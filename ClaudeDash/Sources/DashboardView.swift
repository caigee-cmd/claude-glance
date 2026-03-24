// DashboardView.swift
// ClaudeDash - 仪表盘主视图
// TabView 容器，毛玻璃背景，包含概览/设置/实时监控三个 Tab

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var sessionMonitor: SessionMonitor

    /// 当前选中的 Tab
    @State private var selectedTab: DashboardTab = .overview

    var body: some View {
        TabView(selection: $selectedTab) {
            // 概览 Tab
            OverviewTab()
                .tabItem {
                    Label("概览", systemImage: "chart.bar.fill")
                }
                .tag(DashboardTab.overview)

            // 设置 Tab
            SettingsTab()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(DashboardTab.settings)

            // 实时监控 Tab
            MonitorTab()
                .tabItem {
                    Label("监控", systemImage: "waveform.badge.magnifyingglass")
                }
                .tag(DashboardTab.monitor)
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(.ultraThinMaterial)
    }
}

/// 仪表盘 Tab 枚举
enum DashboardTab: Hashable {
    case overview
    case settings
    case monitor
}

#Preview {
    DashboardView()
        .environmentObject(StatsManager.shared)
        .environmentObject(SessionMonitor.shared)
}
