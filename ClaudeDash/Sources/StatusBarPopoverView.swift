// StatusBarPopoverView.swift
// ClaudeDash - Compact popover: quick glance at today's stats + active sessions

import SwiftUI

struct StatusBarPopoverView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var sessionMonitor: SessionMonitor

    var onOpenSettings: () -> Void
    var onOpenStats: () -> Void
    var onTestNotification: () -> Void
    var onInstallHook: () -> Void
    var onTogglePanel: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider().opacity(0.15)

            todayMetrics
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            if !sessionMonitor.activeSessions.isEmpty {
                Divider().opacity(0.15)

                activeSessionsSection
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }

            if !statsManager.recentSessions.isEmpty {
                Divider().opacity(0.15)

                recentCompletionsSection
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }

            if sessionMonitor.activeSessions.isEmpty && statsManager.recentSessions.isEmpty {
                Divider().opacity(0.15)

                emptyState
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }

            Divider().opacity(0.15)

            actionBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 360)
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ClaudeGradients.primary)

            Text("ClaudeDash")
                .font(.system(size: 15, weight: .semibold))
                .padding(.leading, 6)

            Spacer()

            if statsManager.usageStreak > 1 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(statsManager.usageStreak)d")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .glassBackground(cornerRadius: 8)
            }
        }
    }

    // MARK: - Today Metrics

    private var todayMetrics: some View {
        HStack(spacing: 8) {
            metricCell(
                value: "\(statsManager.todayCompletionCount)",
                label: "Sessions",
                icon: "checkmark.circle.fill",
                color: .green,
                trend: statsManager.completionTrend
            )
            metricCell(
                value: statsManager.todayCost.usdFormatted,
                label: "Cost",
                icon: "dollarsign.circle.fill",
                color: .orange,
                trendDouble: statsManager.costTrend
            )
            metricCell(
                value: statsManager.todayDurationSeconds.durationFormatted,
                label: "Duration",
                icon: "clock.fill",
                color: .blue,
                trendDouble: statsManager.durationTrend
            )
            metricCell(
                value: statsManager.todayTotalTokens.tokenFormatted,
                label: "Tokens",
                icon: "sum",
                color: .claudeCyan
            )
        }
    }

    private func metricCell(
        value: String, label: String, icon: String, color: Color,
        trend: Int? = nil, trendDouble: Double? = nil
    ) -> some View {
        let dir: Int = {
            if let t = trend { return t }
            if let d = trendDouble { return d > 0.001 ? 1 : (d < -0.001 ? -1 : 0) }
            return 0
        }()

        return VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(color)
                if dir != 0 {
                    Image(systemName: dir > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(dir > 0 ? .green : .red)
                }
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .glassBackground(cornerRadius: 10)
    }

    // MARK: - Active Sessions

    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Active", count: sessionMonitor.activeSessions.count)

            ForEach(sessionMonitor.activeSessions.prefix(3)) { session in
                ActiveSessionRow(session: session)
            }
        }
    }

    // MARK: - Recent Completions

    private var recentCompletionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Recent")

            ForEach(statsManager.recentSessions.suffix(3)) { session in
                RecentSessionRow(session: session)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundStyle(.quaternary)

            VStack(alignment: .leading, spacing: 2) {
                Text("No sessions yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Stats will appear after your first task")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 2) {
            actionButton(icon: "chart.bar.fill", label: "Stats", action: onOpenStats)
            actionButton(icon: "macwindow", label: "Panel", action: onTogglePanel)
            actionButton(icon: "gearshape", label: "Settings", action: onOpenSettings)
            actionButton(icon: "arrow.down.circle", label: "Hook", action: onInstallHook)

            Spacer()

            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            if let count {
                Text("(\(count))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
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

            Text(session.project)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Spacer()

            if session.tokenUsage > 0 {
                MiniTokenBar(usage: session.tokenUsage)
                    .frame(width: 32)
            }

            Text(elapsedTime)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)

            Image(systemName: session.currentTool.sfSymbol)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassBackground(cornerRadius: 8)
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
                .font(.system(size: 11))
                .foregroundStyle(.green.opacity(0.7))

            Text(session.project)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Spacer()

            Text(session.durationMs.humanReadableDuration)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(session.cost.usdFormatted)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.65))

            Text(session.completedAt.timeAgo)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassBackground(cornerRadius: 8)
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
