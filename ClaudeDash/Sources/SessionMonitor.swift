// SessionMonitor.swift
// ClaudeDash - Active session detection via JSONL file monitoring
// Uses filesystem events for active transcripts and a low-frequency reconcile scan.

import Foundation
import Combine
import Darwin

struct SessionDirectoryScanFile: Equatable, Sendable {
    let path: String
    let projectName: String
    let lastModified: Date
}

struct SessionDirectoryScanResult: Equatable, Sendable {
    let activeFiles: [SessionDirectoryScanFile]
    let completedPaths: [String]
}

enum SessionDirectoryScanner {
    static func scan(
        baseDir: String,
        trackedActivity: [String: Bool],
        activeThreshold: TimeInterval,
        completionThreshold: TimeInterval,
        now: Date = Date()
    ) -> SessionDirectoryScanResult {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: baseDir),
              let projectDirs = try? fileManager.contentsOfDirectory(atPath: baseDir) else {
            return SessionDirectoryScanResult(activeFiles: [], completedPaths: [])
        }

        var activeFiles: [SessionDirectoryScanFile] = []
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

                let age = now.timeIntervalSince(modDate)
                if age < activeThreshold {
                    activeFiles.append(SessionDirectoryScanFile(
                        path: filePath,
                        projectName: SessionMonitor.extractProjectName(from: projectDir),
                        lastModified: modDate
                    ))
                } else if trackedActivity[filePath] == true,
                          age > completionThreshold {
                    completedPaths.insert(filePath)
                }
            }
        }

        return SessionDirectoryScanResult(
            activeFiles: activeFiles.sorted { $0.lastModified > $1.lastModified },
            completedPaths: completedPaths.sorted()
        )
    }
}

@MainActor
final class SessionMonitor: ObservableObject {
    static let shared = SessionMonitor()

    @Published var activeSessions: [ActiveSession] = []

    private let maxSessions = 10
    private let scanQueue = DispatchQueue(label: "ClaudeDash.SessionMonitor.scan", qos: .utility)
    private let reconcileInterval: TimeInterval = 8
    private let rescanDebounce: TimeInterval = 0.25
    private let activeThreshold: TimeInterval = 120
    private let completionThreshold: TimeInterval = 180
    private let completedRemovalDelay: TimeInterval = 30
    private var completedTimestamps: [String: Date] = [:]
    private let projectsBaseURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/projects", isDirectory: true)

    private var reconcileTimer: Timer?
    private var trackedFiles: [String: TrackedFile] = [:]
    private var parsers: [String: TranscriptParser] = [:]
    private var cancellables: [String: Set<AnyCancellable>] = [:]
    private var fileSources: [String: DispatchSourceFileSystemObject] = [:]
    private var projectDirectorySources: [String: DispatchSourceFileSystemObject] = [:]
    private var projectDirectoryDescriptors: [String: CInt] = [:]
    private var fileDescriptors: [String: CInt] = [:]
    private var rootDirectorySource: DispatchSourceFileSystemObject?
    private var rootDirectoryDescriptor: CInt = -1
    private var isScanInFlight = false
    private var pendingRescanWorkItem: DispatchWorkItem?

    private struct TrackedFile: Sendable {
        let path: String
        let projectName: String
        var lastModified: Date
        var isActive: Bool
    }

    // MARK: - Start / Stop

    func startMonitoring() {
        refreshDirectoryMonitoring()
        scheduleReconcileTimer(fireImmediately: true)
    }

    func stopAllMonitoring() {
        reconcileTimer?.invalidate()
        reconcileTimer = nil

        pendingRescanWorkItem?.cancel()
        pendingRescanWorkItem = nil

        cancelRootDirectoryWatcher()
        cancelProjectDirectoryWatchers()
        cancelTranscriptWatchers()

        parsers.removeAll()
        cancellables.removeAll()
        trackedFiles.removeAll()
        completedTimestamps.removeAll()
        activeSessions.removeAll()
        isScanInFlight = false
    }

    // MARK: - Directory Scanning

    private func scheduleReconcileTimer(fireImmediately: Bool) {
        guard reconcileTimer == nil else {
            if fireImmediately {
                reconcileTimer?.fire()
            }
            return
        }

        reconcileTimer = Timer.scheduledTimer(withTimeInterval: reconcileInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performReconcile()
            }
        }

        if fireImmediately {
            reconcileTimer?.fire()
        }
    }

    private func performReconcile() {
        refreshDirectoryMonitoring()
        scanProjectsDirectory()
        removeStaleCompletedSessions()
    }

    private func scheduleRescan() {
        pendingRescanWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.performReconcile()
            }
        }
        pendingRescanWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + rescanDebounce, execute: workItem)
    }

    private func scanProjectsDirectory() {
        guard !isScanInFlight else { return }
        isScanInFlight = true

        let trackedSnapshot = trackedFiles.mapValues(\.isActive)
        let baseDir = projectsBaseURL.path
        let activeThreshold = activeThreshold
        let completionThreshold = completionThreshold

        scanQueue.async { [weak self] in
            let result = SessionDirectoryScanner.scan(
                baseDir: baseDir,
                trackedActivity: trackedSnapshot,
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

    private func applyScanResult(_ result: SessionDirectoryScanResult) {
        for tracked in result.activeFiles {
            if trackedFiles[tracked.path] == nil {
                startTrackingSession(tracked)
                continue
            }

            // Only reactivate if file was modified AFTER what we last recorded
            // (i.e., genuinely new content, not just the scan re-seeing the same mtime)
            let previousModified = trackedFiles[tracked.path]?.lastModified ?? .distantPast
            let isNewlyModified = tracked.lastModified > previousModified

            trackedFiles[tracked.path]?.lastModified = tracked.lastModified

            if let index = activeSessions.firstIndex(where: { $0.id == tracked.path }),
               activeSessions[index].status == .completed {
                // Session was completed by parser (Stop event).
                // Only reactivate if the file has genuinely new writes.
                if isNewlyModified {
                    activeSessions[index].status = .unknown
                    trackedFiles[tracked.path]?.isActive = true
                                    }
            } else {
                trackedFiles[tracked.path]?.isActive = true
                            }
        }

        for path in result.completedPaths where trackedFiles[path]?.isActive == true {
            markSessionCompleted(path: path)
        }
    }

    // MARK: - Filesystem Watching

    private func refreshDirectoryMonitoring() {
        guard FileManager.default.fileExists(atPath: projectsBaseURL.path) else {
            cancelRootDirectoryWatcher()
            cancelProjectDirectoryWatchers()
            return
        }

        installRootDirectoryWatcherIfNeeded()
        refreshProjectDirectoryWatchers()
    }

    private func installRootDirectoryWatcherIfNeeded() {
        guard rootDirectorySource == nil else { return }
        let fd = open(projectsBaseURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.scheduleRescan()
            }
        }
        source.setCancelHandler {
            close(fd)
        }
        rootDirectoryDescriptor = fd
        rootDirectorySource = source
        source.resume()
    }

    private func refreshProjectDirectoryWatchers() {
        guard let projectDirs = try? FileManager.default.contentsOfDirectory(
            at: projectsBaseURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            cancelProjectDirectoryWatchers()
            return
        }

        let projectPaths = Set(projectDirs.compactMap { url -> String? in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == true else {
                return nil
            }
            return url.path
        })

        for existingPath in projectDirectorySources.keys where !projectPaths.contains(existingPath) {
            cancelProjectDirectoryWatcher(path: existingPath)
        }

        for path in projectPaths where projectDirectorySources[path] == nil {
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .rename, .delete],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                Task { @MainActor [weak self] in
                    self?.scheduleRescan()
                }
            }
            source.setCancelHandler {
                close(fd)
            }

            projectDirectoryDescriptors[path] = fd
            projectDirectorySources[path] = source
            source.resume()
        }
    }

    private func startWatchingTranscriptFile(at path: String) {
        guard fileSources[path] == nil else { return }

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete, .revoke],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            let flags = source.data
            if flags.contains(.rename) || flags.contains(.delete) || flags.contains(.revoke) {
                Task { @MainActor [weak self] in
                    self?.handleTranscriptInvalidated(path: path)
                }
                return
            }

            Task { @MainActor [weak self] in
                self?.handleTranscriptChanged(path: path)
            }
        }
        source.setCancelHandler {
            close(fd)
        }

        fileDescriptors[path] = fd
        fileSources[path] = source
        source.resume()
    }

    private func handleTranscriptChanged(path: String) {
        guard let parser = parsers[path] else { return }

        let modDate: Date
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
           let value = attributes[.modificationDate] as? Date {
            modDate = value
        } else {
            modDate = Date()
        }

        let previousModified = trackedFiles[path]?.lastModified ?? .distantPast
        trackedFiles[path]?.lastModified = modDate

        // Only reactivate completed sessions when file has genuinely new content
        if modDate > previousModified {
            trackedFiles[path]?.isActive = true

            if let index = activeSessions.firstIndex(where: { $0.id == path }),
               activeSessions[index].status == .completed {
                activeSessions[index].status = .unknown
            }
        }

        parser.parseNewContent()
    }

    private func handleTranscriptInvalidated(path: String) {
        markSessionCompleted(path: path)
        scheduleRescan()
    }

    // MARK: - Session Tracking

    private func startTrackingSession(_ tracked: SessionDirectoryScanFile) {
        let path = tracked.path
        guard parsers[path] == nil else { return }

        if parsers.count >= maxSessions {
            removeOldestSession()
        }

        // When a new transcript appears in the same project directory,
        // mark older sessions from that directory as completed.
        // This handles /clear which creates a new file without writing Stop to the old one.
        let newDir = (path as NSString).deletingLastPathComponent
        for existing in activeSessions where existing.id != path {
            let existingDir = (existing.transcriptPath as NSString).deletingLastPathComponent
            if existingDir == newDir,
               existing.status != .completed,
               let existingMod = trackedFiles[existing.id]?.lastModified,
               existingMod <= tracked.lastModified {
                markSessionCompleted(path: existing.id)
            }
        }

        trackedFiles[path] = TrackedFile(
            path: tracked.path,
            projectName: tracked.projectName,
            lastModified: tracked.lastModified,
            isActive: true
        )

        let parser = TranscriptParser(filePath: path)
        parsers[path] = parser
        startWatchingTranscriptFile(at: path)

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
                // Skip stale parser updates for sessions already marked inactive
                // (e.g. /clear created a new transcript, old session was completed externally)
                if self.trackedFiles[path]?.isActive == false, status != .completed {
                    return
                }
                if status == .completed {
                    self.markSessionCompleted(path: path)
                } else {
                    self.activeSessions[index].status = status
                    // Reactivated after completion — clear the removal timestamp
                    self.completedTimestamps.removeValue(forKey: path)
                }
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
    }

    private func markSessionCompleted(path: String) {
        guard let index = activeSessions.firstIndex(where: { $0.id == path }) else { return }
        if activeSessions[index].status != .completed {
            activeSessions[index].status = .completed
            completedTimestamps[path] = Date()
        }
        trackedFiles[path]?.isActive = false
    }

    private func removeStaleCompletedSessions() {
        let now = Date()
        let stale = completedTimestamps.filter { now.timeIntervalSince($0.value) > completedRemovalDelay }
        for (path, _) in stale {
            removeSession(path: path)
            completedTimestamps.removeValue(forKey: path)
        }
    }

    // MARK: - Cleanup

    private func removeSession(path: String) {
        cancelTranscriptWatcher(path: path)
        parsers.removeValue(forKey: path)
        cancellables.removeValue(forKey: path)
        trackedFiles.removeValue(forKey: path)
        completedTimestamps.removeValue(forKey: path)
        activeSessions.removeAll { $0.id == path }
    }

    private func removeOldestSession() {
        guard let oldest = activeSessions.min(by: { $0.startTime < $1.startTime }) else { return }
        removeSession(path: oldest.transcriptPath)
    }

    private func cancelRootDirectoryWatcher() {
        rootDirectorySource?.cancel()
        rootDirectorySource = nil
        rootDirectoryDescriptor = -1
    }

    private func cancelProjectDirectoryWatchers() {
        for path in Array(projectDirectorySources.keys) {
            cancelProjectDirectoryWatcher(path: path)
        }
        projectDirectoryDescriptors.removeAll()
    }

    private func cancelProjectDirectoryWatcher(path: String) {
        projectDirectorySources[path]?.cancel()
        projectDirectorySources.removeValue(forKey: path)
        projectDirectoryDescriptors.removeValue(forKey: path)
    }

    private func cancelTranscriptWatchers() {
        for path in Array(fileSources.keys) {
            cancelTranscriptWatcher(path: path)
        }
        fileDescriptors.removeAll()
    }

    private func cancelTranscriptWatcher(path: String) {
        fileSources[path]?.cancel()
        fileSources.removeValue(forKey: path)
        fileDescriptors.removeValue(forKey: path)
    }

    // MARK: - Helpers

    nonisolated static func extractProjectName(from dirName: String) -> String {
        let components = dirName.split(separator: "-")
        if let last = components.last, !last.isEmpty {
            return String(last)
        }
        return dirName
    }
}
