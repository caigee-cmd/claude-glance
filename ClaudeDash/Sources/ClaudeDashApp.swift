// ClaudeDashApp.swift
// ClaudeDash - 应用入口
// 配置为 accessory 模式（不显示 Dock 图标），仅在状态栏显示

import SwiftUI

@main
struct ClaudeDashApp: App {
    // 使用 NSApplicationDelegateAdaptor 处理 AppKit 集成
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 使用 Settings scene 作为占位，实际窗口由 StatusBarController 管理
        Settings {
            EmptyView()
        }
    }
}

// MARK: - AppDelegate

/// AppDelegate 负责初始化状态栏控制器和核心服务
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 状态栏控制器（持有 NSStatusItem）
    private var statusBarController: StatusBarController?
    /// 统计管理器（全局单例）
    let statsManager = StatsManager.shared
    /// Session 监控器
    let sessionMonitor = SessionMonitor.shared
    /// 通知发送器
    let notificationSender = NotificationSender.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置 App 为 accessory 模式：不在 Dock 显示图标，不激活主窗口
        NSApp.setActivationPolicy(.accessory)

        // 请求通知权限
        notificationSender.requestPermission()

        // 初始化状态栏控制器
        statusBarController = StatusBarController(
            statsManager: statsManager,
            sessionMonitor: sessionMonitor,
            notificationSender: notificationSender
        )

        // 启动 JSONL 目录扫描
        sessionMonitor.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 清理所有 DispatchSource 资源
        sessionMonitor.stopAllMonitoring()
    }
}
