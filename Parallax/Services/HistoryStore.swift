import Foundation

enum HistoryStoreError: LocalizedError {
    case readFailed(Error)
    case decodeFailed(Error)
    case encodeFailed(Error)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .readFailed(let error):
            return "Failed reading usage history: \(error.localizedDescription)"
        case .decodeFailed(let error):
            return "Failed decoding usage history: \(error.localizedDescription)"
        case .encodeFailed(let error):
            return "Failed encoding usage history: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed writing usage history: \(error.localizedDescription)"
        }
    }
}

struct HistoryStore {
    private let fileURL: URL

    init() {
        self.fileURL = Constants.appSupportDirectory.appendingPathComponent("history.json")
    }

    func load() -> [String: Int] {
        do {
            return try readFromDisk()
        } catch {
            NSLog("Parallax history read error: %@", error.localizedDescription)
            return [:]
        }
    }

    func recordUsage(repoPath: String) {
        do {
            var history = try readFromDisk()
            history[repoPath, default: 0] += 1
            try save(history)
        } catch {
            // History is best-effort telemetry; creation should continue.
            NSLog("Parallax history write error: %@", error.localizedDescription)
        }
    }

    private func save(_ history: [String: Int]) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data: Data
        do {
            data = try JSONEncoder().encode(history)
        } catch {
            throw HistoryStoreError.encodeFailed(error)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw HistoryStoreError.writeFailed(error)
        }
    }

    private func readFromDisk() throws -> [String: Int] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:]
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw HistoryStoreError.readFailed(error)
        }

        do {
            return try JSONDecoder().decode([String: Int].self, from: data)
        } catch {
            throw HistoryStoreError.decodeFailed(error)
        }
    }
}
