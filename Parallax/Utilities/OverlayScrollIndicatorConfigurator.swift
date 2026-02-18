import SwiftUI
import AppKit

struct OverlayScrollIndicatorConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = findEnclosingScrollView(from: nsView) else { return }
            scrollView.scrollerStyle = .overlay
            scrollView.hasVerticalScroller = true
            scrollView.verticalScroller?.controlSize = .small
        }
    }

    private func findEnclosingScrollView(from view: NSView) -> NSScrollView? {
        var current: NSView? = view
        while let node = current {
            if let scrollView = node as? NSScrollView {
                return scrollView
            }
            current = node.superview
        }
        return nil
    }
}
