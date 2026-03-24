// SessionMonitor.swift
// ClaudeDash - Active session detection via JSONL file monitoring
// Scans ~/.claude/projects/ for recently-modified .jsonl files

import Foundation
import Combine

@MainActor
final class SessionMonitor: ObservableObject {
    static let shared = SessionMonitor()

    @Published var activeSessions: [ActiveSession] = []

    private let maxSessions = 10
    private let scanQueue = DispatchQueue(label: "ClaudeDash.SessionMonitor.scan", qos: .utility)
    private let idleScanInterval: TimeInterval = 20
    private let activeScanInterval: TimeInterval = 5
    private let transcriptPollInterval: TimeInterval = 3
    private let activeThreshold: TimeInterval = 30
    private let completionThreshold: TimeInterval = 90

    private var scanTimer: Timer?
    private var trackedFiles: [String: TrackedFile] = [:]
    private var parsers: [String: TranscriptParser] = [:]
    private var cancellables: [String: Set<AnyCancellable>] = [:]
    private var fileTimers: [String: Timer] = [:]
    private var isScanInFlight = false
    private var currentScanInterval: TimeInterval?

    private struct TrackedFile: Sendable {
        let path: String
        let projectName: String
        var lastModified: Date
        var isActive: Bool
    }

    private struct DirectoryScanResult {
        let activeFiles: [TrackedFile]
        let completedPaths: [String]
    }

    // MARK: - Start / Stop

    func startMonitoring() {
        scheduleScanTimer(interval: idleScanInterval, fireImmediately: true)
    }

    func stopAllMonitoring() {
        scanTimer?.invalidate()
        scanTimer = nil

        for (_, timer) in fileTimers {
            timer.invalidate()
        }

        fileTimers.removeAll()
        parsers.removeAll()
        cancellables.removeAll()
        trackedFiles.removeAll()
        activeSessions.removeAll()
        isScanInFlight = false
        currentScanInterval = nil
    }

    // MARK: - Directory Scanning

    private func scanProjectsDirectory() {
        guard !isScanInFlight else { return }
        isScanInFlight = true

        let trackedSnapshot = trackedFiles
        let activeThreshold = activeThreshold
        let completionThreshold = completionThreshold

        scanQueue.async { [weak self] in
            let result = Self.scanProjectsDirectorySnapshot(
                trackedFiles: trackedSnapshot,
                activeThreshold: activeThreshold,
                completionThreshold: completionThreshold
            )

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isScanInFlight = false
                self.applyScanResult(result)
            }
        }
    }

    private func applyScanResult(_ result: DirectoryScanResult) {
        for tracked in result.activeFiles {
            if trackedFiles[tracked.path] == nil {
                startTrackingSession(tracked)
            } else {
                trackedFiles[tracked.path]?.lastModified = tracked.lastModified
                trackedFiles[tracked.path]?.isActive = true
            }
        }

        for path in result.completedPaths where trackedFiles[path]?.isActive == true {
            markSessionCompleted(path: path)
        }

        updateScanInterval()
    }

    nonisolated private static func scanProjectsDirectorySnapshot(
        trackedFiles: [String: TrackedFile],
        activeThreshold: TimeInterval,
        completionThreshold: TimeInterval
    ) -> DirectoryScanResult {
        let fileManager = FileManager.default
        let baseDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects").path

        guard fileManager.fileExists(atPath: baseDir),
              let projectDirs = try? fileManager.contentsOfDirectory(atPath: baseDir) else {
            return DirectoryScanResult(activeFiles: [], completedPaths: [])
        }

        var activeFiles: [TrackedFile] = []
        var completedPaths = Set<String>()

        for projectDir in projectDirs {
            let projectPath = (baseDir as NSString).appendingPathComponent(projectDir)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  let files = try? fileManager.contentsOfDirectory(atPath: projectPath) else {
                continue
            }

            for file in files where file.hasSuffix(".jsonl") {
                let filePath = (projectPath as NSString).appendingPathComponent(file)
                guard let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date else {
                    continue
                }

                let age = -modDate.timeIntervalSinceNow
                if age < activeThreshold {
                    activeFiles.append(TrackedFile(
                        path: filePath,
                        projectName: extractProjectName(from: projectDir),
                        lastModified: modDate,
                        isActive: true
                    ))
                } else if let tracked = trackedFiles[filePath],
                          tracked.isActive,
                          age > completionThreshold {
                    completedPaths.insert(filePath)
                }
            }
        }

        return DirectoryScanResult(
            activeFiles: activeFiles,
            completedPaths: Array(completedPaths)
        )
    }

    // MARK: - Session Tracking

    private func startTrackingSession(_ tracked: TrackedFile) {
        let path = tracked.path
        guard parsers[path] == nil else { return }

        if parsers.count >= maxSessions {
            removeOldestSession()
        }

        trackedFiles[path] = tracked

        let parser = TranscriptParser(filePath: path)
        parsers[path] = parser

        let session = ActiveSession(project: tracked.projectName, transcriptPath: path)
        var subscriptions = Set<AnyCancellable>()

        parser.$lastMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                guard let self,
                      let index = self.activeSessions.firstIndex(where: { $0.id == path }) else { return }
                self.activeSessions[index].lastMessages = messages
            }
            .store(in: &subscriptions)

        parser.$currentStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self,
                      let index = self.activeSessions.firstIndex(where: { $0.id == path }) else { return }
                self.activeSessions[index].status = status
            }
            .store(in: &subscriptions)

        parser.$currentTool
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tool in
                guard let self,
                      let index = self.activeSessions.firstIndex(where: { $0.id == path }) else { return }
                self.activeSessions[index].currentTool = tool
            }
            .store(in: &subscriptions)

        parser.$tokenUsage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] usage in
                guard let self,
                      let index = self.activeSessions.firstIndex(where: { $0.id == path }) else { return }
                self.activeSessions[index].tokenUsage = usage
            }
            .store(in: &subscriptions)

        cancellables[path] = subscriptions
        activeSessions.append(session)

        let pollTimer = Timer.scheduledTimer(withTimeInterval: transcriptPollInterval, repeats: true) { [weak self, weak parser] _ in
            guard let parser,
                  let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let modDate = attrs[.modificationDate] as? Date else {
                return
            }

            Task { @MainActor [weak self, weak parser] in
                guard let self, let parser else { return }
                let lastModified = self.trackedFiles[path]?.lastModified
                guard lastModified == nil || modDate > lastModified! else { return }

                self.trackedFiles[path]?.lastModified = modDate
                parser.parseNewContent()
            }
        }
        fileTimers[path] = pollTimer
        updateScanInterval()
    }

    private func markSessionCompleted(path: String) {
        guard let index = activeSessions.firstIndex(where: { $0.id == path }) else { return }
        activeSessions[index].status = .completed
        trackedFiles[path]?.isActive = false

        let session = activeSessions[index]
        NotificationSender.shared.sendCompletionNotification(
            project: session.project,
            durationMs: Int(-session.startTime.timeIntervalSinceNow) * 1000,
            cost: 0,
            summary: "",
            cwd: ""
        )

        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.removeSession(path: path)
            }
        }
    }

    // MARK: - Cleanup

    private func removeSession(path: String) {
        fileTimers[path]?.invalidate()
        fileTimers.removeValue(forKey: path)
        parsers.removeValue(forKey: path)
        cancellables.removeValue(forKey: path)
        trackedFiles.removeValue(forKey: path)
        activeSessions.removeAll { $0.id == path }
        updateScanInterval()
    }

    private func removeOldestSession() {
        guard let oldest = activeSessions.min(by: { $0.startTime < $1.startTime }) else { return }
        removeSession(path: oldest.transcriptPath)
    }

    // MARK: - Helpers

    nonisolated static func extractProjectName(from dirName: String) -> String {
        let components = dirName.split(separator: "-")
        if let last = components.last, !last.isEmpty {
            return String(last)
        }
        return dirName
    }

    private func scheduleScanTimer(interval: TimeInterval, fireImmediately: Bool) {
        guard currentScanInterval != interval || scanTimer == nil else { return }

        scanTimer?.invalidate()
        currentScanInterval = interval
        scanTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scanProjectsDirectory()
            }
        }

        if fireImmediately {
            scanTimer?.fire()
        }
    }

    private func updateScanInterval() {
        let hasActiveWork = trackedFiles.values.contains { $0.isActive } || !activeSessions.isEmpty
        scheduleScanTimer(interval: hasActiveWork ? activeScanInterval : idleScanInterval, fireImmediately: false)
    }
}
