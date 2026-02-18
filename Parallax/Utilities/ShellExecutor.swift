import Foundation

struct ShellExecutor {
    @discardableResult
    func run(_ command: String, arguments: [String] = [], in directory: String? = nil) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let directory = directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw ShellError.nonZeroExit(
                status: process.terminationStatus,
                output: output
            )
        }

        return output
    }
}

enum ShellError: LocalizedError {
    case nonZeroExit(status: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .nonZeroExit(let status, let output):
            return "Command failed (exit \(status)): \(output)"
        }
    }
}
