import Foundation

struct ScannedWorkspaceFolder {
    let name: String
    let path: String
    let parsedWorkspace: Workspace?
}

enum WorkspaceScanResult {
    case success([ScannedWorkspaceFolder])
    case failed
}

actor WorkspaceScanner {
    private let basePath: String

    init(basePath: String) {
        self.basePath = basePath
    }

    func scan() -> WorkspaceScanResult {
        let fm = FileManager.default

        if !fm.fileExists(atPath: basePath) {
            do {
                try fm.createDirectory(atPath: basePath, withIntermediateDirectories: true)
            } catch {
                NSLog("Parallax workspace root create error: %@", error.localizedDescription)
            }
            return .success([])
        }

        let contents: [String]
        do {
            contents = try fm.contentsOfDirectory(atPath: basePath)
        } catch {
            NSLog("Parallax workspace scan error: %@", error.localizedDescription)
            return .failed
        }

        let folders: [ScannedWorkspaceFolder] = contents.compactMap { folderName in
            guard !folderName.hasPrefix(".") else { return nil }

            let fullPath = (basePath as NSString).appendingPathComponent(folderName)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else {
                return nil
            }

            return ScannedWorkspaceFolder(
                name: folderName,
                path: fullPath,
                parsedWorkspace: Workspace.fromFolderName(folderName, basePath: basePath)
            )
        }
        return .success(folders)
    }
}
