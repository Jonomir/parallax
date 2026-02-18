import SwiftUI

struct CreateNewSection: View {
    @Bindable var appState: AppState

    var body: some View {
        SectionHeaderView(title: "Create New Workspace")

        ForEach(appState.filteredRepos) { repo in
            RepoRowView(repo: repo, appState: appState)
        }
    }
}
