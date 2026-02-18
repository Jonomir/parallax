import SwiftUI

struct EditorOption {
    let name: String
    let command: String
    let tint: Color
}

enum EditorOptions {
    static let all: [EditorOption] = [
        EditorOption(name: "Zed", command: "zed", tint: .blue),
        EditorOption(name: "Cursor", command: "cursor", tint: .pink),
        EditorOption(name: "VS Code", command: "code", tint: .orange),
        EditorOption(name: "GoLand", command: "goland", tint: .purple)
    ]
}
