import SwiftUI

struct MainPanelView: View {
    @Bindable var appState: AppState

    private var isCreating: Bool {
        appState.selectedRepoForCreation != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isCreating {
                SearchBarView(query: $appState.searchQuery)
                    .onChange(of: appState.searchQuery) {
                        appState.selectedIndex = 0
                    }

                Divider()

                contentList
            } else {
                TaskNameSheet(repo: appState.selectedRepoForCreation!, appState: appState)
            }

            if let success = appState.successMessage {
                messageBar(success, color: .green, icon: "checkmark.circle.fill") {
                    appState.successMessage = nil
                }
            }

            if let error = appState.errorMessage {
                messageBar(error, color: .red, icon: "exclamationmark.triangle.fill") {
                    appState.errorMessage = nil
                }
            }
        }
        .frame(width: 680, height: 460)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var contentList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if appState.hasActiveWorkspaces {
                        ActiveWorkspacesSection(appState: appState)
                    }

                    if !appState.filteredRepos.isEmpty {
                        CreateNewSection(appState: appState)
                    }

                    if appState.filteredWorkspaces.isEmpty && appState.filteredRepos.isEmpty {
                        Text("No matching repos or workspaces")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical, 4)
                .background(OverlayScrollIndicatorConfigurator())
                .onChange(of: appState.selectedIndex) { _, newValue in
                    appState.clampSelection()
                    if let item = appState.selectedItem {
                        let id: String
                        switch item {
                        case .workspace(let ws): id = ws.id
                        case .repo(let repo): id = repo.id
                        }
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func messageBar(_ text: String, color: Color, icon: String, dismiss: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Dismiss", action: dismiss)
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
    }
}
