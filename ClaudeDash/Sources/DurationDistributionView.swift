// DurationDistributionView.swift
// ClaudeDash - Session 时长分布直方图

import SwiftUI
import Charts

struct DurationDistributionView: View {
    let buckets: [DurationBucket]
    var height: CGFloat = 140

    private var maxCount: Int {
        max(buckets.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("Duration", bucket.label),
                y: .value("Count", bucket.count)
            )
            .foregroundStyle(barColor(bucket))
            .cornerRadius(4)
            .annotation(position: .top, spacing: 2) {
                if bucket.count > 0 {
                    Text("\(bucket.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.65))
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(.primary.opacity(0.65))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    .foregroundStyle(.tertiary)
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: height)
    }

    private func barColor(_ bucket: DurationBucket) -> LinearGradient {
        let ratio = maxCount > 0 ? Double(bucket.count) / Double(maxCount) : 0
        let startOpacity = 0.4 + ratio * 0.4
        return LinearGradient(
            colors: [.claudePurple.opacity(startOpacity), .claudeCyan.opacity(startOpacity * 0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
