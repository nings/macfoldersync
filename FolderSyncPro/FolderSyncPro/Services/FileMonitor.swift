//
//  FileMonitor.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
import CoreServices
@preconcurrency import Combine

/// 文件变化类型
enum FileChangeType: String {
    case created = "创建"
    case modified = "修改"
    case deleted = "删除"
    case renamed = "重命名"
}

/// 文件变化事件
struct FileChangeEvent {
    let path: String
    let changeType: FileChangeType
    let timestamp: Date

    var description: String {
        "[\(changeType.rawValue)] \(path) @ \(timestamp.smartFormatted)"
    }
}

/// 文件监控器 - 使用 FSEvents API 监控文件系统变化
@MainActor
final class FileMonitor: ObservableObject {
    // MARK: - Properties

    /// 监控的路径
    private var monitoredPaths: Set<String> = []

    /// FSEventStream 引用
    nonisolated(unsafe) private var eventStream: FSEventStreamRef?

    /// 事件回调闭包
    private var eventCallback: ((FileChangeEvent) -> Void)?

    /// 日志管理器
    private let logManager: LogManager

    /// 是否正在监控
    @Published private(set) var isMonitoring: Bool = false

    /// 最近的变化事件
    @Published var recentEvents: [FileChangeEvent] = []

    /// 事件缓冲区（用于事件合并）
    /// 注意：使用 nonisolated(unsafe)，因为访问已通过 Timer 在主线程序列化
    nonisolated(unsafe) private var eventBuffer: [String: FileChangeEvent] = [:]

    /// 事件处理队列
    private let eventQueue = DispatchQueue(label: "com.foldersyncpro.filemonitor", qos: .utility)

    /// 事件延迟定时器
    nonisolated(unsafe) private var eventTimer: Timer?

    /// 事件延迟时间（秒）
    private let eventDelay: TimeInterval = 1.0

    /// 最大事件历史记录数
    private let maxEventHistory: Int = 100

    // MARK: - Initialization

    init(logManager: LogManager? = nil) {
        self.logManager = logManager ?? LogManager.shared
    }

    // MARK: - Monitoring Control

    /// 开始监控指定路径
    /// - Parameters:
    ///   - paths: 要监控的路径列表
    ///   - callback: 文件变化回调
    func startMonitoring(paths: [String], callback: @escaping (FileChangeEvent) -> Void) {
        guard !isMonitoring else {
            logManager.warning("文件监控已经在运行中")
            return
        }

        self.monitoredPaths = Set(paths)
        self.eventCallback = callback

        guard !monitoredPaths.isEmpty else {
            logManager.error("没有指定要监控的路径")
            return
        }

        // 创建 FSEventStream
        createEventStream()

        logManager.info(
            "开始监控文件变化: \(monitoredPaths.count) 个路径",
            operation: .monitorStart
        )
    }

    /// 停止监控
    func stopMonitoring() {
        guard isMonitoring else { return }

        destroyEventStream()

        logManager.info(
            "停止文件监控",
            operation: .monitorStop
        )

        isMonitoring = false
        eventCallback = nil
    }

    /// 添加监控路径
    func addPath(_ path: String) {
        guard isMonitoring else {
            monitoredPaths.insert(path)
            return
        }

        monitoredPaths.insert(path)

        // 重新创建事件流
        destroyEventStream()
        createEventStream()

        logManager.info("添加监控路径: \(path)")
    }

    /// 移除监控路径
    func removePath(_ path: String) {
        monitoredPaths.remove(path)

        if isMonitoring {
            // 重新创建事件流
            destroyEventStream()

            if !monitoredPaths.isEmpty {
                createEventStream()
            }
        }

        logManager.info("移除监控路径: \(path)")
    }

    // MARK: - FSEvents Management

    /// 创建 FSEventStream
    private func createEventStream() {
        let pathsToWatch = Array(monitoredPaths) as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
                eventStreamCallback(streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds)
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // 延迟（秒）
            UInt32(kFSEventStreamCreateFlagUseCFTypes |
                   kFSEventStreamCreateFlagFileEvents |
                   kFSEventStreamCreateFlagWatchRoot)
        )

        guard let stream = eventStream else {
            logManager.error("创建 FSEventStream 失败")
            return
        }

        FSEventStreamSetDispatchQueue(stream, eventQueue)

        if FSEventStreamStart(stream) {
            isMonitoring = true
            logManager.info("FSEventStream 已启动")
        } else {
            logManager.error("启动 FSEventStream 失败")
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    /// 销毁 FSEventStream
    nonisolated private func destroyEventStream() {
        guard let stream = eventStream else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil
    }

    // MARK: - Event Processing

    /// 处理文件系统事件
    fileprivate func processEvents(paths: [String], flags: [FSEventStreamEventFlags]) {
        for (path, flag) in zip(paths, flags) {
            let changeType = determineChangeType(from: flag)

            let event = FileChangeEvent(
                path: path,
                changeType: changeType,
                timestamp: Date()
            )

            // 添加到缓冲区
            eventBuffer[path] = event

            // 取消现有定时器
            eventTimer?.invalidate()

            // 设置新定时器（延迟处理）
            eventTimer = Timer.scheduledTimer(
                withTimeInterval: eventDelay,
                repeats: false
            ) { [weak self] _ in
                self?.flushEventBuffer()
            }
        }
    }

    /// 刷新事件缓冲区
    nonisolated private func flushEventBuffer() {
        guard !eventBuffer.isEmpty else { return }

        let events = Array(eventBuffer.values)
        eventBuffer.removeAll()

        Task { @MainActor in
            for event in events {
                // 过滤不需要的事件
                guard shouldProcessEvent(event) else { continue }

                // 添加到历史记录
                addToEventHistory(event)

                // 记录日志
                logManager.debug(
                    "文件变化: \(event.description)",
                    operation: .scan
                )

                // 调用回调
                eventCallback?(event)
            }
        }
    }

    /// 确定变化类型
    private func determineChangeType(from flags: FSEventStreamEventFlags) -> FileChangeType {
        if flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0 {
            return .created
        } else if flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0 {
            return .deleted
        } else if flags & UInt32(kFSEventStreamEventFlagItemRenamed) != 0 {
            return .renamed
        } else if flags & UInt32(kFSEventStreamEventFlagItemModified) != 0 {
            return .modified
        }
        return .modified
    }

    /// 判断是否应该处理事件
    private func shouldProcessEvent(_ event: FileChangeEvent) -> Bool {
        let path = event.path

        // 过滤隐藏文件
        if path.isHiddenFile {
            return false
        }

        // 过滤系统文件
        let systemFiles = [".DS_Store", ".localized", ".Spotlight-V100", ".Trashes"]
        if systemFiles.contains(where: { path.contains($0) }) {
            return false
        }

        // 过滤临时文件
        if path.hasSuffix(".tmp") || path.hasSuffix(".temp") {
            return false
        }

        return true
    }

    /// 添加到事件历史
    private func addToEventHistory(_ event: FileChangeEvent) {
        recentEvents.insert(event, at: 0)

        // 限制历史记录大小
        if recentEvents.count > maxEventHistory {
            recentEvents = Array(recentEvents.prefix(maxEventHistory))
        }
    }

    // MARK: - Helper Methods

    /// 清空事件历史
    func clearEventHistory() {
        recentEvents.removeAll()
    }

    /// 获取指定路径的事件
    func events(for path: String) -> [FileChangeEvent] {
        recentEvents.filter { $0.path == path }
    }

    // MARK: - Cleanup

    deinit {
        // 直接销毁 event stream，不调用 stopMonitoring（避免 MainActor 隔离问题）
        destroyEventStream()
    }
}

// MARK: - FSEvents Callback
fileprivate func eventStreamCallback(
    _ streamRef: ConstFSEventStreamRef,
    _ clientCallBackInfo: UnsafeMutableRawPointer?,
    _ numEvents: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    _ eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }

    let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
    let flags = Array(UnsafeBufferPointer(start: eventFlags, count: numEvents))

    Task { @MainActor in
        monitor.processEvents(paths: paths, flags: flags)
    }
}
