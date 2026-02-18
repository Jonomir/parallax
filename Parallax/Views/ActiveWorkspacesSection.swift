import SwiftUI

struct ActiveWorkspacesSection: View {
    @Bindable var appState: AppState

    var body: some View {
        SectionHeaderView(title: "Active Workspaces")

        ForEach(appState.filteredWorkspaces, id: \.key) { repoName, workspaces in
            RepoGroupHeader(name: repoName)

            ForEach(workspaces) { workspace in
                WorkspaceRowView(workspace: workspace, appState: appState)
            }
        }
    }
}

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

struct RepoGroupHeader: View {
    let name: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
                .font(.title3)
            Text(name)
                .fontWeight(.medium)
                .font(.title3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}
