// StatusBarPopoverView.swift
// ClaudeDash - Compact popover: quick glance at today's stats + active sessions

import SwiftUI

private enum PopoverPanelStyle {
    static let width: CGFloat = 364
    static let outerPadding: CGFloat = 14
    static let metricSpacing: CGFloat = 4
    static let sectionLabelSpacing: CGFloat = 6
    static let borderOpacity: Double = 0.10
    static let secondaryTextOpacity: Double = 0.68
    static let tertiaryTextOpacity: Double = 0.52

    static var titleFont: Font {
        .system(size: 15, weight: .semibold)
    }

    static var metricLabelFont: Font {
        .system(size: 9, weight: .semibold)
    }

    static var metricValueFont: Font {
        .system(size: 15, weight: .bold, design: .rounded)
    }

    static var sectionTitleFont: Font {
        .system(size: 11, weight: .semibold)
    }

    static var rowTitleFont: Font {
        .system(size: 12, weight: .semibold)
    }

    static var rowMetaFont: Font {
        .system(size: 10, weight: .medium)
    }
}

struct StatusBarPopoverView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var sessionMonitor: SessionMonitor
    @AppStorage(
        FloatingMascotPreferences.enabledUserDefaultsKey,
        store: ClaudeDashDefaults.shared
    ) private var isMascotEnabled = false

    var onOpenStats: () -> Void
    var onTestNotification: () -> Void
    var onInstallHook: () -> Void
    var onTogglePanel: () -> Void
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, PopoverPanelStyle.outerPadding)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ringsOverview
                .padding(.horizontal, PopoverPanelStyle.outerPadding)
                .padding(.bottom, 8)

            if !sessionMonitor.activeSessions.isEmpty {
                sectionDivider

                activeSessionsSection
                    .padding(.horizontal, PopoverPanelStyle.outerPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }

            if !statsManager.recentSessions.isEmpty {
                sectionDivider

                recentCompletionsSection
                    .padding(.horizontal, PopoverPanelStyle.outerPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }

            if sessionMonitor.activeSessions.isEmpty && statsManager.recentSessions.isEmpty {
                sectionDivider

                emptyState
                    .padding(.horizontal, PopoverPanelStyle.outerPadding)
                    .padding(.vertical, 12)
            }

            sectionDivider

            actionBar
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .frame(width: PopoverPanelStyle.width)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(PopoverPanelStyle.borderOpacity), lineWidth: 0.5)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.055))

                Image(systemName: ClaudeDashSymbols.appBadge)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ClaudeGradients.primary)
            }
            .frame(width: 24, height: 24)

            Text("Claude Glance")
                .font(PopoverPanelStyle.titleFont)

            Spacer()

            if statsManager.usageStreak > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("\(statsManager.usageStreak)d")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - Rings Overview

    private var ringsOverview: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack {
                ActivityRingsView(
                    sessionProgress: statsManager.sessionRingProgress,
                    weeklyProgress: statsManager.weeklyActivityProgress,
                    tokenProgress: statsManager.tokenRingProgress,
                    centerValue: statsManager.todayTotalTokens.tokenFormatted,
                    centerSubtitle: "tokens today",
                    size: 108
                )
                .padding(4)
            }
            .frame(width: 116)
            .statsBackground(cornerRadius: 14)

            VStack(spacing: 0) {
                popoverMetric(
                    value: "\(statsManager.todayCompletionCount)",
                    label: "Sessions",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: statsManager.completionTrend
                )
                popoverMetric(
                    value: statsManager.todayCost.usdFormatted,
                    label: "Cost",
                    icon: "dollarsign.circle.fill",
                    color: .orange,
                    trendDouble: statsManager.costTrend
                )
                popoverMetric(
                    value: statsManager.todayDurationSeconds.durationFormatted,
                    label: "Duration",
                    icon: "clock.fill",
                    color: .blue,
                    trendDouble: statsManager.durationTrend
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .statsBackground(cornerRadius: 14)
            .frame(maxWidth: .infinity)
        }
    }

    private func popoverMetric(
        value: String, label: String, icon: String, color: Color,
        trend: Int? = nil, trendDouble: Double? = nil
    ) -> some View {
        let dir: Int = {
            if let t = trend { return t }
            if let d = trendDouble { return d > 0.001 ? 1 : (d < -0.001 ? -1 : 0) }
            return 0
        }()

        return HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(PopoverPanelStyle.metricLabelFont)
                    .foregroundStyle(.primary.opacity(PopoverPanelStyle.tertiaryTextOpacity))
                    .tracking(0.35)
                    .lineLimit(1)

                Text(value)
                    .font(PopoverPanelStyle.metricValueFont)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            Spacer(minLength: 6)

            if dir != 0 {
                compactTrendBadge(direction: dir)
            }
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
                .opacity(label == "Duration" ? 0 : 1)
        }
    }

    // MARK: - Active Sessions

    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Active", count: sessionMonitor.activeSessions.count, accent: .yellow)

            ForEach(sessionMonitor.activeSessions.prefix(3)) { session in
                ActiveSessionRow(session: session)
            }
        }
    }

    // MARK: - Recent Completions

    private var recentCompletionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Recent", accent: .green)

            ForEach(statsManager.recentSessions.suffix(3)) { session in
                RecentSessionRow(session: session)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: ClaudeDashSymbols.appBadge)
                .font(.system(size: 20))
                .foregroundStyle(.quaternary)

            VStack(alignment: .leading, spacing: 2) {
                Text("No sessions yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Stats will appear after your first task")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary.opacity(PopoverPanelStyle.tertiaryTextOpacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .statsBackground(cornerRadius: 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 4) {
            actionButton(icon: "chart.bar.fill", label: "Stats", prominence: .primary, action: onOpenStats)
            actionButton(
                icon: ClaudeDashSymbols.panelAction,
                label: isMascotEnabled ? "Mascot On" : "Mascot Off",
                prominence: isMascotEnabled ? .primary : .regular,
                action: onTogglePanel
            )
            actionButton(icon: "gearshape", label: "Settings", action: onOpenSettings)
            actionButton(icon: ClaudeDashSymbols.quitAction, label: "Quit", action: onQuit)
        }
        .padding(4)
        .statsBackground(cornerRadius: 16)
    }

    // MARK: - Helpers

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
            .padding(.horizontal, 10)
    }

    private func sectionLabel(_ title: String, count: Int? = nil, accent: Color = .primary) -> some View {
        HStack(spacing: PopoverPanelStyle.sectionLabelSpacing) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)

            Text(title.uppercased())
                .font(PopoverPanelStyle.sectionTitleFont)
                .foregroundStyle(.primary.opacity(PopoverPanelStyle.secondaryTextOpacity))
                .tracking(0.55)

            if let count {
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(PopoverPanelStyle.tertiaryTextOpacity))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
            }
        }
    }

    private func compactTrendBadge(direction: Int) -> some View {
        Image(systemName: direction > 0 ? "arrow.up.right" : "arrow.down.right")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(direction > 0 ? .green : .red)
            .frame(width: 18, height: 18)
            .background(
                Circle()
                    .fill((direction > 0 ? Color.green : Color.red).opacity(0.12))
            )
    }

    private enum ActionProminence {
        case regular
        case primary
    }

    private func actionButton(
        icon: String,
        label: String,
        prominence: ActionProminence = .regular,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 7)
            .padding(.vertical, 7)
            .background {
                if prominence == .primary {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                        )
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominence == .primary ? Color.primary : Color.primary.opacity(0.72))
    }
}

// MARK: - Active Session Row

struct ActiveSessionRow: View {
    let session: ActiveSession
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.5), radius: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.project)
                    .font(PopoverPanelStyle.rowTitleFont)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(activityLabel)
                        .font(PopoverPanelStyle.rowMetaFont)
                        .foregroundStyle(.primary.opacity(PopoverPanelStyle.tertiaryTextOpacity))
                        .lineLimit(1)

                    if session.tokenUsage > 0 {
                        MiniTokenBar(usage: session.tokenUsage)
                            .frame(width: 42, height: 4)
                    }
                }
            }

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                Image(systemName: session.currentTool.sfSymbol)
                    .font(.system(size: 9, weight: .semibold))
                Text(elapsedTime)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
            .foregroundStyle(.primary.opacity(PopoverPanelStyle.secondaryTextOpacity))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.08 : 0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                }
        }
        .brightness(isHovered ? 0.03 : 0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var statusColor: Color {
        switch session.status {
        case .thinking: return .yellow
        case .toolRunning: return .blue
        case .completed: return .green
        case .unknown: return .gray
        }
    }

    private var elapsedTime: String {
        let seconds = Int(-session.startTime.timeIntervalSinceNow)
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m \(seconds % 60)s" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private var activityLabel: String {
        session.currentTool == .unknown ? "Live session" : session.currentTool.rawValue
    }
}

// MARK: - Mini Token Bar

struct MiniTokenBar: View {
    let usage: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.08))
                Capsule()
                    .fill(barColor)
                    .frame(width: max(0, geo.size.width * min(usage, 1.0)))
            }
        }
        .frame(height: 3)
    }

    private var barColor: Color {
        if usage < 0.5 { return .green.opacity(0.7) }
        if usage < 0.8 { return .yellow.opacity(0.7) }
        return .red.opacity(0.8)
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: SessionRecord
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.green.opacity(0.7))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.project)
                    .font(PopoverPanelStyle.rowTitleFont)
                    .lineLimit(1)

                Text(session.completedAt.timeAgo)
                    .font(PopoverPanelStyle.rowMetaFont)
                    .foregroundStyle(.primary.opacity(PopoverPanelStyle.tertiaryTextOpacity))
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.durationMs.humanReadableDuration)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary.opacity(PopoverPanelStyle.secondaryTextOpacity))
                Text(session.cost.usdFormatted)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.78))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.08 : 0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                }
        }
        .brightness(isHovered ? 0.03 : 0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - PopoverStatCard (compat)

struct PopoverStatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    var trend: Int? = nil
    var trendDouble: Double? = nil

    var body: some View {
        GlassMetricCard(
            icon: icon,
            value: value,
            label: label,
            accentColor: color,
            trend: trend,
            trendDouble: trendDouble
        )
    }
}

// MARK: - PopoverActionButton (compat)

struct PopoverActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Date Extension

extension Date {
    var timeAgo: String {
        let seconds = Int(-self.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
