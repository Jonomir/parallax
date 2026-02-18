import Foundation

enum Constants {
    static let defaultRootPaths = ["~/Projects"]
    static let defaultEditor = "zed"
    static let workspaceRoot = "~/Parallax"
    static let taskSeparator = "__"

    static let skipDirectories: Set<String> = [
        "node_modules", "vendor", "target", "dist", ".build",
        "Pods", "DerivedData", "build", "out"
    ]

    static var appSupportDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("Parallax")
    }
}
