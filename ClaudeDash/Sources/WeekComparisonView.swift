// WeekComparisonView.swift
// ClaudeDash - 本周 vs 上周对比卡片

import SwiftUI

struct WeekComparisonView: View {
    let thisWeek: WeekSummary
    let lastWeek: WeekSummary
    let changePercent: (Int, Int) -> Double
    let changePercentDouble: (Double, Double) -> Double

    var body: some View {
        VStack(spacing: StatsPanelStyle.blockSpacing) {
            // 主指标对比
            HStack(alignment: .top, spacing: StatsPanelStyle.regularSpacing) {
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
            HStack(spacing: StatsPanelStyle.regularSpacing) {
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
        VStack(alignment: .leading, spacing: StatsPanelStyle.regularSpacing) {
            HStack(spacing: StatsPanelStyle.compactSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 14)

                Text(label)
                    .font(StatsPanelStyle.secondaryLabel)
                    .foregroundStyle(.primary.opacity(StatsPanelStyle.secondaryTextOpacity))
                    .lineLimit(1)
            }

            Text(thisValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(alignment: .bottom, spacing: 8) {
                comparisonChangeBadge(change: change)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last week")
                        .font(StatsPanelStyle.miniLabel)
                        .foregroundStyle(.primary.opacity(StatsPanelStyle.tertiaryTextOpacity))
                        .lineLimit(1)

                    Text(lastValue)
                        .font(StatsPanelStyle.metaValue)
                        .foregroundStyle(.primary.opacity(StatsPanelStyle.inactiveTextOpacity))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StatsPanelStyle.cardPadding)
        .padding(.vertical, StatsPanelStyle.cardPadding)
        .statsCard(cornerRadius: 14)
    }

    private func miniComparison(label: String, thisValue: String, lastValue: String) -> some View {
        VStack(alignment: .leading, spacing: StatsPanelStyle.compactSpacing) {
            Text(label)
                .font(StatsPanelStyle.secondaryLabel)
                .foregroundStyle(.primary.opacity(StatsPanelStyle.secondaryTextOpacity))
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(thisValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                Text("vs")
                    .font(StatsPanelStyle.miniLabel)
                    .foregroundStyle(.primary.opacity(StatsPanelStyle.tertiaryTextOpacity))
                Text(lastValue)
                    .font(StatsPanelStyle.metaValue)
                    .foregroundStyle(.primary.opacity(StatsPanelStyle.inactiveTextOpacity))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StatsPanelStyle.cardPadding)
        .padding(.vertical, 11)
        .statsBackground(cornerRadius: 10)
    }

    private func comparisonChangeBadge(change: Double) -> some View {
        HStack(spacing: 3) {
            if abs(change) > 0.5 {
                Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))

                Text(String(format: "%.0f%%", abs(change)))
                    .monospacedDigit()
            } else {
                Text("Flat")
            }
        }
        .font(StatsPanelStyle.secondaryLabel)
        .lineLimit(1)
        .foregroundStyle(change > 0 ? .green : (abs(change) > 0.5 ? .red : .secondary))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            (change > 0 ? Color.green : (abs(change) > 0.5 ? Color.red : Color.secondary)).opacity(0.1),
            in: Capsule()
        )
    }
}
