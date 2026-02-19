import Foundation

enum AppSettingsLoadIssue {
    case readFailed(String)
    case decodeFailed(String)
}

enum AppSettingsValidationError: LocalizedError {
    case noRootPaths
    case invalidRootPath(String)
    case invalidWorkspaceRoot

    var errorDescription: String? {
        switch self {
        case .noRootPaths:
            return "At least one project root path is required."
        case .invalidRootPath(let path):
            return "Invalid project root path: \(path)"
        case .invalidWorkspaceRoot:
            return "Invalid workspace directory path."
        }
    }
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
        let validated = try validatedForSave()
        let dir = Constants.appSupportDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(validated)
        try data.write(to: Self.fileURL, options: .atomic)
    }

    var expandedRootPaths: [String] {
        rootPaths.map { NSString(string: $0).expandingTildeInPath }
    }

    var expandedWorkspaceRoot: String {
        NSString(string: workspaceRoot).expandingTildeInPath
    }

    func validatedForSave() throws -> AppSettings {
        let cleanedRootPaths = rootPaths
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedRootPaths.isEmpty else {
            throw AppSettingsValidationError.noRootPaths
        }

        for path in cleanedRootPaths {
            if !Self.isAbsoluteOrTildePath(path) {
                throw AppSettingsValidationError.invalidRootPath(path)
            }
        }

        let cleanedWorkspaceRoot = workspaceRoot.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isAbsoluteOrTildePath(cleanedWorkspaceRoot) else {
            throw AppSettingsValidationError.invalidWorkspaceRoot
        }

        return AppSettings(
            rootPaths: cleanedRootPaths,
            editor: editor,
            workspaceRoot: cleanedWorkspaceRoot
        )
    }

    private static func isAbsoluteOrTildePath(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        let expanded = NSString(string: path).expandingTildeInPath
        return expanded.hasPrefix("/")
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
