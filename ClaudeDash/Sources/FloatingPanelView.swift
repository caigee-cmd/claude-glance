// FloatingPanelView.swift
// ClaudeDash - Dynamic Island style floating panel

import SwiftUI

struct FloatingPanelView: View {
    @EnvironmentObject var sessionMonitor: SessionMonitor

    private var activeSessions: [ActiveSession] {
        sessionMonitor.activeSessions.filter { $0.status != .completed }
    }

    private var visibleSessions: [ActiveSession] {
        Array(activeSessions.prefix(FloatingPanelLayout.maxVisibleSessions))
    }

    private var hasActive: Bool {
        !activeSessions.isEmpty
    }

    private var hiddenCount: Int {
        max(activeSessions.count - visibleSessions.count, 0)
    }

    private var glowColor: Color {
        if activeSessions.contains(where: { $0.status == .toolRunning }) {
            return .claudeCyan
        }
        if activeSessions.contains(where: { $0.status == .thinking }) {
            return .claudeWarningOrange
        }
        return .green
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: FloatingPanelLayout.rowSpacing) {
                if visibleSessions.isEmpty {
                    emptyRow
                } else {
                    ForEach(visibleSessions) { session in
                        IslandSessionRow(session: session, now: context.date)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FloatingPanelLayout.horizontalPadding)
            .padding(.vertical, FloatingPanelLayout.verticalPadding)
            .background {
                panelBackground
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.white.opacity(0.16))
                    .frame(width: 132, height: 10)
                    .blur(radius: 16)
                    .offset(y: -8)
            }
            .overlay(alignment: .topTrailing) {
                if hiddenCount > 0 {
                    hiddenSessionsBadge
                        .padding(.top, 8)
                        .padding(.trailing, 12)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .contextMenu {
            Button("关闭面板") {
                NotificationCenter.default.post(name: .hideFloatingPanel, object: nil)
            }
        }
    }

    private var panelBackground: some View {
        let cornerRadius: CGFloat = visibleSessions.count <= 1 ? 26 : 30

        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.82), .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.12), .white.opacity(0.015)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 0.8)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(hasActive ? 0.55 : 0.18),
                            Color.claudePurple.opacity(hasActive ? 0.35 : 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: hasActive ? 1.1 : 0.7
                )
        }
        .shadow(color: .black.opacity(0.24), radius: 24, y: 14)
        .shadow(color: glowColor.opacity(hasActive ? 0.24 : 0.08), radius: hasActive ? 22 : 12, y: 10)
    }

    private var hiddenSessionsBadge: some View {
        Text("+\(hiddenCount)")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.white.opacity(0.08), in: Capsule())
    }

    private var emptyRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            Text("No active sessions")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(height: FloatingPanelLayout.rowHeight, alignment: .leading)
    }
}

// MARK: - Session Row

struct IslandSessionRow: View {
    let session: ActiveSession
    let now: Date
    @State private var pulsePhase = false

    private var isActive: Bool {
        session.status == .thinking || session.status == .toolRunning
    }

    var body: some View {
        HStack(spacing: 10) {
            // Pulsing dot
            ZStack {
                if isActive {
                    Circle()
                        .fill(statusColor.opacity(0.32))
                        .frame(width: 16, height: 16)
                        .scaleEffect(pulsePhase ? 1.4 : 0.8)
                        .opacity(pulsePhase ? 0 : 0.8)
                }
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 16, height: 16)

            Text(session.project)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(1)

            Spacer()

            if session.currentTool != .unknown {
                Image(systemName: session.currentTool.sfSymbol)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Text(elapsedTime)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 4)
        .frame(height: FloatingPanelLayout.rowHeight)
        .background(rowBackground)
        .onAppear {
            updatePulseAnimation(isActive: isActive)
        }
        .onChange(of: isActive) { _, active in
            updatePulseAnimation(isActive: active)
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .thinking: return .orange
        case .toolRunning: return .cyan
        case .completed: return .green
        case .unknown: return .gray
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.white.opacity(isActive ? 0.08 : 0.04))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(statusColor.opacity(isActive ? 0.22 : 0.08), lineWidth: 0.8)
            }
    }

    private var elapsedTime: String {
        let seconds = max(Int(now.timeIntervalSince(session.startTime)), 0)
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m \(seconds % 60)s" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func updatePulseAnimation(isActive: Bool) {
        if isActive {
            pulsePhase = false
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulsePhase = true
            }
        } else {
            pulsePhase = false
        }
    }
}
