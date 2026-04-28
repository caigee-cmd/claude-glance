import Foundation
import Combine

struct FloatingPanelHoverRules: Equatable {
    let revealDelay: TimeInterval
    let collapseDelay: TimeInterval

    static let `default` = FloatingPanelHoverRules(
        revealDelay: 0.22,
        collapseDelay: 0.14
    )
}

enum FloatingMascotPlaybackState: Equatable {
    case stoppedAtFirstFrame
    case playing(speed: Double)
}

enum FloatingPanelPlaybackRules {
    static let defaultBaseSpeed: Double = FloatingMascotAnimationSpeedOption.normal.multiplier
    static let speedStep: Double = 0.35
    static let maxTapBoostCount = 5
    static let resetDelay: TimeInterval = 1.1

    static func baseSpeed(defaults: UserDefaults = ClaudeDashDefaults.shared) -> Double {
        let rawValue = defaults.string(forKey: FloatingMascotAnimationSpeedOption.userDefaultsKey)
        return FloatingMascotAnimationSpeedOption(rawValue: rawValue ?? FloatingMascotAnimationSpeedOption.normal.rawValue)?
            .multiplier ?? defaultBaseSpeed
    }

    static func playbackSpeed(forTapCount tapCount: Int, baseSpeed: Double = defaultBaseSpeed) -> Double {
        let clampedTapCount = min(max(tapCount, 0), maxTapBoostCount)
        return baseSpeed + (Double(clampedTapCount) * speedStep)
    }

    static func nextTapCount(previousTapCount: Int, lastTapAt: Date?, now: Date) -> Int {
        guard let lastTapAt else { return 1 }
        guard now.timeIntervalSince(lastTapAt) <= resetDelay else { return 1 }
        return min(previousTapCount + 1, maxTapBoostCount)
    }

    static func shouldReset(lastTapAt: Date?, now: Date) -> Bool {
        guard let lastTapAt else { return false }
        return now.timeIntervalSince(lastTapAt) >= resetDelay
    }
}

@MainActor
final class FloatingPanelInteractionModel: ObservableObject {
    @Published private(set) var displayMode: FloatingPanelDisplayMode = .compact
    @Published private(set) var playbackSpeed: Double = FloatingPanelPlaybackRules.baseSpeed()
    @Published private(set) var mascotPlaybackState: FloatingMascotPlaybackState = .stoppedAtFirstFrame
    @Published private(set) var tapBoostCount = 0
    @Published private(set) var isPanelVisible = false

    private let hoverRules: FloatingPanelHoverRules
    private var isHoveringMascot = false
    private var isHoveringTaskPanel = false
    private var isHoverPreviewVisible = false
    private var isExpanded = false
    private var isDraggingMascot = false
    private var hasLivePlayback = false
    private var lastTapAt: Date?
    private var basePlaybackSpeed = FloatingPanelPlaybackRules.baseSpeed()
    private var playbackResetWorkItem: DispatchWorkItem?
    private var hoverRevealWorkItem: DispatchWorkItem?
    private var hoverCollapseWorkItem: DispatchWorkItem?

    init(hoverRules: FloatingPanelHoverRules = .default) {
        self.hoverRules = hoverRules
    }

    func setHovering(_ hovering: Bool) {
        setHoveringMascot(hovering)
    }

    func setHoveringMascot(_ hovering: Bool) {
        isHoveringMascot = hovering
        guard !isDraggingMascot else { return }

        if hovering {
            cancelHoverCollapse()
            scheduleHoverRevealIfNeeded()
        } else {
            scheduleHoverCollapseIfNeeded()
        }
    }

    func setHoveringTaskPanel(_ hovering: Bool) {
        isHoveringTaskPanel = hovering
        guard !isDraggingMascot else { return }

        if hovering {
            cancelHoverCollapse()
            revealHoverPreview()
        } else {
            scheduleHoverCollapseIfNeeded()
        }
    }

    func setDraggingMascot(_ dragging: Bool) {
        guard isDraggingMascot != dragging else { return }
        isDraggingMascot = dragging

        if dragging {
            hoverRevealWorkItem?.cancel()
            hoverRevealWorkItem = nil
            cancelHoverCollapse()
            return
        }

        guard !isExpanded else {
            syncDisplayMode()
            return
        }

        if isHoveringMascot || isHoveringTaskPanel {
            if isHoverPreviewVisible {
                syncDisplayMode()
                return
            }
            scheduleHoverRevealIfNeeded()
        } else {
            isHoverPreviewVisible = false
            syncDisplayMode()
        }
    }

    func toggleExpanded() {
        isExpanded.toggle()
        if isExpanded {
            revealHoverPreview()
        } else if !isHoveringMascot, !isHoveringTaskPanel {
            isHoverPreviewVisible = false
        }
        syncDisplayMode()
    }

    func collapseExpandedPanel() {
        isExpanded = false
        if !isHoveringMascot, !isHoveringTaskPanel {
            isHoverPreviewVisible = false
        }
        syncDisplayMode()
    }

    func setPlaybackActive(_ active: Bool) {
        guard hasLivePlayback != active else {
            updateMascotPlaybackState()
            return
        }

        hasLivePlayback = active
        updateMascotPlaybackState()
    }

    func setPanelVisible(_ visible: Bool) {
        guard isPanelVisible != visible else { return }
        isPanelVisible = visible
    }

    var shouldAnimateMotion: Bool {
        isPanelVisible && hasLivePlayback
    }

    func refreshPlaybackBaseSpeed() {
        basePlaybackSpeed = FloatingPanelPlaybackRules.baseSpeed()
        playbackSpeed = FloatingPanelPlaybackRules.playbackSpeed(
            forTapCount: tapBoostCount,
            baseSpeed: basePlaybackSpeed
        )
        updateMascotPlaybackState()
    }

    func handleMascotTap(now: Date = Date()) {
        tapBoostCount = FloatingPanelPlaybackRules.nextTapCount(
            previousTapCount: tapBoostCount,
            lastTapAt: lastTapAt,
            now: now
        )
        lastTapAt = now
        playbackSpeed = FloatingPanelPlaybackRules.playbackSpeed(forTapCount: tapBoostCount, baseSpeed: basePlaybackSpeed)
        updateMascotPlaybackState()
        schedulePlaybackReset()
    }

    func resetPlaybackIfNeeded(now: Date = Date()) {
        guard FloatingPanelPlaybackRules.shouldReset(lastTapAt: lastTapAt, now: now) else { return }
        resetPlayback()
    }

    private func syncDisplayMode() {
        if isExpanded {
            displayMode = .expanded
        } else {
            displayMode = isHoverPreviewVisible ? .hoverList : .compact
        }
    }

    private func scheduleHoverRevealIfNeeded() {
        guard !isExpanded, !isHoverPreviewVisible else {
            syncDisplayMode()
            return
        }

        hoverRevealWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isHoveringMascot || self.isHoveringTaskPanel else { return }
                self.revealHoverPreview()
            }
        }
        hoverRevealWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverRules.revealDelay, execute: workItem)
    }

    private func revealHoverPreview() {
        hoverRevealWorkItem?.cancel()
        hoverRevealWorkItem = nil
        isHoverPreviewVisible = true
        syncDisplayMode()
    }

    private func scheduleHoverCollapseIfNeeded() {
        guard !isExpanded else { return }
        guard !isHoveringMascot, !isHoveringTaskPanel else {
            syncDisplayMode()
            return
        }

        hoverRevealWorkItem?.cancel()
        hoverRevealWorkItem = nil
        hoverCollapseWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, !self.isHoveringMascot, !self.isHoveringTaskPanel, !self.isExpanded else { return }
                self.isHoverPreviewVisible = false
                self.syncDisplayMode()
            }
        }
        hoverCollapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverRules.collapseDelay, execute: workItem)
    }

    private func cancelHoverCollapse() {
        hoverCollapseWorkItem?.cancel()
        hoverCollapseWorkItem = nil
    }

    private func schedulePlaybackReset() {
        playbackResetWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.resetPlayback()
            }
        }
        playbackResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + FloatingPanelPlaybackRules.resetDelay, execute: workItem)
    }

    private func resetPlayback() {
        playbackResetWorkItem?.cancel()
        playbackResetWorkItem = nil
        tapBoostCount = 0
        playbackSpeed = basePlaybackSpeed
        lastTapAt = nil
        updateMascotPlaybackState()
    }

    private func updateMascotPlaybackState() {
        mascotPlaybackState = hasLivePlayback || tapBoostCount > 0
            ? .playing(speed: playbackSpeed)
            : .stoppedAtFirstFrame
    }
}
