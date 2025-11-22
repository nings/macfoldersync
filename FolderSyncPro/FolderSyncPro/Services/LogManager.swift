//
//  LogManager.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
import SwiftData
import Combine
import os.log

/// 日志管理器 - 负责应用程序的日志记录和管理
@MainActor
final class LogManager: ObservableObject {
    // MARK: - Singleton

    static let shared = LogManager()

    // MARK: - Properties

    /// 模型上下文（用于 SwiftData）
    private var modelContext: ModelContext?

    /// 日志文件 URL
    private let logFileURL: URL

    /// 日志文件句柄
    private var logFileHandle: FileHandle?

    /// 最小日志级别
    @Published var minimumLogLevel: LogLevel = .info

    /// 是否启用文件日志
    @Published var isFileLoggingEnabled: Bool = true

    /// 是否启用控制台日志
    @Published var isConsoleLoggingEnabled: Bool = true

    /// 日志缓冲区（用于批量写入）
    private var logBuffer: [String] = []

    /// 缓冲区大小限制
    private let bufferSizeLimit: Int = 100

    /// 日志写入队列
    private let logQueue = DispatchQueue(label: "com.foldersyncpro.logqueue", qos: .utility)

    /// 系统日志
    private let osLog = OSLog(subsystem: "com.foldersyncpro", category: "LogManager")

    // MARK: - Initialization

    private init() {
        // 设置日志文件路径
        let logsDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
            .appendingPathComponent("FolderSyncPro/Logs", isDirectory: true)

        // 创建日志目录
        try? FileManager.default.createDirectory(
            at: logsDirectory,
            withIntermediateDirectories: true
        )

        // 设置日志文件名（按日期）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        self.logFileURL = logsDirectory.appendingPathComponent("foldersync_\(dateString).log")

        // 初始化日志文件
        initializeLogFile()

        // 定期清理旧日志
        scheduleLogCleanup()
    }

    // MARK: - Setup

    /// 设置模型上下文
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 初始化日志文件
    private func initializeLogFile() {
        // 如果日志文件不存在，创建它
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }

        // 打开文件句柄
        do {
            logFileHandle = try FileHandle(forWritingTo: logFileURL)
            logFileHandle?.seekToEndOfFile()
        } catch {
            os_log("Failed to open log file: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Logging Methods

    /// 记录日志
    /// - Parameters:
    ///   - level: 日志级别
    ///   - operation: 同步操作类型
    ///   - message: 日志消息
    ///   - configurationId: 配置 ID
    ///   - filePath: 文件路径
    ///   - details: 详细信息
    ///   - errorCode: 错误代码
    func log(
        level: LogLevel,
        operation: SyncOperation,
        message: String,
        configurationId: UUID? = nil,
        filePath: String? = nil,
        details: String? = nil,
        errorCode: Int? = nil
    ) {
        // 检查日志级别
        guard level >= minimumLogLevel else { return }

        // 创建日志对象
        let syncLog = SyncLog(
            level: level,
            operation: operation,
            message: message,
            configurationId: configurationId,
            filePath: filePath,
            details: details,
            errorCode: errorCode
        )

        // 异步处理日志
        Task {
            await processLog(syncLog)
        }
    }

    /// 处理日志
    private func processLog(_ log: SyncLog) async {
        // 保存到数据库
        if let modelContext = modelContext {
            modelContext.insert(log)
            try? modelContext.save()
        }

        // 写入控制台
        if isConsoleLoggingEnabled {
            logToConsole(log)
        }

        // 写入文件
        if isFileLoggingEnabled {
            await logToFile(log)
        }
    }

    /// 写入控制台
    private func logToConsole(_ log: SyncLog) {
        let logMessage = formatLogMessage(log)

        switch log.level {
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, logMessage)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: osLog, type: .default, logMessage)
        case .error, .critical:
            os_log("%{public}@", log: osLog, type: .error, logMessage)
        }

        // 同时打印到标准输出
        print(logMessage)
    }

    /// 写入文件
    private func logToFile(_ log: SyncLog) async {
        let logMessage = formatLogMessage(log) + "\n"

        await withCheckedContinuation { continuation in
            logQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                // 添加到缓冲区
                self.logBuffer.append(logMessage)

                // 如果缓冲区达到限制，立即写入
                if self.logBuffer.count >= self.bufferSizeLimit {
                    self.flushLogBuffer()
                }

                continuation.resume()
            }
        }
    }

    /// 刷新日志缓冲区
    private func flushLogBuffer() {
        guard !logBuffer.isEmpty, let fileHandle = logFileHandle else { return }

        let content = logBuffer.joined()
        if let data = content.data(using: .utf8) {
            fileHandle.write(data)
        }

        logBuffer.removeAll()
    }

    /// 格式化日志消息
    private func formatLogMessage(_ log: SyncLog) -> String {
        var components: [String] = []

        // 时间戳
        components.append("[\(log.formattedTimestamp)]")

        // 级别
        components.append("[\(log.level.rawValue)]")

        // 操作类型
        components.append("[\(log.operation.rawValue)]")

        // 配置 ID（如果有）
        if let configId = log.configurationId {
            components.append("[\(configId.uuidString.prefix(8))]")
        }

        // 消息
        components.append(log.message)

        // 文件路径（如果有）
        if let filePath = log.filePath {
            components.append("- \(filePath)")
        }

        // 详细信息（如果有）
        if let details = log.details {
            components.append("\n  详细信息: \(details)")
        }

        return components.joined(separator: " ")
    }

    // MARK: - Convenience Logging Methods

    func debug(_ message: String, operation: SyncOperation = .scan, configurationId: UUID? = nil) {
        log(level: .debug, operation: operation, message: message, configurationId: configurationId)
    }

    func info(_ message: String, operation: SyncOperation = .scan, configurationId: UUID? = nil) {
        log(level: .info, operation: operation, message: message, configurationId: configurationId)
    }

    func warning(_ message: String, operation: SyncOperation = .scan, configurationId: UUID? = nil) {
        log(level: .warning, operation: operation, message: message, configurationId: configurationId)
    }

    func error(
        _ message: String,
        operation: SyncOperation = .error,
        configurationId: UUID? = nil,
        error: Error? = nil
    ) {
        let details = error?.localizedDescription
        log(level: .error, operation: operation, message: message, configurationId: configurationId, details: details)
    }

    func critical(
        _ message: String,
        operation: SyncOperation = .error,
        configurationId: UUID? = nil,
        error: Error? = nil
    ) {
        let details = error?.localizedDescription
        log(level: .critical, operation: operation, message: message, configurationId: configurationId, details: details)
    }

    // MARK: - Query Methods

    /// 获取指定配置的日志
    func logs(for configurationId: UUID, limit: Int = 100) -> [SyncLog] {
        guard let modelContext = modelContext else { return [] }

        let descriptor = FetchDescriptor<SyncLog>(
            predicate: #Predicate { $0.configurationId == configurationId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 获取指定级别的日志
    func logs(withLevel level: LogLevel, limit: Int = 100) -> [SyncLog] {
        guard let modelContext = modelContext else { return [] }

        let descriptor = FetchDescriptor<SyncLog>(
            predicate: #Predicate { $0.level == level },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 获取最近的日志
    func recentLogs(limit: Int = 100) -> [SyncLog] {
        guard let modelContext = modelContext else { return [] }

        var descriptor = FetchDescriptor<SyncLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Cleanup Methods

    /// 定期清理旧日志
    private func scheduleLogCleanup() {
        // 每天清理一次旧日志（保留最近 30 天）
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.cleanupOldLogs(olderThan: 30)
            }
        }
    }

    /// 清理旧日志
    func cleanupOldLogs(olderThan days: Int) {
        guard let modelContext = modelContext else { return }

        let cutoffDate = Date().addingDays(-days)

        let descriptor = FetchDescriptor<SyncLog>(
            predicate: #Predicate { $0.timestamp < cutoffDate }
        )

        if let oldLogs = try? modelContext.fetch(descriptor) {
            for log in oldLogs {
                modelContext.delete(log)
            }
            try? modelContext.save()
        }

        // 清理旧的日志文件
        cleanupOldLogFiles(olderThan: days)
    }

    /// 清理旧的日志文件
    private func cleanupOldLogFiles(olderThan days: Int) {
        let logsDirectory = logFileURL.deletingLastPathComponent()

        guard let logFiles = try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        let cutoffDate = Date().addingDays(-days)

        for logFile in logFiles {
            if let attributes = try? logFile.resourceValues(forKeys: [.creationDateKey]),
               let creationDate = attributes.creationDate,
               creationDate < cutoffDate {
                try? FileManager.default.removeItem(at: logFile)
            }
        }
    }

    /// 导出日志到文件
    func exportLogs(to url: URL) throws {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<SyncLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let logs = try modelContext.fetch(descriptor)
        var content = "FolderSyncPro 日志导出\n"
        content += "导出时间: \(Date().standardFormatted)\n"
        content += "总计: \(logs.count) 条日志\n"
        content += String(repeating: "=", count: 80) + "\n\n"

        for log in logs {
            content += formatLogMessage(log) + "\n"
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Cleanup

    deinit {
        flushLogBuffer()
        try? logFileHandle?.close()
    }
}
