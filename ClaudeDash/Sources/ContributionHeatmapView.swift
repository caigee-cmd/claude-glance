// ContributionHeatmapView.swift
// ClaudeDash - GitHub Contribution Grid 风格热力图
// 最近 13 周（91 天）的日活跃度，紫 → 青渐变色阶

import SwiftUI

struct ContributionHeatmapView: View {
    /// 日期 → 完成次数 (key: yyyy-MM-dd)
    let dailyCounts: [String: Int]

    var cellSize: CGFloat = 11
    var cellSpacing: CGFloat = 2
    var numWeeks: Int = 13
    var showDayLabels: Bool = true
    var showMonthLabels: Bool = false

    @State private var hoveredDay: HeatmapCell.DayInfo?

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 月份标签
            if showMonthLabels {
                monthLabelsRow
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                // 星期标签列
                if showDayLabels {
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { row in
                            Text(dayLabel(row))
                                .font(.system(size: max(cellSize * 0.7, 9), weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: cellSize)
                        }
                    }
                }

                // 主网格
                HStack(spacing: cellSpacing) {
                    ForEach(0..<numWeeks, id: \.self) { weekIndex in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                let dayInfo = dayInfoFor(week: weekIndex, day: dayIndex)
                                HeatmapCell(
                                    info: dayInfo,
                                    maxCount: maxDailyCount,
                                    cellSize: cellSize,
                                    hoveredDay: $hoveredDay
                                )
                            }
                        }
                    }
                }
            }

            // 底部行：Tooltip + 色阶图例
            HStack {
                // Tooltip
                if let hovered = hoveredDay {
                    HStack(spacing: 6) {
                        Text(hovered.dateDisplay)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.7))
                        Text("\(hovered.count) sessions")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeOut(duration: 0.15), value: hoveredDay?.dateString)
                }

                Spacer()

                // 色阶图例
                HStack(spacing: 3) {
                    Text("Less")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)

                    ForEach(legendColors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: max(cellSize * 0.15, 1.5), style: .continuous)
                            .fill(color)
                            .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                    }

                    Text("More")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - 数据计算

    private var gridStartDate: Date {
        let today = Date()
        // 找到本周一
        let weekday = calendar.component(.weekday, from: today) // 1=Sun ... 7=Sat
        let mondayOffset = (weekday + 5) % 7 // Mon=0, Tue=1, ..., Sun=6
        let thisMonday = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!
        // 向前推 numWeeks-1 周
        return calendar.date(byAdding: .weekOfYear, value: -(numWeeks - 1), to: thisMonday)!
    }

    private var maxDailyCount: Int {
        max(dailyCounts.values.max() ?? 1, 1)
    }

    /// 色阶图例用的 5 级颜色
    private var legendColors: [Color] {
        [
            .white.opacity(0.04),
            .claudePurple.opacity(0.3),
            .claudePurple.opacity(0.55),
            Color(
                red: (124 + (34 - 124) * 0.5) / 255,
                green: (58 + (211 - 58) * 0.5) / 255,
                blue: (237 + (238 - 237) * 0.5) / 255
            ).opacity(0.75),
            .claudeCyan.opacity(0.85),
        ]
    }

    private func dayInfoFor(week: Int, day: Int) -> HeatmapCell.DayInfo {
        let offset = week * 7 + day
        let date = calendar.date(byAdding: .day, value: offset, to: gridStartDate)!
        let dateStr = dateFormatter.string(from: date)
        let count = dailyCounts[dateStr] ?? 0
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()

        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "M月d日"
        let dateDisplay = displayFmt.string(from: date)

        return HeatmapCell.DayInfo(
            dateString: dateStr,
            dateDisplay: dateDisplay,
            count: count,
            isToday: isToday,
            isFuture: isFuture
        )
    }

    private func dayLabel(_ index: Int) -> String {
        // Mon=0 ... Sun=6
        switch index {
        case 0: return "M"
        case 2: return "W"
        case 4: return "F"
        default: return " "
        }
    }

    // MARK: - 月份标签

    private var monthLabelsRow: some View {
        HStack(spacing: cellSpacing) {
            if showDayLabels {
                Color.clear.frame(width: 18)
            }

            ForEach(0..<numWeeks, id: \.self) { weekIndex in
                let date = calendar.date(byAdding: .day, value: weekIndex * 7, to: gridStartDate)!
                let day = calendar.component(.day, from: date)

                if day <= 7 {
                    let fmt = DateFormatter()
                    let _ = (fmt.dateFormat = "MMM")
                    Text(fmt.string(from: date))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize)
                } else {
                    Color.clear.frame(width: cellSize)
                }
            }
        }
    }
}

// MARK: - 单个热力图格子

struct HeatmapCell: View {
    struct DayInfo: Equatable {
        let dateString: String
        let dateDisplay: String
        let count: Int
        let isToday: Bool
        let isFuture: Bool
    }

    let info: DayInfo
    let maxCount: Int
    let cellSize: CGFloat
    @Binding var hoveredDay: DayInfo?

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: max(cellSize * 0.2, 2), style: .continuous)
            .fill(cellColor)
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if info.isToday {
                    RoundedRectangle(cornerRadius: max(cellSize * 0.2, 2), style: .continuous)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1.2)
                }
            }
            .overlay {
                if info.isToday {
                    RoundedRectangle(cornerRadius: max(cellSize * 0.2, 2), style: .continuous)
                        .fill(.white.opacity(0.1))
                }
            }
            .shadow(
                color: info.isToday ? .white.opacity(0.3) : .clear,
                radius: info.isToday ? 3 : 0
            )
            .scaleEffect(isHovered ? 1.3 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                guard !info.isFuture else { return }
                isHovered = hovering
                if hovering {
                    hoveredDay = info
                } else if hoveredDay?.dateString == info.dateString {
                    hoveredDay = nil
                }
            }
    }

    private var cellColor: Color {
        if info.isFuture { return .clear }
        if info.count == 0 { return .white.opacity(0.04) }

        let ratio = Double(info.count) / Double(max(maxCount, 1))
        switch ratio {
        case ..<0.25:
            return .claudePurple.opacity(0.3)
        case ..<0.50:
            return .claudePurple.opacity(0.55)
        case ..<0.75:
            return Color(
                red: (124 + (34 - 124) * 0.5) / 255,
                green: (58 + (211 - 58) * 0.5) / 255,
                blue: (237 + (238 - 237) * 0.5) / 255
            ).opacity(0.75)
        default:
            return .claudeCyan.opacity(0.85)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.opacity(0.9)
        ContributionHeatmapView(
            dailyCounts: {
                var counts: [String: Int] = [:]
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                for i in 0..<91 {
                    let d = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                    counts[fmt.string(from: d)] = Int.random(in: 0...8)
                }
                return counts
            }(),
            cellSize: 14,
            cellSpacing: 3,
            showDayLabels: true
        )
        .padding()
    }
    .frame(width: 400, height: 200)
}
