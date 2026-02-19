import Foundation
import AppKit

enum EditorLaunchError: LocalizedError {
    case unsupportedEditor(String)
    case openFailed(editor: String, appName: String, path: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedEditor(let editor):
            return "Unsupported editor '\(editor)'."
        case .openFailed(let editor, let appName, let path):
            return "Could not open '\(path)' in '\(editor)' (\(appName)). Ensure the app is installed."
        }
    }
}

enum EditorLauncher {
    static func open(path: String, editor: String = Constants.defaultEditor) throws {
        let normalizedEditor = editor.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let appName = applicationName(for: normalizedEditor) else {
            throw EditorLaunchError.unsupportedEditor(editor)
        }

        let opened = NSWorkspace.shared.openFile(path, withApplication: appName)
        guard opened else {
            throw EditorLaunchError.openFailed(
                editor: editor,
                appName: appName,
                path: path
            )
        }
    }

    static func applicationName(for editor: String) -> String? {
        switch editor {
        case "zed":
            return "Zed"
        case "cursor":
            return "Cursor"
        case "code":
            return "Visual Studio Code"
        case "goland":
            return "GoLand"
        default:
            return nil
        }
    }
}
