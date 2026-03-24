// Models.swift
// ClaudeDash - 共享数据模型定义
// 所有 target 共用的数据结构

import Foundation

// MARK: - Session 记录（Helper 写入，主 App 读取）

/// 单次 Claude Code 任务完成的记录
struct SessionRecord: Codable, Identifiable, Sendable {
    let id: UUID
    /// 项目名称（从 cwd 提取）
    let project: String
    /// 工作目录完整路径
    let cwd: String
    /// 总耗时（毫秒）
    let durationMs: Int
    /// 费用（USD）
    let cost: Double
    /// 最后 assistant 消息摘要
    let summary: String
    /// transcript 文件路径
    let transcriptPath: String
    /// 完成时间戳
    let completedAt: Date

    init(project: String, cwd: String, durationMs: Int, cost: Double, summary: String, transcriptPath: String) {
        self.id = UUID()
        self.project = project
        self.cwd = cwd
        self.durationMs = durationMs
        self.cost = cost
        self.summary = summary
        self.transcriptPath = transcriptPath
        self.completedAt = Date()
    }
}

// MARK: - 每日统计汇总

/// 单日统计数据
struct DailySummary: Codable, Identifiable, Sendable {
    var id: String { dateString }
    /// 日期字符串 yyyy-MM-dd
    let dateString: String
    /// 当日完成次数
    var completionCount: Int
    /// 当日总成本 USD
    var totalCost: Double
    /// 当日总耗时（秒）
    var totalDurationSeconds: Double
    /// 当日 input tokens 总量
    var totalInputTokens: Int
    /// 当日 output tokens 总量
    var totalOutputTokens: Int
    /// 每小时完成次数分布（0-23）
    var hourlyDistribution: [Int]
    /// Cache read tokens（命中缓存，更便宜）
    var totalCacheReadTokens: Int
    /// Cache creation tokens（首次缓存创建）
    var totalCacheCreationTokens: Int
    /// 当日工具调用总次数
    var totalToolUseCount: Int
    /// 当日消息总数（user + assistant）
    var totalMessageCount: Int
    /// 工具调用分布 (tool name → count)
    var toolDistribution: [String: Int]

    /// 总 token 数
    var totalTokens: Int { totalInputTokens + totalOutputTokens }

    init(dateString: String) {
        self.dateString = dateString
        self.completionCount = 0
        self.totalCost = 0
        self.totalDurationSeconds = 0
        self.totalInputTokens = 0
        self.totalOutputTokens = 0
        self.hourlyDistribution = Array(repeating: 0, count: 24)
        self.totalCacheReadTokens = 0
        self.totalCacheCreationTokens = 0
        self.totalToolUseCount = 0
        self.totalMessageCount = 0
        self.toolDistribution = [:]
    }
}

extension DailySummary {
    var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        if Calendar.current.isDateInToday(date) { return "今天" }
        if Calendar.current.isDateInYesterday(date) { return "昨天" }

        let display = DateFormatter()
        display.dateFormat = "M/d"
        return display.string(from: date)
    }
}

// MARK: - Stop Hook JSON（Claude Code 传入的数据结构）

/// Claude Code Stop Hook 通过 stdin 传入的 JSON 结构
struct StopHookInput: Codable {
    /// 最后 assistant 消息内容
    let last_assistant_message: String?
    /// 工作目录
    let cwd: String?
    /// 总耗时毫秒
    let total_duration_ms: Int?
    /// 费用 USD
    let cost: Double?
    /// transcript 文件路径
    let transcript_path: String?
}

// MARK: - App 设置

/// 通知声音选项
enum NotificationSound: String, Codable, CaseIterable {
    case glass = "Glass"
    case ping = "Ping"
    case blow = "Blow"
    case submarine = "Submarine"
    case none = "None"

    /// 系统声音文件名
    var soundFileName: String? {
        switch self {
        case .none: return nil
        default: return rawValue
        }
    }
}

// MARK: - Transcript 解析相关

/// Session 当前状态
enum SessionStatus: String, Codable, Sendable {
    case thinking = "思考中"
    case toolRunning = "工具执行中"
    case completed = "已完成"
    case unknown = "未知"
}

/// 工具类型及对应 SF Symbol
enum ToolType: String, Sendable {
    case edit = "Edit"
    case read = "Read"
    case write = "Write"
    case grep = "Grep"
    case glob = "Glob"
    case bash = "Bash"
    case unknown = "Unknown"

    /// 对应的 SF Symbol 名称
    var sfSymbol: String {
        switch self {
        case .edit: return "pencil"
        case .read: return "doc.text"
        case .write: return "doc.badge.plus"
        case .grep: return "magnifyingglass"
        case .glob: return "folder.badge.magnifyingglass"
        case .bash: return "terminal"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Transcript 中的单条消息
struct TranscriptMessage: Identifiable, Sendable {
    let id = UUID()
    let role: String
    let content: String
    let toolName: String?
    let timestamp: Date

    init(role: String, content: String, toolName: String? = nil) {
        self.role = role
        self.content = content
        self.toolName = toolName
        self.timestamp = Date()
    }
}

/// 活跃 Session 信息（用于监控 Tab 显示）
struct ActiveSession: Identifiable {
    let id: String
    let project: String
    let transcriptPath: String
    var status: SessionStatus
    var lastMessages: [TranscriptMessage]
    var currentTool: ToolType
    var tokenUsage: Double  // 0.0 - 1.0 比例
    var startTime: Date

    init(project: String, transcriptPath: String) {
        self.id = transcriptPath
        self.project = project
        self.transcriptPath = transcriptPath
        self.status = .unknown
        self.lastMessages = []
        self.currentTool = .unknown
        self.tokenUsage = 0.0
        self.startTime = Date()
    }
}

// MARK: - 项目统计汇总

/// 按项目聚合的统计数据
struct ProjectStat: Identifiable, Sendable {
    let id: String
    let project: String
    var sessionCount: Int
    var totalCost: Double
    var totalDurationSeconds: Double
    var totalInputTokens: Int
    var totalOutputTokens: Int
    var totalToolUseCount: Int
    var totalMessageCount: Int
    var totalCacheReadTokens: Int
    var totalCacheCreationTokens: Int

    var averageCost: Double { sessionCount > 0 ? totalCost / Double(sessionCount) : 0 }
    var averageDuration: Double { sessionCount > 0 ? totalDurationSeconds / Double(sessionCount) : 0 }
    var averageToolUses: Double { sessionCount > 0 ? Double(totalToolUseCount) / Double(sessionCount) : 0 }
    /// token 数格式化（如 "1.2M"）
    var tokensFormatted: String { totalInputTokens.tokenFormatted }
}

// MARK: - 周统计汇总

struct WeekSummary: Sendable {
    let sessions: Int
    let cost: Double
    let tokens: Int
    let duration: Double
    let activeDays: Int
    let toolUses: Int
    let messages: Int
}

// MARK: - 时长分布桶

struct DurationBucket: Identifiable, Sendable {
    var id: String { label }
    let label: String
    let range: String
    let count: Int
}

// MARK: - 辅助扩展

extension Int {
    /// 毫秒转人类可读耗时字符串
    var humanReadableDuration: String {
        let totalSeconds = self / 1000
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes < 60 {
            return "\(minutes)m \(seconds)s"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

extension Int {
    /// Token 数格式化（如 "1.2M", "456K"）
    var tokenFormatted: String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", Double(self) / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.0fK", Double(self) / 1_000)
        }
        return "\(self)"
    }
}

extension Double {
    /// USD 格式化
    var usdFormatted: String {
        if self >= 1.0 {
            return String(format: "$%.2f", self)
        }
        return String(format: "$%.4f", self)
    }

    /// 秒数转人类可读耗时
    var durationFormatted: String {
        Int(self * 1000).humanReadableDuration
    }
}
