import Foundation

enum WorkspaceMetadataStoreError: LocalizedError {
    case encodeFailed(Error)
    case writeFailed(Error)
    case readFailed(Error)
    case decodeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .encodeFailed(let error):
            return "Failed to encode workspace metadata: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to persist workspace metadata: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read workspace metadata: \(error.localizedDescription)"
        case .decodeFailed(let error):
            return "Failed to decode workspace metadata: \(error.localizedDescription)"
        }
    }
}

actor WorkspaceMetadataStore {
    private let fileURL: URL

    init(fileURL: URL = Constants.appSupportDirectory.appendingPathComponent("workspaces.json")) {
        self.fileURL = fileURL
    }

    func load() -> [String: WorkspaceMetadata] {
        do {
            return try readFromDisk()
        } catch {
            NSLog("Parallax metadata read error: %@", error.localizedDescription)
            return [:]
        }
    }

    func persist(_ metadataByPath: [String: WorkspaceMetadata]) throws {
        try writeToDisk(metadataByPath)
    }

    func upsert(
        workspacePath: String,
        sourceRepoPath: String,
        branchName: String,
        createdAt: Date = Date()
    ) throws {
        var all = try readFromDisk()
        let key = normalizedPath(workspacePath)
        let existingCreatedAt = all[key]?.createdAt ?? createdAt
        all[key] = WorkspaceMetadata(
            workspacePath: key,
            sourceRepoPath: normalizedPath(sourceRepoPath),
            branchName: branchName,
            createdAt: existingCreatedAt
        )
        try writeToDisk(all)
    }

    func delete(workspacePath: String) throws {
        var all = try readFromDisk()
        all.removeValue(forKey: normalizedPath(workspacePath))
        try writeToDisk(all)
    }

    nonisolated func normalizedPath(_ path: String) -> String {
        PathContainment.canonicalPath(URL(fileURLWithPath: path))
    }

    private func readFromDisk() throws -> [String: WorkspaceMetadata] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:]
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw WorkspaceMetadataStoreError.readFailed(error)
        }

        do {
            let decoded = try JSONDecoder().decode(WorkspaceMetadataFile.self, from: data)
            var normalized: [String: WorkspaceMetadata] = [:]
            for metadata in decoded.workspaces.values {
                let workspacePath = normalizedPath(metadata.workspacePath)
                normalized[workspacePath] = WorkspaceMetadata(
                    workspacePath: workspacePath,
                    sourceRepoPath: normalizedPath(metadata.sourceRepoPath),
                    branchName: metadata.branchName,
                    createdAt: metadata.createdAt
                )
            }
            return normalized
        } catch {
            throw WorkspaceMetadataStoreError.decodeFailed(error)
        }
    }

    private func writeToDisk(_ metadataByPath: [String: WorkspaceMetadata]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let data: Data
        do {
            data = try JSONEncoder().encode(WorkspaceMetadataFile(workspaces: metadataByPath))
        } catch {
            throw WorkspaceMetadataStoreError.encodeFailed(error)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WorkspaceMetadataStoreError.writeFailed(error)
        }
    }
}
