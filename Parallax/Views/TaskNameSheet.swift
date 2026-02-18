import SwiftUI

struct TaskNameSheet: View {
    let repo: Repository
    @Bindable var appState: AppState
    @State private var taskName: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Text("New workspace for")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(repo.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 12) {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                TextField("Task name (e.g. fix-login-bug)", text: $taskName)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit { createWorkspace() }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 40)

            actionHint
                .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            appState.focusSearch?()
        }
    }

    private var actionHint: some View {
        HStack(spacing: 6) {
            if let name = TaskSlug.preview(from: taskName) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Enter to create **agent/\(name)**")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Use letters, numbers, spaces, '-', '_', and '.'")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("Type a task name, Enter to create")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private func createWorkspace() {
        let name = taskName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        appState.selectedRepoForCreation = nil
        Task {
            await appState.createWorkspace(for: repo, taskName: name)
        }
    }
}
