import SwiftUI

struct WorkspaceRowView: View {
    let workspace: Workspace
    @Bindable var appState: AppState
    @State private var isHovered = false
    @State private var hoveredButton: String?

    private var isSelected: Bool {
        if case .workspace(let ws) = appState.selectedItem {
            return ws.id == workspace.id
        }
        return false
    }

    private var mergeBackHint: String {
        workspace.canMergeBack
            ? "Pull back to source (⌘B)"
            : "Merge back unavailable (source repo unresolved)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(workspace.taskName)
                    .fontWeight(.medium)
                    .font(.title3)
                if let branch = workspace.branchName {
                    Text(branch)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isHovered || isSelected {
                if let hint = hoveredButton {
                    Text(hint)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }

                actionButton("arrow.turn.left.up", hint: mergeBackHint, color: workspace.canMergeBack ? .primary : .secondary, enabled: workspace.canMergeBack) {
                    Task { await appState.mergeBackWorkspace(workspace) }
                }

                actionButton("arrow.up.forward.app", hint: "Open in editor (↩)") {
                    appState.openWorkspace(workspace)
                }

                actionButton("trash", hint: "Delete (⇧⌫)", color: .red) {
                    Task { await appState.deleteWorkspace(workspace) }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .background((isHovered || isSelected) ? Color.accentColor.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .id(workspace.id)
        .onHover { isHovered = $0; if !$0 { hoveredButton = nil } }
        .onTapGesture(count: 2) {
            appState.openWorkspace(workspace)
        }
    }

    private func actionButton(
        _ icon: String,
        hint: String,
        color: Color = .primary,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
        }
        .buttonStyle(.borderless)
        .disabled(!enabled)
        .onHover { hoveredButton = $0 ? hint : nil }
    }
}
