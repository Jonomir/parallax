import Foundation

struct Repository: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    var frequency: Int = 0

    init(name: String, path: String) {
        self.id = path
        self.name = name
        self.path = path
    }

    func matches(query: String) -> Bool {
        name.localizedCaseInsensitiveContains(query)
    }
}
