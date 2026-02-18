import Carbon
import AppKit

@MainActor
final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private weak var panelController: PanelController?

    private static var shared: HotkeyManager?

    static func register(panelController: PanelController) {
        let manager = HotkeyManager()
        manager.panelController = panelController
        manager.registerHotKey()
        shared = manager
    }

    private func registerHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x5058), id: 1) // "PX" + 1

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        // Cmd+P: kVK_ANSI_P = 0x23, cmdKey = 0x0100
        var ref: EventHotKeyRef?
        RegisterEventHotKey(
            UInt32(kVK_ANSI_P),
            UInt32(cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        hotKeyRef = ref
    }

    fileprivate func handleHotKey() {
        panelController?.toggle()
    }
}

private func hotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        manager.handleHotKey()
    }
    return noErr
}
