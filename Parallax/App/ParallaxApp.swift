import SwiftUI

@main
struct ParallaxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Parallax", systemImage: "square.on.square.intersection.dashed") {
            Button("Open Parallax") {
                appDelegate.panelController?.toggle()
            }

            Divider()

            Button("Settings...") {
                appDelegate.openSettings()
            }

            Divider()

            Button("Quit Parallax") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: appDelegate.appState.wantsSettings) { _, wants in
            if wants {
                appDelegate.appState.wantsSettings = false
                appDelegate.openSettings()
            }
        }
    }
}
