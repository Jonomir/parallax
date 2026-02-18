import Foundation

struct WorkspaceMetadata: Codable, Hashable {
    let workspacePath: String
    let sourceRepoPath: String
    let branchName: String
    let createdAt: Date
}

struct WorkspaceMetadataFile: Codable {
    var workspaces: [String: WorkspaceMetadata]
}
