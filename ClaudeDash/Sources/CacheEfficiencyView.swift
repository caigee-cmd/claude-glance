// CacheEfficiencyView.swift
// ClaudeDash - Cache 效率可视化 + 成本细分

import SwiftUI
import Charts

// MARK: - Cache 效率仪表

struct CacheEfficiencyView: View {
    let hitRate: Double      // 0-1
    let savings: Double      // USD saved
    let cacheReadTokens: Int
    let cacheCreateTokens: Int
    let pureInputTokens: Int
    let outputTokens: Int

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                // Cache 命中率环
                cacheRing
                    .frame(width: 80, height: 80)

                // 指标卡片
                VStack(alignment: .leading, spacing: 8) {
                    cacheMetric(
                        label: "Hit Rate",
                        value: String(format: "%.0f%%", hitRate * 100),
                        color: hitRate > 0.5 ? .green : .orange
                    )
                    cacheMetric(
                        label: "Saved",
                        value: savings.usdFormatted,
                        color: .claudeCyan
                    )
                    cacheMetric(
                        label: "Cache Read",
                        value: cacheReadTokens.tokenFormatted,
                        color: .mint
                    )
                }
            }

            // Token 分类条
            tokenBreakdownBar
        }
    }

    private var cacheRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 8)

            Circle()
                .trim(from: 0, to: min(hitRate, 1.0))
                .stroke(
                    LinearGradient(
                        colors: [.green, .claudeCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text(String(format: "%.0f", hitRate * 100))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.65))
            }
        }
    }

    private func cacheMetric(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.primary.opacity(0.65))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
        }
    }

    // MARK: - Token 分类横条

    private var tokenBreakdownBar: some View {
        let total = max(cacheReadTokens + cacheCreateTokens + pureInputTokens + outputTokens, 1)
        let segments: [(label: String, count: Int, color: Color)] = [
            ("Cache Read", cacheReadTokens, .mint),
            ("Cache Create", cacheCreateTokens, .claudeWarningOrange),
            ("Input", pureInputTokens, .claudeCyan),
            ("Output", outputTokens, .claudePurple),
        ]

        return VStack(spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(segments.indices, id: \.self) { i in
                        let seg = segments[i]
                        let width = max(1, geo.size.width * CGFloat(seg.count) / CGFloat(total))
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(seg.color.opacity(0.8))
                            .frame(width: width)
                    }
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())

            // 图例
            HStack(spacing: 10) {
                ForEach(segments.indices, id: \.self) { i in
                    let seg = segments[i]
                    if seg.count > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(seg.color.opacity(0.8)).frame(width: 5, height: 5)
                            Text(seg.label)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(seg.count.tokenFormatted)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary.opacity(0.65))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 成本细分瀑布图

struct CostBreakdownView: View {
    let inputCost: Double
    let outputCost: Double
    let cacheReadCost: Double
    let cacheCreateCost: Double
    var height: CGFloat = 140

    private var segments: [(label: String, cost: Double, color: Color)] {
        [
            ("Input", inputCost, .claudeCyan),
            ("Output", outputCost, .claudePurple),
            ("Cache Read", cacheReadCost, .mint),
            ("Cache Create", cacheCreateCost, .claudeWarningOrange),
        ].filter { $0.cost > 0.0001 }
    }

    private var totalCost: Double {
        inputCost + outputCost + cacheReadCost + cacheCreateCost
    }

    var body: some View {
        VStack(spacing: 10) {
            Chart(segments.indices, id: \.self) { i in
                let seg = segments[i]
                BarMark(
                    x: .value("Cost", seg.cost),
                    y: .value("Type", seg.label)
                )
                .foregroundStyle(seg.color.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing, spacing: 4) {
                    Text(seg.cost.usdFormatted)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary.opacity(0.65))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 12))
                        .foregroundStyle(.primary.opacity(0.65))
                }
            }
            .frame(height: height)

            // 总计
            HStack {
                Spacer()
                Text("Total: \(totalCost.usdFormatted)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
    }
}
