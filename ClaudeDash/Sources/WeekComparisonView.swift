// WeekComparisonView.swift
// ClaudeDash - 本周 vs 上周对比卡片

import SwiftUI

struct WeekComparisonView: View {
    let thisWeek: WeekSummary
    let lastWeek: WeekSummary
    let changePercent: (Int, Int) -> Double
    let changePercentDouble: (Double, Double) -> Double

    var body: some View {
        VStack(spacing: 10) {
            // 主指标对比
            HStack(spacing: 8) {
                comparisonCard(
                    icon: "checkmark.circle.fill",
                    label: "Sessions",
                    thisValue: "\(thisWeek.sessions)",
                    lastValue: "\(lastWeek.sessions)",
                    change: changePercent(thisWeek.sessions, lastWeek.sessions),
                    color: .green
                )
                comparisonCard(
                    icon: "dollarsign.circle.fill",
                    label: "Cost",
                    thisValue: thisWeek.cost.usdFormatted,
                    lastValue: lastWeek.cost.usdFormatted,
                    change: changePercentDouble(thisWeek.cost, lastWeek.cost),
                    color: .orange
                )
                comparisonCard(
                    icon: "textformat.123",
                    label: "Tokens",
                    thisValue: thisWeek.tokens.tokenFormatted,
                    lastValue: lastWeek.tokens.tokenFormatted,
                    change: changePercent(thisWeek.tokens, lastWeek.tokens),
                    color: .claudeCyan
                )
                comparisonCard(
                    icon: "clock.fill",
                    label: "Duration",
                    thisValue: thisWeek.duration.durationFormatted,
                    lastValue: lastWeek.duration.durationFormatted,
                    change: changePercentDouble(thisWeek.duration, lastWeek.duration),
                    color: .blue
                )
            }

            // 二级指标
            HStack(spacing: 8) {
                miniComparison(label: "Active Days", thisValue: "\(thisWeek.activeDays)/7", lastValue: "\(lastWeek.activeDays)/7")
                miniComparison(label: "Tool Uses", thisValue: "\(thisWeek.toolUses)", lastValue: "\(lastWeek.toolUses)")
                miniComparison(label: "Messages", thisValue: "\(thisWeek.messages)", lastValue: "\(lastWeek.messages)")
            }
        }
    }

    private func comparisonCard(
        icon: String, label: String,
        thisValue: String, lastValue: String,
        change: Double, color: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)

            Text(thisValue)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // 变化 badge
            if abs(change) > 0.5 {
                HStack(spacing: 2) {
                    Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.0f%%", abs(change)))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(change > 0 ? .green : .red)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    (change > 0 ? Color.green : Color.red).opacity(0.1),
                    in: Capsule()
                )
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(0.65))

            // 上周
            Text("prev: \(lastValue)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .statsCard(cornerRadius: 14)
    }

    private func miniComparison(label: String, thisValue: String, lastValue: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Text(thisValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("←")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(lastValue)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .statsBackground(cornerRadius: 10)
    }
}
