import Foundation

struct GitService {
    private let shell = ShellExecutor()

    func createAndCheckoutBranch(_ name: String, in directory: String) throws {
        try shell.run("git", arguments: ["checkout", "-b", name], in: directory)
    }

    func currentBranch(in directory: String) throws -> String {
        try shell.run("git", arguments: ["branch", "--show-current"], in: directory)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fetches a branch from a workspace and creates/updates it in the target directory.
    func fetchBranch(_ branchName: String, from workspacePath: String, into targetDirectory: String) throws {
        try shell.run("git", arguments: ["fetch", workspacePath, branchName], in: targetDirectory)
        try shell.run("git", arguments: ["branch", "-f", branchName, "FETCH_HEAD"], in: targetDirectory)
    }
}
