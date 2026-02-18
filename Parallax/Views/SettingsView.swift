import SwiftUI

struct SettingsView: View {
    var appState: AppState?
    @State private var settings = AppSettings.load()
    @State private var newPath: String = ""
    @State private var saveStatus: String? = nil
    @State private var saveStatusIsError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "square.on.square.intersection.dashed")
                        .font(.system(size: 38))
                        .foregroundStyle(.blue)

                    Text("Parallax Settings")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Adjust workspace paths and editor preferences.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                SettingsSectionCard(
                    title: "Project root paths",
                    description: "Parallax scans these directories for git repositories."
                ) {
                    VStack(spacing: 8) {
                        if settings.rootPaths.isEmpty {
                            Text("No root paths configured yet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(settings.rootPaths, id: \.self) { path in
                                HStack(spacing: 10) {
                                    Text(path)
                                        .font(.callout)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button {
                                        settings.rootPaths.removeAll { $0 == path }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            TextField("Add path (e.g. ~/Developer)", text: $newPath)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { addPath() }

                            Button("Add") { addPath() }
                                .buttonStyle(.bordered)
                                .disabled(newPath.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }

                SettingsSectionCard(
                    title: "Workspace directory",
                    description: "Workspaces are created here as full filesystem copies."
                ) {
                    TextField("Path", text: $settings.workspaceRoot)
                        .textFieldStyle(.roundedBorder)
                }

                SettingsSectionCard(title: "Default editor", description: nil) {
                    EditorSelectionRow(selection: $settings.editor)
                }

                Button {
                    do {
                        try settings.save()
                        saveStatus = "Settings applied!"
                        saveStatusIsError = false
                        if let appState {
                            Task { await appState.reloadSettings() }
                        }
                        Task {
                            do {
                                try await Task.sleep(for: .seconds(2))
                            } catch {
                                return
                            }
                            saveStatus = nil
                        }
                    } catch {
                        saveStatus = "Error: \(error.localizedDescription)"
                        saveStatusIsError = true
                    }
                } label: {
                    Text("Save")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 4)

                if let status = saveStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(saveStatusIsError ? .red : .green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 500, minHeight: 520)
    }

    private func addPath() {
        let path = newPath.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty, !settings.rootPaths.contains(path) else { return }
        settings.rootPaths.append(path)
        newPath = ""
    }
}
