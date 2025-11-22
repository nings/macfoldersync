//
//  SyncConfiguration.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
import SwiftData

/// 同步模式枚举
enum SyncMode: String, Codable {
    case bidirectional = "双向同步"
    case sourceToTarget = "源到目标"
    case targetToSource = "目标到源"
}

/// 冲突解决策略枚举
enum ConflictResolutionStrategy: String, Codable {
    case newerWins = "较新文件胜出"
    case largerWins = "较大文件胜出"
    case askUser = "询问用户"
    case skip = "跳过冲突"
}

/// 同步配置数据模型
@Model
final class SyncConfiguration {
    // MARK: - Properties

    /// 唯一标识符
    var id: UUID

    /// 配置名称
    var name: String

    /// 源文件夹路径
    var sourcePath: String

    /// 目标文件夹路径
    var targetPath: String

    /// 同步模式
    var syncMode: SyncMode

    /// 冲突解决策略
    var conflictStrategy: ConflictResolutionStrategy

    /// 是否启用实时监控
    var isRealtimeMonitorEnabled: Bool

    /// 是否已激活
    var isActive: Bool

    /// 排除模式列表
    var excludePatterns: [String]

    /// 包含模式列表
    var includePatterns: [String]

    /// 创建时间
    var createdAt: Date

    /// 最后修改时间
    var updatedAt: Date

    /// 最后同步时间
    var lastSyncedAt: Date?

    /// 源文件夹安全书签数据（Base64 编码的字符串）
    var sourceBookmarkBase64: String?

    /// 目标文件夹安全书签数据（Base64 编码的字符串）
    var targetBookmarkBase64: String?

    /// 同步间隔（秒），用于定时同步
    var syncInterval: TimeInterval

    // MARK: - Computed Properties

    /// 源文件夹 bookmark 数据
    var sourceBookmarkData: Data? {
        get {
            guard let base64 = sourceBookmarkBase64 else { return nil }
            return Data(base64Encoded: base64)
        }
        set {
            sourceBookmarkBase64 = newValue?.base64EncodedString()
        }
    }

    /// 目标文件夹 bookmark 数据
    var targetBookmarkData: Data? {
        get {
            guard let base64 = targetBookmarkBase64 else { return nil }
            return Data(base64Encoded: base64)
        }
        set {
            targetBookmarkBase64 = newValue?.base64EncodedString()
        }
    }

    /// 最大并发数
    var maxConcurrentOperations: Int

    /// 是否验证文件完整性（使用校验和）
    var verifyFileIntegrity: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        sourcePath: String,
        targetPath: String,
        syncMode: SyncMode = .bidirectional,
        conflictStrategy: ConflictResolutionStrategy = .newerWins,
        isRealtimeMonitorEnabled: Bool = true,
        isActive: Bool = true,
        excludePatterns: [String] = [".DS_Store", ".git/*", "node_modules/*", "*.tmp", "*.log"],
        includePatterns: [String] = [],
        syncInterval: TimeInterval = 60,
        maxConcurrentOperations: Int = 4,
        verifyFileIntegrity: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sourcePath = sourcePath
        self.targetPath = targetPath
        self.syncMode = syncMode
        self.conflictStrategy = conflictStrategy
        self.isRealtimeMonitorEnabled = isRealtimeMonitorEnabled
        self.isActive = isActive
        self.excludePatterns = excludePatterns
        self.includePatterns = includePatterns
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncInterval = syncInterval
        self.maxConcurrentOperations = maxConcurrentOperations
        self.verifyFileIntegrity = verifyFileIntegrity
    }

    // MARK: - Methods

    /// 更新最后同步时间
    func updateLastSyncTime() {
        self.lastSyncedAt = Date()
        self.updatedAt = Date()
    }

    /// 检查文件是否应该被排除
    func shouldExclude(_ path: String) -> Bool {
        // 如果有包含模式，先检查是否匹配包含模式
        if !includePatterns.isEmpty {
            let matchesInclude = includePatterns.contains { pattern in
                path.matchesPattern(pattern)
            }
            if !matchesInclude {
                return true
            }
        }

        // 检查是否匹配排除模式
        return excludePatterns.contains { pattern in
            path.matchesPattern(pattern)
        }
    }

    /// 验证配置是否有效
    func isValid() -> Bool {
        guard !name.isEmpty else { return false }
        guard !sourcePath.isEmpty else { return false }
        guard !targetPath.isEmpty else { return false }
        guard sourcePath != targetPath else { return false }
        return true
    }
}

// MARK: - CustomStringConvertible
extension SyncConfiguration: CustomStringConvertible {
    var description: String {
        """
        SyncConfiguration(
            name: \(name),
            source: \(sourcePath),
            target: \(targetPath),
            mode: \(syncMode.rawValue),
            active: \(isActive)
        )
        """
    }
}
