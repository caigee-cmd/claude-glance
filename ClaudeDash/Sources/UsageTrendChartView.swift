// UsageTrendChartView.swift
// ClaudeDash - 14 天使用趋势面积图
// Swift Charts Area + 渐变填充 + 峰值高亮

import SwiftUI
import Charts

struct UsageTrendChartView: View {
    let data: [DailySummary]
    var height: CGFloat = 80
    var showAxes: Bool = false
    var showPeakAnnotation: Bool = false

    @State private var isHovered = false

    private var peakDay: DailySummary? {
        data.max(by: { $0.completionCount < $1.completionCount })
    }

    var body: some View {
        Chart(data) { day in
            // 面积填充
            AreaMark(
                x: .value("日", day.shortDateLabel),
                y: .value("次", day.completionCount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .claudePurple.opacity(0.3),
                        .claudeCyan.opacity(0.08),
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // 折线
            LineMark(
                x: .value("日", day.shortDateLabel),
                y: .value("次", day.completionCount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.claudePurple, .claudeCyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            // 数据点
            if showAxes {
                PointMark(
                    x: .value("日", day.shortDateLabel),
                    y: .value("次", day.completionCount)
                )
                .foregroundStyle(Color.claudeCyan)
                .symbolSize(day.dateString == peakDay?.dateString ? 40 : 20)
            }

            // 峰值标注
            if showPeakAnnotation,
               day.dateString == peakDay?.dateString,
               day.completionCount > 0 {
                PointMark(
                    x: .value("日", day.shortDateLabel),
                    y: .value("次", day.completionCount)
                )
                .foregroundStyle(Color.claudeCyan)
                .symbolSize(50)
                .annotation(position: .top, spacing: 4) {
                    Text("\(day.completionCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.claudeCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .chartXAxis(showAxes ? .automatic : .hidden)
        .chartYAxis(showAxes ? .automatic : .hidden)
        .chartXAxis {
            if showAxes {
                AxisMarks(values: .automatic(desiredCount: 7)) { value in
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .chartYAxis {
            if showAxes {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - 成本趋势图

struct CostTrendChartView: View {
    let data: [DailySummary]
    var height: CGFloat = 140

    var body: some View {
        Chart(data) { day in
            BarMark(
                x: .value("日期", day.shortDateLabel),
                y: .value("成本", day.totalCost)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.claudePurple.opacity(0.8), .claudeCyan.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    .foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("$\(v, specifier: "%.2f")")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Token 趋势图

struct TokenTrendChartView: View {
    let data: [DailySummary]
    var height: CGFloat = 140

    var body: some View {
        Chart(data) { day in
            BarMark(
                x: .value("日期", day.shortDateLabel),
                y: .value("Input", Double(day.totalInputTokens) / 1_000_000)
            )
            .foregroundStyle(Color.claudeCyan.opacity(0.7))
            .cornerRadius(3)
            .position(by: .value("Type", "Input"))

            BarMark(
                x: .value("日期", day.shortDateLabel),
                y: .value("Output", Double(day.totalOutputTokens) / 1_000_000)
            )
            .foregroundStyle(Color.claudePurple.opacity(0.7))
            .cornerRadius(3)
            .position(by: .value("Type", "Output"))
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    .foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(v, specifier: "%.1f")M")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .chartForegroundStyleScale([
            "Input": Color.claudeCyan.opacity(0.7),
            "Output": Color.claudePurple.opacity(0.7),
        ])
        .frame(height: height)
    }
}

#Preview {
    UsageTrendChartView(
        data: [],
        height: 120,
        showAxes: true,
        showPeakAnnotation: true
    )
    .padding()
    .frame(width: 400, height: 200)
    .background(.black.opacity(0.9))
}
