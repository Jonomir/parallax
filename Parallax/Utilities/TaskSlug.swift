import Foundation

enum TaskSlugError: LocalizedError {
    case emptyTaskName
    case invalidCharacters
    case invalidResult

    var errorDescription: String? {
        switch self {
        case .emptyTaskName:
            return "Task name cannot be empty."
        case .invalidCharacters:
            return "Task name can only use letters, numbers, spaces, '-', '_', and '.'."
        case .invalidResult:
            return "Task name produced an invalid slug."
        }
    }
}

struct TaskSlug: Hashable {
    let value: String

    init(raw: String) throws {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TaskSlugError.emptyTaskName
        }

        let lower = trimmed.lowercased()
        var slug = ""
        var previousCharacter: Character?

        for scalar in lower.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                if previousCharacter != "-" {
                    slug.append("-")
                    previousCharacter = "-"
                }
                continue
            }

            guard Self.allowedCharacters.contains(scalar) else {
                throw TaskSlugError.invalidCharacters
            }

            let character = Character(scalar)
            if Self.collapsibleSeparators.contains(character), previousCharacter == character {
                continue
            }

            slug.append(character)
            previousCharacter = character
        }

        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-_."))
        guard !slug.isEmpty, slug != ".", slug != "..", !slug.contains("..") else {
            throw TaskSlugError.invalidResult
        }

        self.value = slug
    }

    static func preview(from input: String) -> String? {
        try? TaskSlug(raw: input).value
    }

    private static let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.")
    private static let collapsibleSeparators: Set<Character> = ["-", "_"]
}
