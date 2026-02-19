import Foundation

actor WorkspaceManager {
    private let git = GitService()
    private let baseURL: URL
    private let metadataStore: WorkspaceMetadataStore

    init(basePath: String, metadataStore: WorkspaceMetadataStore) {
        self.baseURL = URL(fileURLWithPath: basePath, isDirectory: true)
        self.metadataStore = metadataStore
    }

    func create(repo: Repository, taskName: String) async throws -> Workspace {
        let slug = try TaskSlug(raw: taskName).value
        let workspaceURL = try setupWorkspaceDirectory(repo: repo, taskSlug: slug)
        let destPath = workspaceURL.path

        let branchName = "agent/\(slug)"
        do {
            try git.createAndCheckoutBranch(branchName, in: destPath)
        } catch {
            // Best-effort cleanup if setup partially succeeded.
            try? FileManager.default.removeItem(at: workspaceURL)
            throw error
        }

        do {
            try await metadataStore.upsert(
                workspacePath: destPath,
                sourceRepoPath: repo.path,
                branchName: branchName
            )
        } catch {
            // Workspace is valid even if metadata persistence fails.
            NSLog("Parallax metadata upsert error: %@", error.localizedDescription)
        }

        return Workspace(
            id: destPath, repoName: repo.name, taskName: slug,
            path: destPath, sourceRepoPath: repo.path, branchName: branchName
        )
    }

    func mergeBack(_ workspace: Workspace) throws {
        guard let sourceRepoPath = workspace.sourceRepoPath,
              let branchName = workspace.branchName else {
            throw MergeBackError.missingInfo
        }
        try git.fetchBranch(branchName, from: workspace.path, into: sourceRepoPath)
    }

    func delete(_ workspace: Workspace) async throws {
        let workspaceURL = URL(fileURLWithPath: workspace.path, isDirectory: true)
        try validateWorkspacePath(workspaceURL)
        try FileManager.default.removeItem(at: workspaceURL)

        do {
            try await metadataStore.delete(workspacePath: workspace.path)
        } catch {
            NSLog("Parallax metadata delete error: %@", error.localizedDescription)
        }
    }

    // MARK: - Private

    private func setupWorkspaceDirectory(repo: Repository, taskSlug: String) throws -> URL {
        let folderName = "\(repo.name)\(Constants.taskSeparator)\(taskSlug)"
        let destinationURL = try nextAvailableWorkspaceURL(baseFolderName: folderName)
        let fm = FileManager.default

        try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try fm.copyItem(at: URL(fileURLWithPath: repo.path, isDirectory: true), to: destinationURL)

        return destinationURL
    }

    private func nextAvailableWorkspaceURL(baseFolderName: String) throws -> URL {
        var attempt = baseFolderName
        var counter = 2
        let fm = FileManager.default

        while true {
            let candidate = baseURL.appendingPathComponent(attempt, isDirectory: true)
            try validateWorkspacePath(candidate)
            if !fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            attempt = "\(baseFolderName)-\(counter)"
            counter += 1
        }
    }

    private func validateWorkspacePath(_ workspaceURL: URL) throws {
        guard PathContainment.isDescendant(workspaceURL, of: baseURL) else {
            throw WorkspacePathError.outsideWorkspaceRoot(
                PathContainment.canonicalPath(workspaceURL)
            )
        }
    }

    enum MergeBackError: LocalizedError {
        case missingInfo
        var errorDescription: String? { "Workspace is missing source repo path or branch name" }
    }

    enum WorkspacePathError: LocalizedError {
        case outsideWorkspaceRoot(String)

        var errorDescription: String? {
            switch self {
            case .outsideWorkspaceRoot(let path):
                return "Invalid workspace destination path: \(path)"
            }
        }
    }
}
