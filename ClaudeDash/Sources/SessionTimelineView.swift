// SessionTimelineView.swift
// ClaudeDash - Session 时间线视图

import SwiftUI

struct AggregatedProject: Identifiable {
    let id: String
    let projectName: String
    let source: SessionSource
    let totalDuration: Double
    let totalCost: Double
    let earliestStart: Date
    let sessionCount: Int
}

struct SessionTimelineView: View {
    let sessions: [ScannedSession]
    var maxBarWidth: CGFloat = 400

    @State private var hoveredProject: String?

    private var aggregatedProjects: [AggregatedProject] {
        let grouped = Dictionary(grouping: sessions) { "\($0.projectName)|\($0.source.rawValue)" }
        return grouped.map { key, group in
            let first = group.first!
            let totalDur = group.reduce(0.0) { $0 + $1.durationSeconds }
            let totalCost = group.reduce(0.0) { $0 + $1.estimatedCost }
            return AggregatedProject(
                id: key,
                projectName: first.projectName,
                source: first.source,
                totalDuration: totalDur,
                totalCost: totalCost,
                earliestStart: group.map(\.startTime).min()!,
                sessionCount: group.count
            )
        }
        .sorted { $0.earliestStart < $1.earliestStart }
    }

    private var timeRange: (start: Date, end: Date)? {
        guard let first = sessions.first, let last = sessions.last else { return nil }
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: first.startTime)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: last.endTime))!
        return (start: dayStart, end: dayEnd)
    }

    private var totalDuration: TimeInterval {
        guard let range = timeRange else { return 86400 }
        return range.end.timeIntervalSince(range.start)
    }

    var body: some View {
        if sessions.isEmpty {
            emptyTimeline
        } else {
            VStack(alignment: .leading, spacing: 3) {
                // 时间轴标签
                timeAxis

                // 按项目聚合的条
                ForEach(aggregatedProjects) { project in
                    projectBar(project)
                }
            }
        }
    }

    private var timeAxis: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                // 时间刻度
                if let range = timeRange {
                    ForEach(SessionTimelineAxis.ticks(for: range)) { tick in
                        let offset = tick.date.timeIntervalSince(range.start)
                        let x = (offset / totalDuration) * Double(width)
                        if x >= 0 && x <= Double(width) {
                            Text(tick.label)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .position(x: x, y: 5)
                        }
                    }
                }
            }
        }
        .frame(height: 12)
    }

    private func projectBar(_ project: AggregatedProject) -> some View {
        let isHovered = hoveredProject == project.id

        return GeometryReader { geo in
            let width = geo.size.width
            let barStart = barOffset(for: project, in: width)
            let barWidth = barWidthFor(project, in: width)

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(projectGradient(project))
                    .frame(width: max(barWidth, 4), height: isHovered ? 20 : 16)
                    .overlay(alignment: .leading) {
                        if barWidth > 60 {
                            HStack(spacing: 3) {
                                Text(project.projectName)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                                if project.sessionCount > 1 {
                                    Text("\(project.sessionCount)s")
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Text(project.totalDuration.durationFormatted)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.leading, 4)
                            .foregroundStyle(.white)
                        }
                    }
                    .offset(x: barStart)
                    .onHover { hovering in
                        hoveredProject = hovering ? project.id : nil
                    }

                Spacer(minLength: 0)
            }
        }
        .frame(height: isHovered ? 20 : 16)
        .animation(.spring(response: 0.2), value: isHovered)
    }

    private func barOffset(for project: AggregatedProject, in totalWidth: CGFloat) -> CGFloat {
        guard let range = timeRange else { return 0 }
        let offset = project.earliestStart.timeIntervalSince(range.start)
        return CGFloat(offset / totalDuration) * totalWidth
    }

    private func barWidthFor(_ project: AggregatedProject, in totalWidth: CGFloat) -> CGFloat {
        CGFloat(project.totalDuration / totalDuration) * totalWidth
    }

    private func projectGradient(_ project: AggregatedProject) -> LinearGradient {
        let costRatio = min(project.totalCost / 1.0, 1.0)
        if costRatio > 0.5 {
            return LinearGradient(colors: [.claudeWarningOrange, .claudeWarningRed], startPoint: .leading, endPoint: .trailing)
        }
        switch project.source {
        case .kimi:
            return LinearGradient(colors: [.kimiCyan.opacity(0.8), .kimiCyan.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
        case .claude:
            return LinearGradient(colors: [.claudePurple, .claudeCyan], startPoint: .leading, endPoint: .trailing)
        case .codex:
            return LinearGradient(colors: [.codexGreen.opacity(0.8), .codexGreen.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var emptyTimeline: some View {
        VStack(spacing: 6) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("No sessions yet today")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
