// TranscriptParser.swift
// ClaudeDash - JSONL Transcript real-time parser
// Incremental parsing of ~/.claude/projects/{project}/{session}.jsonl

import Foundation
import Combine

final class TranscriptParser: ObservableObject, @unchecked Sendable {
    @Published private(set) var lastMessages: [TranscriptMessage] = []
    @Published private(set) var currentStatus: SessionStatus = .unknown
    @Published private(set) var currentTool: ToolType = .unknown
    @Published private(set) var tokenUsage: Double = 0.0

    let filePath: String

    private let parseQueue = DispatchQueue(
        label: "ClaudeDash.TranscriptParser",
        qos: .utility
    )
    private let maxContextTokens: Double = 200_000

    private var fileOffset: UInt64 = 0
    private var totalInputTokens: Int = 0
    private var totalOutputTokens: Int = 0
    private var bufferedMessages: [TranscriptMessage] = []
    private var statusValue: SessionStatus = .unknown
    private var toolValue: ToolType = .unknown
    private var tokenUsageValue: Double = 0.0

    init(filePath: String) {
        self.filePath = filePath
        parseNewContent()
    }

    // MARK: - Incremental parse

    func parseNewContent() {
        parseQueue.async { [weak self] in
            self?.parseNewContentSync()
        }
    }

    private func parseNewContentSync() {
        guard FileManager.default.fileExists(atPath: filePath),
              let fileHandle = FileHandle(forReadingAtPath: filePath) else { return }
        defer { fileHandle.closeFile() }

        fileHandle.seek(toFileOffset: fileOffset)
        let newData = fileHandle.readDataToEndOfFile()
        guard !newData.isEmpty else { return }

        fileOffset = fileHandle.offsetInFile

        guard let content = String(data: newData, encoding: .utf8) else { return }
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            parseLine(trimmed)
        }

        publishState()
    }

    // MARK: - Line parsing

    private func parseLine(_ line: String) {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let lineType = json["type"] as? String ?? ""

        switch lineType {
        case "assistant":
            parseAssistantLine(json)
        case "user":
            parseUserLine(json)
        case "progress":
            parseProgressLine(json)
        case "system":
            if statusValue == .unknown {
                statusValue = .thinking
            }
        default:
            break
        }
    }

    private func parseAssistantLine(_ json: [String: Any]) {
        guard let message = json["message"] as? [String: Any] else { return }

        let contentBlocks = message["content"] as? [[String: Any]] ?? []

        var toolName: String?
        var textContent = ""
        for block in contentBlocks {
            let blockType = block["type"] as? String ?? ""
            if blockType == "tool_use" {
                toolName = block["name"] as? String
            } else if blockType == "text" {
                textContent += block["text"] as? String ?? ""
            }
        }

        if let usage = message["usage"] as? [String: Any] {
            if let input = usage["input_tokens"] as? Int {
                totalInputTokens = input
            }
            if let output = usage["output_tokens"] as? Int {
                totalOutputTokens = output
            }
            if let cacheRead = usage["cache_read_input_tokens"] as? Int {
                totalInputTokens = max(totalInputTokens, cacheRead)
            }
            let total = Double(totalInputTokens + totalOutputTokens)
            tokenUsageValue = min(1.0, total / maxContextTokens)
        }

        let summary = toolName.map { "[\($0)]" } ?? String(textContent.prefix(200))
        appendMessage(TranscriptMessage(role: "assistant", content: summary, toolName: toolName))

        if let toolName {
            statusValue = .toolRunning
            toolValue = mapToolName(toolName)
        } else {
            statusValue = .thinking
            toolValue = .unknown
        }
    }

    private func parseUserLine(_ json: [String: Any]) {
        guard let message = json["message"] as? [String: Any] else { return }
        let contentBlocks = message["content"] as? [[String: Any]] ?? []

        let hasToolResult = contentBlocks.contains { $0["type"] as? String == "tool_result" }
        statusValue = .thinking
        if hasToolResult {
            toolValue = .unknown
        }

        appendMessage(TranscriptMessage(role: "user", content: hasToolResult ? "[tool_result]" : "user input"))
    }

    private func parseProgressLine(_ json: [String: Any]) {
        guard let progressData = json["data"] as? [String: Any] else { return }
        let dataType = progressData["type"] as? String ?? ""

        guard dataType == "hook_progress" else { return }
        let hookEvent = progressData["hookEvent"] as? String ?? ""
        let hookName = progressData["hookName"] as? String ?? ""

        switch hookEvent {
        case "PreToolUse":
            statusValue = .toolRunning
            if let toolPart = hookName.split(separator: ":").last {
                toolValue = mapToolName(String(toolPart))
            }
        case "PostToolUse":
            statusValue = .thinking
            toolValue = .unknown
        case "Stop":
            statusValue = .completed
        default:
            break
        }
    }

    // MARK: - Helpers

    private func publishState() {
        let messages = bufferedMessages
        let status = statusValue
        let tool = toolValue
        let usage = tokenUsageValue

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            lastMessages = messages
            currentStatus = status
            currentTool = tool
            tokenUsage = usage
        }
    }

    private func appendMessage(_ message: TranscriptMessage) {
        bufferedMessages.append(message)
        if bufferedMessages.count > 5 {
            bufferedMessages.removeFirst(bufferedMessages.count - 5)
        }
    }

    private func mapToolName(_ name: String) -> ToolType {
        let lowered = name.lowercased()
        if lowered.contains("edit") { return .edit }
        if lowered.contains("read") { return .read }
        if lowered.contains("write") { return .write }
        if lowered.contains("grep") { return .grep }
        if lowered.contains("glob") { return .glob }
        if lowered.contains("bash") || lowered.contains("terminal") { return .bash }
        return .unknown
    }
}
