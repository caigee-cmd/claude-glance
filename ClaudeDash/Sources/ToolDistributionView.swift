// ToolDistributionView.swift
// ClaudeDash - 工具调用分布图（环形图 + 列表）

import SwiftUI
import Charts

struct ToolDistributionView: View {
    let distribution: [(tool: String, count: Int)]
    let totalCount: Int
    var compact: Bool = false

    private var topTools: [(tool: String, count: Int)] {
        Array(distribution.prefix(8))
    }

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    // MARK: - 紧凑视图（用于 Popover）

    private var compactView: some View {
        HStack(spacing: 12) {
            // 迷你环形图
            miniDonut
                .frame(width: 60, height: 60)

            // Top 3 工具
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(topTools.prefix(3).enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(toolColor(item.tool))
                            .frame(width: 5, height: 5)
                        Text(item.tool)
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(item.count)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.primary.opacity(0.65))
                    }
                }
            }
        }
    }

    // MARK: - 完整视图

    private var fullView: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 20) {
                // 环形图
                donutChart
                    .frame(width: 140, height: 140)

                // 工具列表
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(topTools.enumerated()), id: \.offset) { _, item in
                        toolRow(item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 环形图

    private var donutChart: some View {
        ZStack {
            ForEach(Array(arcSlices.enumerated()), id: \.offset) { _, slice in
                ArcShape(startAngle: slice.start, endAngle: slice.end)
                    .fill(slice.color)
            }

            // 中心总数
            VStack(spacing: 1) {
                Text("\(totalCount)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("calls")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.65))
            }
        }
    }

    private var miniDonut: some View {
        ZStack {
            ForEach(Array(arcSlices.enumerated()), id: \.offset) { _, slice in
                ArcShape(startAngle: slice.start, endAngle: slice.end)
                    .fill(slice.color)
            }
        }
    }

    private struct ArcSlice {
        let start: Angle
        let end: Angle
        let color: Color
    }

    private var arcSlices: [ArcSlice] {
        guard totalCount > 0 else { return [] }
        var slices: [ArcSlice] = []
        var currentAngle: Double = -90
        for item in topTools {
            let sweep = (Double(item.count) / Double(totalCount)) * 360
            slices.append(ArcSlice(
                start: .degrees(currentAngle),
                end: .degrees(currentAngle + sweep),
                color: toolColor(item.tool)
            ))
            currentAngle += sweep
        }
        // 剩余
        if currentAngle < 270 {
            slices.append(ArcSlice(
                start: .degrees(currentAngle),
                end: .degrees(270),
                color: .white.opacity(0.08)
            ))
        }
        return slices
    }

    private func toolRow(_ item: (tool: String, count: Int)) -> some View {
        let pct = totalCount > 0 ? Double(item.count) / Double(totalCount) : 0
        return HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(toolColor(item.tool))
                .frame(width: 12, height: 12)

            Image(systemName: toolSFSymbol(item.tool))
                .font(.system(size: 12))
                .foregroundStyle(.primary.opacity(0.65))
                .frame(width: 14)

            Text(item.tool)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Text("\(item.count)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.65))

            Text(String(format: "%.0f%%", pct * 100))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    // MARK: - 工具颜色

    func toolColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "read": return .blue
        case "edit": return .claudePurple
        case "write": return .green
        case "bash": return .orange
        case "grep": return .claudeCyan
        case "glob": return .mint
        case "todoread", "todowrite": return .yellow
        case "webfetch", "websearch": return .pink
        default: return .gray
        }
    }

    func toolSFSymbol(_ name: String) -> String {
        switch name.lowercased() {
        case "read": return "doc.text"
        case "edit": return "pencil"
        case "write": return "doc.badge.plus"
        case "bash": return "terminal"
        case "grep": return "magnifyingglass"
        case "glob": return "folder.badge.magnifyingglass"
        default: return "wrench"
        }
    }
}

// MARK: - 弧形 Shape

struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.6
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

// MARK: - 工具趋势图

struct ToolTrendChartView: View {
    let data: [DailySummary]
    var height: CGFloat = 140

    var body: some View {
        Chart(data) { day in
            BarMark(
                x: .value("Date", day.shortDateLabel),
                y: .value("Tools", day.totalToolUseCount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.claudePurple.opacity(0.7), .claudeCyan.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(3)
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    .foregroundStyle(.tertiary)
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: height)
    }
}
