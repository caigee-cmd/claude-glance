// WeeklyPunchCardView.swift
// ClaudeDash - 7×24 全周热力图（GitHub Punch Card 风格）

import SwiftUI

struct WeeklyPunchCardView: View {
    /// [weekday Mon=0..Sun=6][hour 0-23]
    let heatmap: [[Int]]
    var cellSize: CGFloat = 16
    var cellSpacing: CGFloat = 2

    @State private var hoveredCell: (day: Int, hour: Int)?

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var maxCount: Int {
        max(heatmap.flatMap { $0 }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 小时标签行
            HStack(spacing: cellSpacing) {
                Color.clear.frame(width: 28) // 对齐日标签
                ForEach(0..<24, id: \.self) { hour in
                    if hour % 3 == 0 {
                        Text("\(hour)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize)
                    } else {
                        Color.clear.frame(width: cellSize)
                    }
                }
            }

            // 主网格
            ForEach(0..<7, id: \.self) { day in
                HStack(spacing: cellSpacing) {
                    // 日标签
                    Text(dayLabels[day])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)

                    // 24 小时格子
                    ForEach(0..<24, id: \.self) { hour in
                        let count = day < heatmap.count && hour < heatmap[day].count ? heatmap[day][hour] : 0
                        punchCell(count: count, day: day, hour: hour)
                    }
                }
            }

            // 底部：tooltip + 色阶
            HStack {
                if let h = hoveredCell {
                    let count = heatmap[h.day][h.hour]
                    Text("\(dayLabels[h.day]) \(h.hour):00 — \(count) sessions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                Spacer()

                // 色阶图例
                HStack(spacing: 2) {
                    Text("Less")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                    ForEach(punchLegendColors.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(punchLegendColors[i])
                            .frame(width: 8, height: 8)
                    }
                    Text("More")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 2)
        }
    }

    private func punchCell(count: Int, day: Int, hour: Int) -> some View {
        let isHovered = hoveredCell?.day == day && hoveredCell?.hour == hour

        return RoundedRectangle(cornerRadius: max(cellSize * 0.2, 2), style: .continuous)
            .fill(punchColor(count))
            .frame(width: cellSize, height: cellSize)
            .scaleEffect(isHovered ? 1.3 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                if hovering {
                    hoveredCell = (day: day, hour: hour)
                } else if hoveredCell?.day == day && hoveredCell?.hour == hour {
                    hoveredCell = nil
                }
            }
    }

    private func punchColor(_ count: Int) -> Color {
        if count == 0 { return .white.opacity(0.03) }
        let ratio = Double(count) / Double(maxCount)
        switch ratio {
        case ..<0.25: return .claudePurple.opacity(0.25)
        case ..<0.50: return .claudePurple.opacity(0.5)
        case ..<0.75: return Color(
            red: (124 + (34 - 124) * 0.5) / 255,
            green: (58 + (211 - 58) * 0.5) / 255,
            blue: (237 + (238 - 237) * 0.5) / 255
        ).opacity(0.7)
        default: return .claudeCyan.opacity(0.85)
        }
    }

    private var punchLegendColors: [Color] {
        [
            .white.opacity(0.03),
            .claudePurple.opacity(0.25),
            .claudePurple.opacity(0.5),
            Color(
                red: (124 + (34 - 124) * 0.5) / 255,
                green: (58 + (211 - 58) * 0.5) / 255,
                blue: (237 + (238 - 237) * 0.5) / 255
            ).opacity(0.7),
            .claudeCyan.opacity(0.85),
        ]
    }
}
