import AppKit

@MainActor
class PanelController {
    private var panel: FloatingPanel?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        appState.dismissPanel = { [weak self] in self?.hide() }
        appState.focusSearch = { [weak self] in self?.panel?.focusTextField() }
    }

    func toggle() {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            panel = FloatingPanel(appState: appState)
        }

        guard let panel = panel else { return }

        appState.searchQuery = ""
        appState.selectedRepoForCreation = nil
        appState.errorMessage = nil

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - panel.frame.width / 2
            let y = screenFrame.maxY - panel.frame.height - 200
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        panel.focusTextField()

        Task { await appState.refresh() }
    }

    func hide() {
        panel?.orderOut(nil)
    }
}
