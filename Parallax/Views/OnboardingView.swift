import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rootPath: String = "~/Projects"
    @State private var editor: String = "zed"
    @State private var workspaceRoot: String = "~/Parallax"
    @State private var saveError: String?
    @State private var animateGetStarted = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "square.on.square.intersection.dashed")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)

                Text("Welcome to Parallax")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Set up your workspace preferences to get started.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            SettingsSectionCard(
                title: "Where are your projects?",
                description: "Parallax will scan this directory for git repositories"
            ) {
                TextField("Root path", text: $rootPath)
                    .textFieldStyle(.roundedBorder)
            }

            SettingsSectionCard(
                title: "Workspace directory",
                description: "Full copies of your repos will be stored here"
            ) {
                TextField("Path", text: $workspaceRoot)
                    .textFieldStyle(.roundedBorder)
            }

            SettingsSectionCard(title: "Preferred editor", description: nil) {
                EditorSelectionRow(selection: $editor)
            }

            Button("Get Started") {
                let settings = AppSettings(
                    rootPaths: [rootPath],
                    editor: editor,
                    workspaceRoot: workspaceRoot
                )
                do {
                    try settings.save()
                    saveError = nil
                    onComplete()
                } catch {
                    saveError = "Could not save settings: \(error.localizedDescription)"
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .scaleEffect(animateGetStarted ? 1.03 : 1.0)
            .shadow(color: .blue.opacity(animateGetStarted ? 0.45 : 0.15), radius: animateGetStarted ? 12 : 4)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                value: animateGetStarted
            )

            if let saveError {
                Text(saveError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(width: 560, height: 520)
        .onAppear {
            if !reduceMotion {
                animateGetStarted = true
            }
        }
    }
}
