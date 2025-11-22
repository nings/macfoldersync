//
//  SyncLog.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
import SwiftData

/// 日志级别枚举
enum LogLevel: String, Codable, Comparable {
    case debug = "调试"
    case info = "信息"
    case warning = "警告"
    case error = "错误"
    case critical = "严重"

    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

/// 同步操作类型枚举
enum SyncOperation: String, Codable {
    case scan = "扫描"
    case copy = "复制"
    case update = "更新"
    case delete = "删除"
    case conflictResolved = "解决冲突"
    case monitorStart = "开始监控"
    case monitorStop = "停止监控"
    case configUpdate = "配置更新"
    case error = "错误"
}

/// 同步日志数据模型
@Model
final class SyncLog {
    // MARK: - Properties

    /// 唯一标识符
    var id: UUID

    /// 时间戳
    var timestamp: Date

    /// 日志级别
    var level: LogLevel

    /// 同步操作类型
    var operation: SyncOperation

    /// 日志消息
    var message: String

    /// 关联的配置 ID
    var configurationId: UUID?

    /// 文件路径（如果适用）
    var filePath: String?

    /// 详细信息
    var details: String?

    /// 错误代码（如果是错误日志）
    var errorCode: Int?

    /// 持续时间（秒）
    var duration: TimeInterval?

    /// 处理的文件数量
    var filesProcessed: Int?

    /// 总字节数
    var bytesProcessed: Int64?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        operation: SyncOperation,
        message: String,
        configurationId: UUID? = nil,
        filePath: String? = nil,
        details: String? = nil,
        errorCode: Int? = nil,
        duration: TimeInterval? = nil,
        filesProcessed: Int? = nil,
        bytesProcessed: Int64? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.operation = operation
        self.message = message
        self.configurationId = configurationId
        self.filePath = filePath
        self.details = details
        self.errorCode = errorCode
        self.duration = duration
        self.filesProcessed = filesProcessed
        self.bytesProcessed = bytesProcessed
    }

    // MARK: - Convenience Initializers

    /// 创建信息日志
    static func info(
        operation: SyncOperation,
        message: String,
        configurationId: UUID? = nil,
        filePath: String? = nil
    ) -> SyncLog {
        SyncLog(
            level: .info,
            operation: operation,
            message: message,
            configurationId: configurationId,
            filePath: filePath
        )
    }

    /// 创建错误日志
    static func error(
        operation: SyncOperation,
        message: String,
        configurationId: UUID? = nil,
        filePath: String? = nil,
        errorCode: Int? = nil,
        details: String? = nil
    ) -> SyncLog {
        SyncLog(
            level: .error,
            operation: operation,
            message: message,
            configurationId: configurationId,
            filePath: filePath,
            details: details,
            errorCode: errorCode
        )
    }

    /// 创建警告日志
    static func warning(
        operation: SyncOperation,
        message: String,
        configurationId: UUID? = nil,
        filePath: String? = nil
    ) -> SyncLog {
        SyncLog(
            level: .warning,
            operation: operation,
            message: message,
            configurationId: configurationId,
            filePath: filePath
        )
    }

    /// 创建调试日志
    static func debug(
        operation: SyncOperation,
        message: String,
        configurationId: UUID? = nil,
        filePath: String? = nil
    ) -> SyncLog {
        SyncLog(
            level: .debug,
            operation: operation,
            message: message,
            configurationId: configurationId,
            filePath: filePath
        )
    }

    // MARK: - Methods

    /// 获取格式化的时间戳
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    /// 获取格式化的持续时间
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        return String(format: "%.2f秒", duration)
    }

    /// 获取格式化的处理字节数
    var formattedBytesProcessed: String? {
        guard let bytes = bytesProcessed else { return nil }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// 获取日志的简要摘要
    var summary: String {
        var parts: [String] = []
        parts.append("[\(level.rawValue)]")
        parts.append(operation.rawValue)
        if let filesProcessed = filesProcessed {
            parts.append("(\(filesProcessed)个文件)")
        }
        parts.append(message)
        return parts.joined(separator: " ")
    }
}

// MARK: - CustomStringConvertible
extension SyncLog: CustomStringConvertible {
    var description: String {
        """
        SyncLog(
            time: \(formattedTimestamp),
            level: \(level.rawValue),
            operation: \(operation.rawValue),
            message: \(message)
        )
        """
    }
}
