import Foundation

actor RepoScanner {
    private let rootPaths: [String]

    init(rootPaths: [String]) {
        self.rootPaths = rootPaths
    }

    func scan() -> [Repository] {
        var repos: [Repository] = []
        let fm = FileManager.default

        for rootPath in rootPaths {
            let rootURL = URL(fileURLWithPath: rootPath)
            guard let enumerator = fm.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                let name = url.lastPathComponent

                if Constants.skipDirectories.contains(name) {
                    enumerator.skipDescendants()
                    continue
                }

                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                guard isDir else { continue }

                let gitDir = url.appendingPathComponent(".git")
                if fm.fileExists(atPath: gitDir.path) {
                    repos.append(Repository(
                        name: url.lastPathComponent,
                        path: url.path
                    ))
                    enumerator.skipDescendants()
                }
            }
        }

        return repos
    }
}
