import SwiftUI

struct RepoRowView: View {
    let repo: Repository
    @Bindable var appState: AppState
    @State private var isHovered = false

    private var isSelected: Bool {
        if case .repo(let r) = appState.selectedItem {
            return r.id == repo.id
        }
        return false
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            Text(repo.name)
                .font(.title3)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background((isHovered || isSelected) ? Color.accentColor.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .id(repo.id)
        .onHover { isHovered = $0 }
        .onTapGesture {
            appState.selectedRepoForCreation = repo
        }
    }
}
