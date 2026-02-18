import Foundation

enum AppSettingsLoadIssue {
    case readFailed(String)
    case decodeFailed(String)
}

struct AppSettingsLoadResult {
    let settings: AppSettings
    let issue: AppSettingsLoadIssue?
}

struct AppSettings: Codable {
    var rootPaths: [String]
    var editor: String
    var workspaceRoot: String

    static let `default` = AppSettings(
        rootPaths: Constants.defaultRootPaths,
        editor: Constants.defaultEditor,
        workspaceRoot: Constants.workspaceRoot
    )

    private static var fileURL: URL {
        Constants.appSupportDirectory.appendingPathComponent("settings.json")
    }

    static func exists() -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func loadResult() -> AppSettingsLoadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppSettingsLoadResult(settings: .default, issue: nil)
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            return AppSettingsLoadResult(
                settings: .default,
                issue: .readFailed(error.localizedDescription)
            )
        }

        do {
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            return AppSettingsLoadResult(settings: settings, issue: nil)
        } catch {
            backupCorruptSettingsIfPossible()
            return AppSettingsLoadResult(
                settings: .default,
                issue: .decodeFailed(error.localizedDescription)
            )
        }
    }

    static func load() -> AppSettings {
        loadResult().settings
    }

    func save() throws {
        let dir = Constants.appSupportDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(self)
        try data.write(to: Self.fileURL, options: .atomic)
    }

    var expandedRootPaths: [String] {
        rootPaths.map { NSString(string: $0).expandingTildeInPath }
    }

    var expandedWorkspaceRoot: String {
        NSString(string: workspaceRoot).expandingTildeInPath
    }

    private static func backupCorruptSettingsIfPossible() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("corrupt-\(timestamp).json")

        do {
            try FileManager.default.moveItem(at: fileURL, to: backupURL)
        } catch {
            NSLog("Parallax settings backup error: %@", error.localizedDescription)
        }
    }
}
