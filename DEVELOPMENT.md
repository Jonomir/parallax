# Parallax — Development Guide

## Setup

**Prerequisites:** Xcode, XcodeGen (`brew install xcodegen`)

```bash
xcodegen generate          # Creates Parallax.xcodeproj from project.yml
open Parallax.xcodeproj    # Cmd+R to build & run
```

`project.yml` is the project definition. `.xcodeproj` is gitignored and regenerated.

## Key Design Decisions

**FloatingPanel is an NSPanel, not a SwiftUI Window.**
SwiftUI `Window` scenes don't support borderless floating panels that auto-dismiss. `FloatingPanel` is an `NSPanel` subclass with `.nonactivatingPanel` style, `.floating` level, `.transient` collection behavior. `resignKey()` hides it on focus loss. Panel is created once, reused on every show.

**Keyboard handling lives in AppKit, not SwiftUI.**
SwiftUI's `onKeyPress` only fires when a SwiftUI view has focus — unreliable in NSPanel. All keyboard shortcuts (Escape, arrows, Return, Delete) are handled in `FloatingPanel.keyDown()` which always receives events when the panel is key. Delete/Backspace is forwarded to the text field when it has focus (for normal editing), otherwise triggers workspace deletion.

**Focus management uses AppKit's makeFirstResponder.**
`@FocusState` is unreliable inside NSPanel with `.nonactivatingPanel` style. Instead, `FloatingPanel.focusTextField()` walks the NSView hierarchy to find the first editable `NSTextField` and calls `makeFirstResponder` via `DispatchQueue.main.async` (to let SwiftUI settle after view changes). Triggered via `AppState.focusSearch` callback on panel show, view transitions (entering/exiting create flow), and task name sheet appear.

**Settings/Onboarding are manual NSWindows.**
SwiftUI `Window` and `Settings` scenes don't work for `LSUIElement` menu-bar-only apps. Both are hosted in `NSWindow` instances created by `AppDelegate`.

**Zero external dependencies.** Global hotkey uses Carbon `RegisterEventHotKey` directly.

## Known Issues / TODO

- **Delete has no confirmation** — alert dialog doesn't work with floating panel. Could add as inline UI.
- **Hotkey hardcoded to Cmd+P** — not configurable. Conflicts with Print in other apps.
- **No app icon** — AppIcon.appiconset has empty slots.
