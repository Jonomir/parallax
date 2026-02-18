import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    private let appState: AppState
    private var keyMonitor: Any?

    init(appState: AppState) {
        self.appState = appState
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 460),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        hasShadow = true
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        backgroundColor = .clear

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]

        let view = MainPanelView(appState: appState)
        contentView = NSHostingView(rootView: view)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isKeyWindow else { return event }
            return self.handleKey(event) ? nil : event
        }
    }

    deinit {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    func focusTextField() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let tf = self.findTextField(in: self.contentView) else { return }
            self.makeFirstResponder(tf)
        }
    }

    // MARK: - Keyboard

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown,
           event.modifierFlags.contains(.command),
           let chars = event.charactersIgnoringModifiers {
            switch chars {
            case ",":
                appState.dismissPanel?()
                appState.wantsSettings = true
                return
            case "b" where appState.selectedRepoForCreation == nil:
                handleMergeBack()
                return
            default:
                break
            }
        }
        super.sendEvent(event)
    }

    /// Returns true if the event was handled (consumed).
    private func handleKey(_ event: NSEvent) -> Bool {
        switch Int(event.keyCode) {
        case 53: // Escape
            handleEscape()
            return true
        case 126: // Up arrow
            guard appState.selectedRepoForCreation == nil else { return false }
            appState.moveSelection(by: -1)
            return true
        case 125: // Down arrow
            guard appState.selectedRepoForCreation == nil else { return false }
            appState.moveSelection(by: 1)
            return true
        case 36: // Return
            if appState.selectedRepoForCreation != nil {
                return false // let text field handle onSubmit
            }
            handleEnter()
            return true
        case 51: // Delete/Backspace
            if event.modifierFlags.contains(.shift), appState.selectedRepoForCreation == nil {
                handleDelete()
                return true
            }
            return false
        default:
            return false
        }
    }

    private func handleEscape() {
        if appState.selectedRepoForCreation != nil {
            appState.selectedRepoForCreation = nil
        } else if !appState.searchQuery.isEmpty {
            appState.searchQuery = ""
        } else {
            appState.dismissPanel?()
        }
    }

    private func handleEnter() {
        guard let item = appState.selectedItem else { return }
        switch item {
        case .workspace(let ws):
            appState.openWorkspace(ws)
        case .repo(let repo):
            appState.selectedRepoForCreation = repo
        }
    }

    private func handleDelete() {
        guard let item = appState.selectedItem else { return }
        if case .workspace(let ws) = item {
            Task { await appState.deleteWorkspace(ws) }
        }
    }

    private func handleMergeBack() {
        guard let item = appState.selectedItem else { return }
        if case .workspace(let ws) = item {
            guard ws.canMergeBack else {
                appState.errorMessage = "Merge back unavailable: source repository could not be resolved for this workspace."
                return
            }
            Task { await appState.mergeBackWorkspace(ws) }
        }
    }

    private func findTextField(in view: NSView?) -> NSTextField? {
        guard let view else { return nil }
        if let tf = view as? NSTextField, tf.isEditable { return tf }
        for sub in view.subviews {
            if let found = findTextField(in: sub) { return found }
        }
        return nil
    }
}
