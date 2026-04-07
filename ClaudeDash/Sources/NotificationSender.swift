// NotificationSender.swift
// ClaudeDash - 通知发送器
// 封装 UNUserNotificationCenter，处理权限请求、模板展开、声音选择

import Foundation
import UserNotifications

@MainActor
final class NotificationSender: ObservableObject {
    // MARK: - 单例

    static let shared = NotificationSender()

    // MARK: - 属性

    /// 通知中心引用
    private let center = UNUserNotificationCenter.current()

    // MARK: - 权限请求

    /// 请求通知权限（alert + sound + badge）
    func requestPermission() {
        // center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        //     if let error = error {
        //         print("[NotificationSender] 权限请求失败: \(error)")
        //     }
        //     print("[NotificationSender] 通知权限: \(granted ? "已授权" : "被拒绝")")
        // }
    }

    // MARK: - 模板变量展开

    /// 展开通知模板中的变量占位符
    /// 支持: {project}, {duration}, {cost}, {summary}
    static func expandTemplate(
        _ template: String,
        project: String,
        durationMs: Int,
        cost: Double,
        summary: String
    ) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{project}", with: project)
        result = result.replacingOccurrences(of: "{duration}", with: durationMs.humanReadableDuration)
        result = result.replacingOccurrences(of: "{cost}", with: cost.usdFormatted)
        result = result.replacingOccurrences(of: "{summary}", with: summary)
        return result
    }

    // MARK: - 发送通知

    /// 发送任务完成通知
    /// - Parameters:
    ///   - project: 项目名
    ///   - durationMs: 耗时毫秒
    ///   - cost: 费用 USD
    ///   - summary: 任务摘要
    ///   - cwd: 工作目录（通知点击后打开）
    func sendCompletionNotification(
        project: String,
        durationMs: Int,
        cost: Double,
        summary: String,
        cwd: String
    ) {
        // 通知功能已禁用
        // let defaults = ClaudeDashDefaults.shared
        // let template = defaults.string(forKey: "ClaudeDash_notificationTemplate")
        //     ?? "{project} 已完成 - 耗时 {duration}，费用 {cost}"
        // let soundName = defaults.string(forKey: "ClaudeDash_notificationSound") ?? "Glass"
        // let body = Self.expandTemplate(template, project: project, durationMs: durationMs, cost: cost, summary: summary)
        // let content = UNMutableNotificationContent()
        // content.title = ClaudeDashCopy.notificationTitle
        // content.body = body
        // content.userInfo = ["cwd": cwd]
        // if let sound = NotificationSound(rawValue: soundName), sound != .none,
        //    let fileName = sound.soundFileName {
        //     content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
        // }
        // let enableSummary = defaults.bool(forKey: "ClaudeDash_enableSummary")
        // if enableSummary && !summary.isEmpty {
        //     content.subtitle = String(summary.prefix(100))
        // }
        // let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        // center.add(request) { error in
        //     if let error = error { print("[NotificationSender] 发送通知失败: \(error)") }
        // }
    }

    // MARK: - 测试通知

    /// 发送一条测试通知，同时写入一条模拟 session 数据到统计
    func sendTestNotification() {
        // 通知功能已禁用
        // let testProjects = ["my-app", "web-ui", "api-server", "cli-tool", "docs-site"]
        // let project = testProjects.randomElement()!
        // let durationMs = Int.random(in: 15000...180000)
        // let cost = Double.random(in: 0.005...0.15)
        // let summary = "完成了一些代码修改和测试工作。"
        // sendCompletionNotification(project: project, durationMs: durationMs, cost: cost, summary: summary, cwd: "/Users/test/\(project)")
        // let record = SessionRecord(project: project, cwd: "/Users/test/\(project)", durationMs: durationMs, cost: cost, summary: summary, transcriptPath: "")
        // StatsManager.shared.addSession(record)
        // writeTestSessionToFile(record)
    }

    /// 将测试 session 写入 sessions.json 文件
    private func writeTestSessionToFile(_ record: SessionRecord) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClaudeDash")
        let filePath = dir.appendingPathComponent("sessions.json")

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var sessions: [SessionRecord] = []
        if let data = try? Data(contentsOf: filePath) {
            sessions = (try? JSONDecoder().decode([SessionRecord].self, from: data)) ?? []
        }
        sessions.append(record)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(sessions) {
            try? data.write(to: filePath, options: .atomic)
        }
    }
}
