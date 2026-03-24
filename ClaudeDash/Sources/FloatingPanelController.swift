// FloatingPanelController.swift
// ClaudeDash - Floating progress panel for active sessions
// NSPanel always-on-top, auto-show/hide, draggable

import AppKit
import SwiftUI
import Combine

extension Notification.Name {
    static let hideFloatingPanel = Notification.Name("hideFloatingPanel")
}

@MainActor
final class FloatingPanelController {
    private var panel: NSPanel?
    private let sessionMonitor: SessionMonitor
    private var cancellables = Set<AnyCancellable>()
    private var isVisible = false
    private var isManuallyHidden = false

    // Saved position
    private let positionXKey = "ClaudeDash_panelX"
    private let positionYKey = "ClaudeDash_panelY"

    init(sessionMonitor: SessionMonitor) {
        self.sessionMonitor = sessionMonitor
        observeSessionChanges()
        observeHideNotification()
    }

    // MARK: - Observe

    private func observeSessionChanges() {
        sessionMonitor.$activeSessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                let activeCount = sessions.filter { $0.status != .completed }.count

                if activeCount == 0 {
                    self.isManuallyHidden = false
                    if self.isVisible {
                        self.hidePanel(manual: false)
                    }
                } else if !self.isVisible && !self.isManuallyHidden {
                    self.showPanel()
                }

                self.updatePanelSize(activeCount: activeCount)
            }
            .store(in: &cancellables)
    }

    private func observeHideNotification() {
        NotificationCenter.default.publisher(for: .hideFloatingPanel)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.hidePanel(manual: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Show / Hide

    func showPanel() {
        if panel == nil {
            createPanel()
        }
        isManuallyHidden = false
        panel?.orderFrontRegardless()
        isVisible = true
    }

    func hidePanel(manual: Bool = true) {
        savePosition()
        panel?.orderOut(nil)
        isVisible = false
        if manual {
            isManuallyHidden = true
        }
    }

    func togglePanel() {
        if isVisible {
            hidePanel(manual: true)
        } else {
            showPanel()
        }
    }

    // MARK: - Panel Creation

    private func createPanel() {
        let contentView = FloatingPanelView()
            .environmentObject(sessionMonitor)

        let hostingView = NSHostingView(rootView: contentView)
        let initialActiveCount = sessionMonitor.activeSessions.filter { $0.status != .completed }.count
        let initialSize = NSSize(
            width: FloatingPanelLayout.panelWidth,
            height: FloatingPanelLayout.panelHeight(forTotalSessionCount: initialActiveCount)
        )
        hostingView.setFrameSize(initialSize)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isExcludedFromWindowsMenu = true
        panel.animationBehavior = .utilityWindow
        panel.contentView = hostingView
        panel.isReleasedWhenClosed = false

        // Restore saved position or default to top-right
        let defaults = UserDefaults.standard
        if defaults.object(forKey: positionXKey) != nil {
            let x = defaults.double(forKey: positionXKey)
            let y = defaults.double(forKey: positionYKey)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - FloatingPanelLayout.panelWidth - 20
            let y = screenFrame.maxY - 92
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
    }

    // MARK: - Resize

    private func updatePanelSize(activeCount: Int) {
        guard let panel else { return }
        let height = FloatingPanelLayout.panelHeight(forTotalSessionCount: activeCount)
        var frame = panel.frame
        let oldHeight = frame.height
        frame.size.width = FloatingPanelLayout.panelWidth
        frame.size.height = height
        // Adjust origin so top edge stays fixed
        frame.origin.y += oldHeight - height
        panel.setFrame(frame, display: true, animate: true)
    }

    // MARK: - Position Persistence

    private func savePosition() {
        guard let panel else { return }
        let origin = panel.frame.origin
        UserDefaults.standard.set(origin.x, forKey: positionXKey)
        UserDefaults.standard.set(origin.y, forKey: positionYKey)
    }
}
