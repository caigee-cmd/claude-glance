// HistoryScanner.swift
// ClaudeDash - Claude Code 历史 JSONL 扫描器
// 扫描 ~/.claude/projects/ 下的所有 JSONL 文件，提取 session 统计数据

import Foundation

// MARK: - 扫描结果模型

/// 从 JSONL 解析出的单个 session 统计
struct ScannedSession: Identifiable, Codable, Sendable {
    var id: String { sessionId }
    let sessionId: String
    let projectDir: String
    let projectName: String
    let startTime: Date
    let endTime: Date
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreationTokens: Int
    let messageCount: Int
    let toolUseCount: Int
    let model: String
    let filePath: String
    /// 工具调用分布 (tool name → 调用次数)
    let toolDistribution: [String: Int]

    /// 总 token 数（输入 + 输出）
    var totalTokens: Int { inputTokens + outputTokens + cacheReadTokens + cacheCreationTokens }

    /// 估算成本 USD（基于公开的 API 定价估算）
    var estimatedCost: Double {
        // 粗略估算，使用 Claude Opus 4 定价参考
        // input: $15/M tokens, output: $75/M tokens, cache read: $1.5/M, cache creation: $18.75/M
        let inputCost = Double(inputTokens) / 1_000_000 * 15.0
        let outputCost = Double(outputTokens) / 1_000_000 * 75.0
        let cacheReadCost = Double(cacheReadTokens) / 1_000_000 * 1.5
        let cacheCreationCost = Double(cacheCreationTokens) / 1_000_000 * 18.75
        return inputCost + outputCost + cacheReadCost + cacheCreationCost
    }

    /// session 持续时间（秒）
    var durationSeconds: Double {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - 扫描器

enum HistoryScanner {
    private struct CachedScanEntry: Codable, Sendable {
        let filePath: String
        let fileSize: Int64
        let modifiedAt: TimeInterval
        let session: ScannedSession

        func matches(fileSize: Int64, modifiedAt: TimeInterval) -> Bool {
            self.fileSize == fileSize && abs(self.modifiedAt - modifiedAt) < 0.5
        }
    }

    private struct CachedScanStore: Codable, Sendable {
        let version: Int
        let entries: [String: CachedScanEntry]
    }

    private static let cacheVersion = 1

    /// Claude Code 项目目录
    private static var claudeProjectsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }

    /// 历史扫描缓存文件
    private static var defaultCacheFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let supportDir = appSupport.appendingPathComponent("ClaudeDash", isDirectory: true)
        return supportDir.appendingPathComponent("history-scan-cache.json")
    }

    /// 扫描所有 JSONL 文件，返回 session 统计列表
    static func scanAll(in baseDir: URL? = nil, cacheFileURL: URL? = nil) -> [ScannedSession] {
        let baseDir = baseDir ?? claudeProjectsDir
        guard FileManager.default.fileExists(atPath: baseDir.path) else { return [] }

        var sessions: [ScannedSession] = []
        let cacheURL = cacheFileURL ?? defaultCacheFileURL
        let cacheStore = loadCache(from: cacheURL)
        var updatedEntries: [String: CachedScanEntry] = [:]

        guard let projectDirs = try? FileManager.default.contentsOfDirectory(
            at: baseDir, includingPropertiesForKeys: nil
        ) else { return [] }

        for projectDir in projectDirs {
            guard projectDir.hasDirectoryPath else { continue }

            let projectDirName = projectDir.lastPathComponent
            let projectName = extractProjectName(from: projectDirName)

            // 找所有 .jsonl 文件
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: projectDir, includingPropertiesForKeys: nil
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" {
                let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
                guard let values = try? file.resourceValues(forKeys: resourceKeys),
                      values.isRegularFile != false else { continue }

                let sessionId = file.deletingPathExtension().lastPathComponent
                let filePath = file.path
                let modifiedAt = values.contentModificationDate?.timeIntervalSince1970 ?? 0
                let fileSize = Int64(values.fileSize ?? 0)

                if let cached = cacheStore.entries[filePath],
                   cached.matches(fileSize: fileSize, modifiedAt: modifiedAt) {
                    sessions.append(cached.session)
                    updatedEntries[filePath] = cached
                    continue
                }

                if let session = parseJSONL(
                    at: file,
                    sessionId: sessionId,
                    projectDir: projectDirName,
                    projectName: projectName
                ) {
                    sessions.append(session)
                    updatedEntries[filePath] = CachedScanEntry(
                        filePath: filePath,
                        fileSize: fileSize,
                        modifiedAt: modifiedAt,
                        session: session
                    )
                }
            }
        }

        persistCache(CachedScanStore(version: cacheVersion, entries: updatedEntries), to: cacheURL)
        return sessions.sorted { $0.startTime < $1.startTime }
    }

    /// 从项目目录名提取可读项目名
    /// 格式: "-Users-cj-Documents-personal-project-myapp" → "myapp"
    private static func extractProjectName(from dirName: String) -> String {
        let parts = dirName.split(separator: "-")
        // 取最后一个非空部分
        if let last = parts.last, !last.isEmpty {
            return String(last)
        }
        return dirName
    }

    /// 解析单个 JSONL 文件
    private static func parseJSONL(
        at fileURL: URL,
        sessionId: String,
        projectDir: String,
        projectName: String
    ) -> ScannedSession? {
        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.count >= 2 else { return nil } // 太短，跳过

        var firstTimestamp: Date?
        var lastTimestamp: Date?
        var inputTokens = 0
        var outputTokens = 0
        var cacheReadTokens = 0
        var cacheCreationTokens = 0
        var messageCount = 0
        var toolUseCount = 0
        var toolDistribution: [String: Int] = [:]
        var model = ""

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            // 提取时间戳
            if let ts = json["timestamp"] as? String, let date = isoFormatter.date(from: ts) {
                if firstTimestamp == nil { firstTimestamp = date }
                lastTimestamp = date
            }

            let type = json["type"] as? String ?? ""

            switch type {
            case "assistant":
                messageCount += 1
                // 提取 usage
                if let message = json["message"] as? [String: Any] {
                    if model.isEmpty, let m = message["model"] as? String {
                        model = m
                    }
                    if let usage = message["usage"] as? [String: Any] {
                        inputTokens += usage["input_tokens"] as? Int ?? 0
                        outputTokens += usage["output_tokens"] as? Int ?? 0
                        cacheReadTokens += usage["cache_read_input_tokens"] as? Int ?? 0
                        cacheCreationTokens += usage["cache_creation_input_tokens"] as? Int ?? 0
                    }
                    // 统计工具调用
                    if let content = message["content"] as? [[String: Any]] {
                        for block in content {
                            if let blockType = block["type"] as? String, blockType == "tool_use" {
                                toolUseCount += 1
                                if let toolName = block["name"] as? String {
                                    toolDistribution[toolName, default: 0] += 1
                                }
                            }
                        }
                    }
                }

            case "user":
                messageCount += 1

            default:
                break
            }
        }

        guard let start = firstTimestamp, let end = lastTimestamp else { return nil }

        return ScannedSession(
            sessionId: sessionId,
            projectDir: projectDir,
            projectName: projectName,
            startTime: start,
            endTime: end,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            cacheCreationTokens: cacheCreationTokens,
            messageCount: messageCount,
            toolUseCount: toolUseCount,
            model: model,
            filePath: fileURL.path,
            toolDistribution: toolDistribution
        )
    }

    private static func loadCache(from url: URL) -> CachedScanStore {
        guard let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(CachedScanStore.self, from: data),
              store.version == cacheVersion else {
            return CachedScanStore(version: cacheVersion, entries: [:])
        }
        return store
    }

    private static func persistCache(_ store: CachedScanStore, to url: URL) {
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(store) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
