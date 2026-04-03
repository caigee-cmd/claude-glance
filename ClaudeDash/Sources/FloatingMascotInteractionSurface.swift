import AppKit
import SwiftUI

enum FloatingMascotInteractionRules {
    static let dragActivationDistance: CGFloat = 4
}

struct FloatingMascotInteractionSurface: NSViewRepresentable {
    let onTap: () -> Void
    let onDragStateChanged: (Bool) -> Void

    func makeNSView(context _: Context) -> FloatingMascotInteractionSurfaceView {
        let view = FloatingMascotInteractionSurfaceView()
        view.onTap = onTap
        view.onDragStateChanged = onDragStateChanged
        return view
    }

    func updateNSView(_ nsView: FloatingMascotInteractionSurfaceView, context _: Context) {
        nsView.onTap = onTap
        nsView.onDragStateChanged = onDragStateChanged
    }
}

final class FloatingMascotInteractionSurfaceView: NSView {
    var onTap: (() -> Void)?
    var onDragStateChanged: ((Bool) -> Void)?

    private var initialMouseLocationInScreen: CGPoint?
    private var initialWindowOrigin: CGPoint?
    private var didDrag = false

    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }

        initialMouseLocationInScreen = NSEvent.mouseLocation
        initialWindowOrigin = window.frame.origin
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard
            let window,
            let initialMouseLocationInScreen,
            let initialWindowOrigin
        else {
            return
        }

        let currentLocationInScreen = NSEvent.mouseLocation
        let translation = CGSize(
            width: currentLocationInScreen.x - initialMouseLocationInScreen.x,
            height: currentLocationInScreen.y - initialMouseLocationInScreen.y
        )

        if !didDrag {
            didDrag = hypot(translation.width, translation.height) >= FloatingMascotInteractionRules.dragActivationDistance
            if didDrag {
                onDragStateChanged?(true)
            }
        }

        guard didDrag else { return }

        let proposedOrigin = CGPoint(
            x: initialWindowOrigin.x + translation.width,
            y: initialWindowOrigin.y + translation.height
        )
        let visibleFrame = FloatingPanelLayout.preferredVisibleFrame(
            for: proposedOrigin,
            panelSize: window.frame.size,
            visibleFrames: NSScreen.screens.map(\.visibleFrame)
        ) ?? window.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(origin: .zero, size: window.frame.size)
        let newOrigin = FloatingPanelLayout.clampedOrigin(
            for: proposedOrigin,
            panelSize: window.frame.size,
            visibleFrame: visibleFrame
        )

        window.setFrameOrigin(NSPoint(x: newOrigin.x, y: newOrigin.y))
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            if didDrag {
                onDragStateChanged?(false)
            }
            initialMouseLocationInScreen = nil
            initialWindowOrigin = nil
            didDrag = false
        }

        guard event.type == .leftMouseUp else { return }

        if !didDrag {
            onTap?()
        }
    }
}
