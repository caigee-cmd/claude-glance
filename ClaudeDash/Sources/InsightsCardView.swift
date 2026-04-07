// InsightsCardView.swift
// ClaudeDash - 智能洞察卡片 + 效率指标

import SwiftUI

// MARK: - 单个洞察卡片

struct InsightCard: View {
    let insight: StatsManager.Insight
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: insight.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(insightColor)
                .frame(width: 32, height: 32)
                .background(insightColor.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(insight.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(10)
        .statsBackground(cornerRadius: 12)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .brightness(isHovered ? 0.04 : 0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var insightColor: Color {
        switch insight.colorName {
        case "purple": return .claudePurple
        case "cyan": return .claudeCyan
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        default: return .secondary
        }
    }
}

// MARK: - 洞察列表

struct InsightsListView: View {
    let insights: [StatsManager.Insight]

    var body: some View {
        if insights.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
                Text("Complete some sessions this week to see insights")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ], spacing: 8) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}

// MARK: - 效率指标卡片组

struct EfficiencyMetricsView: View {
    let tokensPerMinute: Double
    let tokensPerDollar: Double
    let avgMessagesPerSession: Double
    let avgToolUsesPerSession: Double
    let cacheHitRate: Double
    let streak: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            efficiencyCard(
                icon: "bolt.fill",
                label: "Tokens/min",
                value: tokensPerMinute > 1000 ? "\(Int(tokensPerMinute / 1000))K" : "\(Int(tokensPerMinute))",
                color: .claudeCyan
            )
            efficiencyCard(
                icon: "dollarsign.arrow.circlepath",
                label: "Tokens/$",
                value: tokensPerDollar > 1000 ? "\(Int(tokensPerDollar / 1000))K" : "\(Int(tokensPerDollar))",
                color: .orange
            )
            efficiencyCard(
                icon: "bubble.left.and.bubble.right",
                label: "Msgs/Session",
                value: String(format: "%.1f", avgMessagesPerSession),
                color: .blue
            )
            efficiencyCard(
                icon: "wrench.and.screwdriver",
                label: "Tools/Session",
                value: String(format: "%.1f", avgToolUsesPerSession),
                color: .claudePurple
            )
            efficiencyCard(
                icon: "memorychip",
                label: "Cache Hit",
                value: String(format: "%.0f%%", cacheHitRate * 100),
                color: .mint
            )
            efficiencyCard(
                icon: "flame.fill",
                label: "Streak",
                value: "\(streak)d",
                color: .orange
            )
        }
    }

    private func efficiencyCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .statsCard(cornerRadius: 14)
    }
}

// MARK: - 导出按钮

struct ExportButtonsView: View {
    let onExportCSV: () -> Void
    let onExportJSON: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            exportButton(icon: "tablecells", label: "Export CSV", action: onExportCSV)
            exportButton(icon: "curlybraces", label: "Export JSON", action: onExportJSON)
        }
    }

    private func exportButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .statsBackground(cornerRadius: 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary.opacity(0.65))
    }
}
