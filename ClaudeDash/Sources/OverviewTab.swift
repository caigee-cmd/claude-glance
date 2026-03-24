// OverviewTab.swift
// ClaudeDash - 概览 Tab
// 今日完成次数/总成本/总耗时卡片 + Swift Charts 每小时柱状图

import SwiftUI
import Charts

struct OverviewTab: View {
    @EnvironmentObject var statsManager: StatsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("今日概览")
                        .font(.title2.bold())
                    Spacer()
                    Text(todayDateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // 统计卡片行
                HStack(spacing: 16) {
                    StatCard(
                        title: "完成次数",
                        value: "\(statsManager.todayCompletionCount)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "总成本",
                        value: statsManager.todayCost.usdFormatted,
                        icon: "dollarsign.circle.fill",
                        color: .orange
                    )

                    StatCard(
                        title: "总耗时",
                        value: statsManager.todayDurationSeconds.durationFormatted,
                        icon: "clock.fill",
                        color: .blue
                    )
                }
                .padding(.horizontal)

                // 每小时柱状图
                VStack(alignment: .leading, spacing: 8) {
                    Text("每小时分布")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart {
                        ForEach(Array(statsManager.todayHourlyDistribution.enumerated()), id: \.offset) { hour, count in
                            BarMark(
                                x: .value("小时", "\(hour)时"),
                                y: .value("次数", count)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(4)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 1)) { value in
                            if let hour = value.as(String.self) {
                                let h = Int(hour.replacingOccurrences(of: "时", with: "")) ?? 0
                                // 每 3 小时显示一个标签
                                if h % 3 == 0 {
                                    AxisValueLabel { Text(hour).font(.caption2) }
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
        }
    }

    /// 今日日期格式化
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
}

// MARK: - 统计卡片组件

/// 单个统计数据卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            HStack {
                Text(value)
                    .font(.title.bold().monospacedDigit())
                Spacer()
            }

            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OverviewTab()
        .environmentObject(StatsManager.shared)
        .frame(width: 700, height: 500)
}
