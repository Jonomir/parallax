import Foundation

enum EditorLaunchError: LocalizedError {
    case launchFailed(editor: String, path: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let editor, let path, let underlying):
            return "Could not launch '\(editor)' for '\(path)': \(underlying.localizedDescription)"
        }
    }
}

enum EditorLauncher {
    static func open(path: String, editor: String = Constants.defaultEditor) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [editor, path]

        do {
            try process.run()
        } catch {
            throw EditorLaunchError.launchFailed(editor: editor, path: path, underlying: error)
        }
    }
}
