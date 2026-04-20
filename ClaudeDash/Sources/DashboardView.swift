// DashboardView.swift
// ClaudeDash - 仪表盘主视图
// TabView 容器，毛玻璃背景，包含概览/实时监控两个 Tab

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var sessionMonitor: SessionMonitor

    /// 当前选中的 Tab
    @State private var selectedTab: DashboardTab = .overview

    var body: some View {
        VStack(spacing: 0) {
            // 顶部来源切换器
            HStack {
                Spacer()
                Picker("数据来源", selection: $statsManager.selectedSource) {
                    ForEach(StatsDataSource.allCases) { source in
                        Label(source.title, systemImage: source.iconName)
                            .tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            TabView(selection: $selectedTab) {
                // 概览 Tab
                OverviewTab()
                    .tabItem {
                        Label("概览", systemImage: "chart.bar.fill")
                    }
                    .tag(DashboardTab.overview)

                // 实时监控 Tab
                MonitorTab()
                    .tabItem {
                        Label("监控", systemImage: ClaudeDashSymbols.monitorTab)
                    }
                    .tag(DashboardTab.monitor)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(.ultraThinMaterial)
    }
}

/// 仪表盘 Tab 枚举
enum DashboardTab: Hashable {
    case overview
    case monitor
}

#Preview {
    DashboardView()
        .environmentObject(StatsManager.shared)
        .environmentObject(SessionMonitor.shared)
}
