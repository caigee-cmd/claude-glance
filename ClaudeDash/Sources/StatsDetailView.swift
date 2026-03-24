// StatsDetailView.swift
// ClaudeDash - 详细统计窗口
// Liquid Glass 设计：5 Tab — Overview / Tokens / Tools / Projects / Insights

import SwiftUI
import Charts

struct StatsDetailView: View {
    @EnvironmentObject var statsManager: StatsManager
    @State private var selectedTab: StatsTab = .overview

    enum StatsTab: String, CaseIterable {
        case overview = "Overview"
        case tokens = "Tokens"
        case tools = "Tools"
        case projects = "Projects"
        case insights = "Insights"
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

            tabBar
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            if statsManager.scanComplete {
                ScrollView(.vertical, showsIndicators: false) {
                    switch selectedTab {
                    case .overview: overviewContent
                    case .tokens: tokensContent
                    case .tools: toolsContent
                    case .projects: projectsContent
                    case .insights: insightsContent
                    }
                }
            } else {
                statsLoadingState
            }
        }
        .frame(minWidth: 740, minHeight: 660)
        .background(statsWindowBackground)
    }

    // MARK: - 顶部栏

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ClaudeGradients.primary)

                Text("Statistics")
                    .font(.system(size: 20, weight: .bold))

                if statsManager.usageStreak > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text("\(statsManager.usageStreak)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .statsBackground(cornerRadius: 8)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                miniStat(icon: "sum", value: "\(statsManager.totalCompletionsAllTime)")
                miniStat(icon: "creditcard", value: statsManager.totalCostAllTime.usdFormatted)
                miniStat(icon: "textformat.123", value: statsManager.totalTokensAllTime.tokenFormatted)
            }

            Spacer()

        }
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(StatsTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundStyle(selectedTab == tab ? Color.primary : Color.primary.opacity(0.55))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .statsBackground(cornerRadius: 14)
    }

    private func miniStat(icon: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(.primary.opacity(0.6))
    }

    private var statsWindowBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.11, green: 0.12, blue: 0.16),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.claudePurple.opacity(0.08),
                            Color.claudeCyan.opacity(0.04),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Overview Tab

    private var overviewContent: some View {
        LazyVStack(spacing: 16) {
            // Rings + 今日详情
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 10) {
                    ActivityRingsView(
                        sessionProgress: statsManager.sessionRingProgress,
                        weeklyProgress: statsManager.weeklyActivityProgress,
                        tokenProgress: statsManager.tokenRingProgress,
                        centerValue: statsManager.todayTotalTokens.tokenFormatted,
                        centerSubtitle: "tokens today",
                        size: 190
                    )

                    HStack(spacing: 16) {
                        ringLegendItem(color: .claudePurple, label: "Sessions", value: "\(statsManager.todayCompletionCount)")
                        ringLegendItem(color: .claudeCyan.opacity(0.7), label: "7-Day", value: "\(Int(statsManager.weeklyActivityProgress * 7))/7")
                        ringLegendItem(color: .claudeCyan, label: "Tokens", value: "\(Int(statsManager.tokenRingProgress * 100))%")
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .statsCard(cornerRadius: 20)

                VStack(spacing: 8) {
                    detailStatCard(title: "Sessions", value: "\(statsManager.todayCompletionCount)", trend: statsManager.completionTrend, icon: "checkmark.circle.fill", color: .green)
                    detailStatCard(title: "Cost", value: statsManager.todayCost.usdFormatted, trendValue: statsManager.costTrend, icon: "dollarsign.circle.fill", color: .orange)
                    detailStatCard(title: "Duration", value: statsManager.todayDurationSeconds.durationFormatted, trendDuration: statsManager.durationTrend, icon: "clock.fill", color: .blue)
                    detailStatCard(title: "Avg / Task", value: statsManager.averageDurationPerTask.durationFormatted, subtitle: statsManager.averageCostPerTask.usdFormatted + " avg cost", icon: "gauge.medium", color: .claudePurple)
                }
                .frame(width: 200)
            }
            .padding(.horizontal, 24)

            // 周对比
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Week over Week", trailing: "this week vs last")

                WeekComparisonView(
                    thisWeek: statsManager.thisWeekSummary,
                    lastWeek: statsManager.lastWeekSummary,
                    changePercent: statsManager.weekChangePercent,
                    changePercentDouble: statsManager.weekChangePercent
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 热力图
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Contribution Activity", trailing: "last 13 weeks")

                ContributionHeatmapView(
                    dailyCounts: statsManager.heatmapDailyCounts,
                    cellSize: 15,
                    cellSpacing: 3,
                    numWeeks: 13,
                    showDayLabels: true,
                    showMonthLabels: true
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 14 天趋势
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "14-Day Trend")

                UsageTrendChartView(
                    data: statsManager.last14Days,
                    height: 160,
                    showAxes: true,
                    showPeakAnnotation: true
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 今日小时分布
            hourlyHeatmapSection
                .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - Tokens & Cost Tab

    private var tokensContent: some View {
        LazyVStack(spacing: 16) {
            // Token 概览卡片
            HStack(spacing: 10) {
                tokenOverviewCard(title: "Input", value: statsManager.todayInputTokens.tokenFormatted, color: .claudeCyan, icon: "arrow.down.circle.fill")
                tokenOverviewCard(title: "Output", value: statsManager.todayOutputTokens.tokenFormatted, color: .claudePurple, icon: "arrow.up.circle.fill")
                tokenOverviewCard(title: "Total", value: statsManager.todayTotalTokens.tokenFormatted, color: .indigo, icon: "sum")
                tokenOverviewCard(title: "Cost", value: statsManager.todayCost.usdFormatted, color: .orange, icon: "dollarsign.circle.fill")
            }
            .padding(.horizontal, 24)

            // Cache 效率
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Cache Efficiency", trailing: "saved \(statsManager.cacheSavings.usdFormatted)")

                CacheEfficiencyView(
                    hitRate: statsManager.cacheHitRate,
                    savings: statsManager.cacheSavings,
                    cacheReadTokens: statsManager.todayCacheReadTokens,
                    cacheCreateTokens: statsManager.todayCacheCreationTokens,
                    pureInputTokens: statsManager.todayPureInputTokens,
                    outputTokens: statsManager.todayOutputTokens
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 成本细分
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Cost Breakdown — Today")

                CostBreakdownView(
                    inputCost: Double(statsManager.todayPureInputTokens) / 1_000_000 * 15.0,
                    outputCost: Double(statsManager.todayOutputTokens) / 1_000_000 * 75.0,
                    cacheReadCost: Double(statsManager.todayCacheReadTokens) / 1_000_000 * 1.5,
                    cacheCreateCost: Double(statsManager.todayCacheCreationTokens) / 1_000_000 * 18.75,
                    height: 100
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // Token 趋势图
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Token Usage — 14 Days")

                TokenTrendChartView(data: statsManager.last14Days, height: 180)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.claudeCyan.opacity(0.7)).frame(width: 6, height: 6)
                        Text("Input").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.claudePurple.opacity(0.7)).frame(width: 6, height: 6)
                        Text("Output").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 成本趋势图
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Cost Trend — 14 Days")

                CostTrendChartView(data: statsManager.last14Days, height: 160)
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - Tools Tab (NEW)

    private var toolsContent: some View {
        LazyVStack(spacing: 16) {
            // 工具分布
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Tool Distribution", trailing: "\(statsManager.totalToolUseCountAllTime) total calls")

                ToolDistributionView(
                    distribution: statsManager.toolDistributionSorted,
                    totalCount: statsManager.totalToolUseCountAllTime
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 模型使用分布
            if !statsManager.modelDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    GlassSectionHeader(title: "Model Usage")

                    VStack(spacing: 6) {
                        ForEach(statsManager.modelDistribution, id: \.model) { item in
                            modelRow(item)
                        }
                    }
                }
                .padding(16)
                .statsCard(cornerRadius: 20)
                .padding(.horizontal, 24)
            }

            // 工具调用趋势
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Tool Usage — 14 Days")

                ToolTrendChartView(data: statsManager.last14Days, height: 160)
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 对话深度
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Conversation Depth")

                HStack(spacing: 10) {
                    depthCard(icon: "bubble.left.and.bubble.right", label: "Avg Messages", value: String(format: "%.1f", statsManager.averageMessagesPerSession), color: .blue)
                    depthCard(icon: "wrench.and.screwdriver", label: "Avg Tool Calls", value: String(format: "%.1f", statsManager.averageToolUsesPerSession), color: .claudePurple)
                    depthCard(icon: "clock.arrow.circlepath", label: "Avg Duration", value: statsManager.averageDurationPerTask.durationFormatted, color: .green)
                    depthCard(icon: "dollarsign.circle", label: "Avg Cost", value: statsManager.averageCostPerTask.usdFormatted, color: .orange)
                }
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - Projects Tab

    private var projectsContent: some View {
        LazyVStack(spacing: 16) {
            if statsManager.projectStats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundStyle(.quaternary)
                    Text("暂无项目数据")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    GlassSectionHeader(title: "Project Ranking")

                    ForEach(Array(statsManager.projectStats.prefix(10).enumerated()), id: \.element.id) { index, stat in
                        projectRow(index: index, stat: stat)
                    }
                }
                .padding(16)
                .statsCard(cornerRadius: 20)
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - Insights Tab (NEW)

    private var insightsContent: some View {
        LazyVStack(spacing: 16) {
            // 效率指标面板
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Efficiency Metrics")

                EfficiencyMetricsView(
                    tokensPerMinute: statsManager.tokensPerMinute,
                    tokensPerDollar: statsManager.tokensPerDollar,
                    avgMessagesPerSession: statsManager.averageMessagesPerSession,
                    avgToolUsesPerSession: statsManager.averageToolUsesPerSession,
                    cacheHitRate: statsManager.cacheHitRate,
                    streak: statsManager.usageStreak
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 智能洞察
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Weekly Insights")

                InsightsListView(insights: statsManager.weeklyInsights)
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 7×24 全周热力图
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Weekly Activity Punch Card", trailing: "all-time")

                WeeklyPunchCardView(
                    heatmap: statsManager.weeklyHourlyHeatmap,
                    cellSize: 14,
                    cellSpacing: 2
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // Session 时长分布
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Session Duration Distribution")

                DurationDistributionView(
                    buckets: statsManager.durationBuckets,
                    height: 140
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 今日 Session 时间线
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Today's Timeline", trailing: "\(statsManager.todaySessions.count) sessions")

                SessionTimelineView(sessions: statsManager.todaySessions)
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            // 导出按钮
            VStack(alignment: .leading, spacing: 8) {
                GlassSectionHeader(title: "Data Export")

                ExportButtonsView(
                    onExportCSV: { exportData(format: "csv") },
                    onExportJSON: { exportData(format: "json") }
                )
            }
            .padding(16)
            .statsCard(cornerRadius: 20)
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - 子组件

    private func ringLegendItem(color: Color, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.4), radius: 2)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.primary.opacity(0.6))
        }
    }

    private func detailStatCard(
        title: String, value: String,
        trend: Int? = nil, trendValue: Double? = nil, trendDuration: Double? = nil,
        subtitle: String? = nil, icon: String, color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(subtitle ?? title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let t = trend, t != 0 {
                trendBadge(direction: t > 0 ? 1 : -1, text: "\(abs(t))")
            } else if let tv = trendValue, abs(tv) > 0.001 {
                trendBadge(direction: tv > 0 ? 1 : -1, text: abs(tv).usdFormatted)
            } else if let td = trendDuration, abs(td) > 0.5 {
                trendBadge(direction: td > 0 ? 1 : -1, text: abs(td).durationFormatted)
            }
        }
        .padding(10)
        .statsCard(cornerRadius: 14)
    }

    private func trendBadge(direction: Int, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: direction > 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(direction > 0 ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            (direction > 0 ? Color.green : Color.red).opacity(0.1),
            in: Capsule()
        )
    }

    private func tokenOverviewCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .statsCard(cornerRadius: 16)
    }

    private var statsLoadingState: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("正在构建统计快照")
                .font(.system(size: 15, weight: .semibold))
            Text("首次扫描可能需要几秒，之后会显著更快。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - 每小时热力图

    private var hourlyHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                GlassSectionHeader(title: "Hourly Distribution")
                Spacer()
                if let peak = statsManager.peakHour {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                        Text("Peak: \(peak):00")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .statsBackground(cornerRadius: 8)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 12),
                spacing: 4
            ) {
                ForEach(0..<24, id: \.self) { hour in
                    let count = statsManager.todayHourlyDistribution[hour]
                    let maxCount = max(statsManager.todayHourlyDistribution.max() ?? 1, 1)

                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(hourlyColor(count: count, max: maxCount))
                            .frame(height: 32)
                            .overlay {
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                            }

                        Text("\(hour)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .statsCard(cornerRadius: 20)
    }

    private func hourlyColor(count: Int, max: Int) -> Color {
        if count == 0 { return .white.opacity(0.04) }
        let intensity = Double(count) / Double(max)
        if intensity < 0.33 { return .claudePurple.opacity(0.35) }
        if intensity < 0.66 { return .claudePurple.opacity(0.6) }
        return .claudeCyan.opacity(0.8)
    }

    // MARK: - 模型行

    private func modelRow(_ item: (model: String, count: Int)) -> some View {
        let totalSessions = statsManager.totalScannedSessionCount
        let pct = totalSessions > 0 ? Double(item.count) / Double(totalSessions) : 0

        return HStack(spacing: 10) {
            Image(systemName: "cpu")
                .font(.system(size: 10))
                .foregroundStyle(Color.claudePurple)
                .frame(width: 14)

            Text(item.model)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)

            Spacer()

            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.04))
                    Capsule()
                        .fill(LinearGradient(colors: [.claudePurple.opacity(0.5), .claudeCyan.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * pct))
                }
            }
            .frame(width: 80, height: 4)

            Text("\(item.count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 35, alignment: .trailing)

            Text(String(format: "%.0f%%", pct * 100))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .statsBackground(cornerRadius: 8)
    }

    // MARK: - 深度卡片

    private func depthCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .statsCard(cornerRadius: 14)
    }

    // MARK: - 项目行

    private func projectRow(index: Int, stat: ProjectStat) -> some View {
        let maxSessions = statsManager.maxProjectSessionCount
        let barWidth = Double(stat.sessionCount) / Double(max(maxSessions, 1))

        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(rankColor(index).opacity(0.15))
                    .frame(width: 22, height: 22)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor(index))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stat.project)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.04))
                        Capsule()
                            .fill(LinearGradient(colors: [.claudePurple.opacity(0.6), .claudeCyan.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(4, geo.size.width * barWidth))
                    }
                }
                .frame(height: 3)
            }

            Spacer()

            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                    Text("\(stat.sessionCount)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.primary.opacity(0.65))

                Text(stat.totalCost.usdFormatted)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.orange)
                    .frame(width: 60, alignment: .trailing)

                Text(stat.tokensFormatted)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.claudeCyan)
                    .frame(width: 50, alignment: .trailing)

                Text(stat.totalDurationSeconds.durationFormatted)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.blue)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            index == 0 ? AnyShapeStyle(.orange.opacity(0.05)) : AnyShapeStyle(.clear),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .statsBackground(cornerRadius: 10)
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .orange
        case 1: return .gray
        case 2: return Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255)
        default: return .secondary
        }
    }

    // MARK: - 导出

    private func exportData(format: String) {
        let content: String
        let ext: String
        if format == "csv" {
            content = statsManager.exportCSV()
            ext = "csv"
        } else {
            content = statsManager.exportJSON()
            ext = "json"
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "claudedash_stats.\(ext)"
        panel.allowedContentTypes = ext == "csv" ? [.commaSeparatedText] : [.json]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - DetailStatCard (保留兼容)

struct DetailStatCard: View {
    let title: String
    let value: String
    var trend: Int? = nil
    var trendValue: Double? = nil
    var trendDuration: Double? = nil
    var trendLabel: String? = nil
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(subtitle ?? title)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .statsCard(cornerRadius: 14)
    }
}

#Preview {
    StatsDetailView()
        .environmentObject(StatsManager.shared)
        .frame(width: 740, height: 680)
}
