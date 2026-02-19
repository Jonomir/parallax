import Foundation

enum PathContainment {
    static func isDescendant(_ targetURL: URL, of baseURL: URL, fileManager: FileManager = .default) -> Bool {
        let basePath = canonicalPath(baseURL, fileManager: fileManager)
        let targetPath = canonicalPath(targetURL, fileManager: fileManager)
        let basePrefix = basePath.hasSuffix("/") ? basePath : basePath + "/"
        return targetPath.hasPrefix(basePrefix)
    }

    /// Canonicalizes a URL for safe path comparisons.
    /// If the leaf does not exist yet, this resolves symlinks/casing on the nearest existing ancestor
    /// and then appends missing path components back.
    static func canonicalPath(_ url: URL, fileManager: FileManager = .default) -> String {
        var current = url.standardizedFileURL
        var missingComponents: [String] = []

        while !fileManager.fileExists(atPath: current.path) {
            let parent = current.deletingLastPathComponent()
            guard parent.path != current.path else { break }
            missingComponents.insert(current.lastPathComponent, at: 0)
            current = parent
        }

        var resolved = current.resolvingSymlinksInPath().standardizedFileURL
        for component in missingComponents {
            resolved.appendPathComponent(component, isDirectory: true)
        }
        return resolved.standardizedFileURL.path
    }
}
