import Foundation

actor WorkspaceRefreshService {
    private let workspaceScanner: WorkspaceScanner
    private let metadataStore: WorkspaceMetadataStore
    private let git = GitService()

    init(basePath: String, metadataStore: WorkspaceMetadataStore) {
        self.workspaceScanner = WorkspaceScanner(basePath: basePath)
        self.metadataStore = metadataStore
    }

    func loadWorkspaces(repositories: [Repository]) async -> [Workspace] {
        let scanResult = await workspaceScanner.scan()
        var metadataByPath = await metadataStore.load()
        let scannedFolders: [ScannedWorkspaceFolder]

        switch scanResult {
        case .success(let folders):
            scannedFolders = folders
        case .failed:
            return fallbackWorkspacesFromMetadata(metadataByPath)
        }

        let reposByName = Dictionary(grouping: repositories, by: \.name)
        var workspaces: [Workspace] = []
        var seenWorkspacePaths: Set<String> = []
        var didMutateMetadata = false

        for folder in scannedFolders {
            let normalizedPath = metadataStore.normalizedPath(folder.path)
            seenWorkspacePaths.insert(normalizedPath)
            let existingMetadata = metadataByPath[normalizedPath]

            guard var workspace = workspaceFrom(folder: folder, metadata: existingMetadata) else {
                continue
            }

            if existingMetadata == nil {
                let candidates = reposByName[workspace.repoName] ?? []
                if candidates.count == 1 {
                    workspace.sourceRepoPath = candidates[0].path
                }
            }

            if hasGitMetadata(at: workspace.path) {
                do {
                    let liveBranch = try git.currentBranch(in: workspace.path)
                    if !liveBranch.isEmpty {
                        workspace.branchName = liveBranch
                    }
                } catch {
                    NSLog(
                        "Parallax branch resolve error for %@: %@",
                        workspace.path,
                        error.localizedDescription
                    )
                }
            }

            if let sourceRepoPath = workspace.sourceRepoPath,
               let branchName = workspace.branchName,
               !branchName.isEmpty {
                let createdAt = existingMetadata?.createdAt ?? Date()
                let normalizedSource = metadataStore.normalizedPath(sourceRepoPath)
                let next = WorkspaceMetadata(
                    workspacePath: normalizedPath,
                    sourceRepoPath: normalizedSource,
                    branchName: branchName,
                    createdAt: createdAt
                )

                if metadataByPath[normalizedPath] != next {
                    metadataByPath[normalizedPath] = next
                    didMutateMetadata = true
                }
            }

            workspaces.append(workspace)
        }

        let beforeCount = metadataByPath.count
        metadataByPath = metadataByPath.filter { seenWorkspacePaths.contains($0.key) }
        if metadataByPath.count != beforeCount {
            didMutateMetadata = true
        }

        if didMutateMetadata {
            do {
                try await metadataStore.persist(metadataByPath)
            } catch {
                NSLog("Parallax metadata persist error: %@", error.localizedDescription)
            }
        }

        return workspaces
    }

    private func workspaceFrom(
        folder: ScannedWorkspaceFolder,
        metadata: WorkspaceMetadata?
    ) -> Workspace? {
        guard let metadata else {
            return folder.parsedWorkspace
        }

        let fallbackRepo = folder.parsedWorkspace?.repoName ?? folder.name
        let fallbackTask = folder.parsedWorkspace?.taskName ?? folder.name

        return Workspace(
            id: folder.path,
            repoName: repoName(from: metadata.sourceRepoPath, fallback: fallbackRepo),
            taskName: taskName(from: metadata.branchName, fallback: fallbackTask),
            path: folder.path,
            sourceRepoPath: metadata.sourceRepoPath,
            branchName: metadata.branchName
        )
    }

    private func repoName(from sourceRepoPath: String, fallback: String) -> String {
        let name = URL(fileURLWithPath: sourceRepoPath, isDirectory: true).lastPathComponent
        return name.isEmpty ? fallback : name
    }

    private func taskName(from branchName: String, fallback: String) -> String {
        let prefix = "agent/"
        guard branchName.hasPrefix(prefix) else { return fallback }
        let value = String(branchName.dropFirst(prefix.count))
        return value.isEmpty ? fallback : value
    }

    private func fallbackWorkspacesFromMetadata(
        _ metadataByPath: [String: WorkspaceMetadata]
    ) -> [Workspace] {
        let fm = FileManager.default

        return metadataByPath.values
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { metadata in
                let path = metadata.workspacePath
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
                    return nil
                }

                let folderName = URL(fileURLWithPath: path, isDirectory: true).lastPathComponent
                return Workspace(
                    id: path,
                    repoName: repoName(from: metadata.sourceRepoPath, fallback: folderName),
                    taskName: taskName(from: metadata.branchName, fallback: folderName),
                    path: path,
                    sourceRepoPath: metadata.sourceRepoPath,
                    branchName: metadata.branchName
                )
            }
    }

    private func hasGitMetadata(at workspacePath: String) -> Bool {
        let gitURL = URL(fileURLWithPath: workspacePath, isDirectory: true)
            .appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitURL.path)
    }
}
