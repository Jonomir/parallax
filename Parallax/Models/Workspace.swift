import Foundation

struct Workspace: Identifiable, Hashable {
    let id: String
    let repoName: String
    let taskName: String
    let path: String
    var sourceRepoPath: String?
    var branchName: String?
    var canMergeBack: Bool {
        guard sourceRepoPath != nil, let branchName else { return false }
        return !branchName.isEmpty
    }

    func matches(query: String) -> Bool {
        repoName.localizedCaseInsensitiveContains(query) ||
        taskName.localizedCaseInsensitiveContains(query)
    }

    static func fromFolderName(_ name: String, basePath: String) -> Workspace? {
        let separator = Constants.taskSeparator
        guard let range = name.range(of: separator, options: .backwards) else { return nil }

        let repo = String(name[name.startIndex..<range.lowerBound])
        let task = String(name[range.upperBound...])
        guard !repo.isEmpty, !task.isEmpty else { return nil }

        let fullPath = (basePath as NSString).appendingPathComponent(name)

        return Workspace(
            id: fullPath,
            repoName: repo,
            taskName: task,
            path: fullPath
        )
    }
}
