import SwiftUI

struct SearchBarView: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title2)

            TextField("Search repos and workspaces...", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
