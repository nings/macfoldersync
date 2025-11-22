//
//  ConflictResolver.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
import AppKit
import Combine

/// 冲突信息结构
struct ConflictInfo {
    let sourceFile: FileItem
    let targetFile: FileItem
    let relativePath: String

    var description: String {
        """
        文件冲突:
        - 路径: \(relativePath)
        - 源文件: \(sourceFile.formattedFileSize), 修改于 \(sourceFile.modificationDate.smartFormatted)
        - 目标文件: \(targetFile.formattedFileSize), 修改于 \(targetFile.modificationDate.smartFormatted)
        """
    }
}

/// 冲突解决结果
enum ConflictResolution {
    case useSource      // 使用源文件
    case useTarget      // 使用目标文件
    case skip           // 跳过此文件
    case keepBoth       // 保留两者（重命名）
}

/// 冲突解决器 - 负责处理文件同步冲突
@MainActor
final class ConflictResolver: ObservableObject {
    // MARK: - Properties

    /// 日志管理器
    private let logManager: LogManager

    /// 未解决的冲突列表
    @Published var pendingConflicts: [ConflictInfo] = []

    /// 冲突解决历史
    private var resolutionHistory: [String: ConflictResolution] = [:]

    // MARK: - Initialization

    init(logManager: LogManager = .shared) {
        self.logManager = logManager
    }

    // MARK: - Conflict Resolution

    /// 解决冲突
    /// - Parameters:
    ///   - conflict: 冲突信息
    ///   - strategy: 解决策略
    /// - Returns: 解决结果
    func resolve(
        conflict: ConflictInfo,
        using strategy: ConflictResolutionStrategy
    ) async -> ConflictResolution {
        logManager.info(
            "开始解决冲突: \(conflict.relativePath)",
            operation: .conflictResolved
        )

        let resolution: ConflictResolution

        switch strategy {
        case .newerWins:
            resolution = resolveByNewerWins(conflict)

        case .largerWins:
            resolution = resolveByLargerWins(conflict)

        case .askUser:
            resolution = await resolveByAskingUser(conflict)

        case .skip:
            resolution = .skip
        }

        // 记录解决历史
        resolutionHistory[conflict.relativePath] = resolution

        logManager.info(
            "冲突已解决: \(conflict.relativePath) -> \(resolutionDescription(resolution))",
            operation: .conflictResolved
        )

        return resolution
    }

    /// 批量解决冲突
    /// - Parameters:
    ///   - conflicts: 冲突列表
    ///   - strategy: 解决策略
    /// - Returns: 解决结果映射
    func resolveBatch(
        conflicts: [ConflictInfo],
        using strategy: ConflictResolutionStrategy
    ) async -> [String: ConflictResolution] {
        var results: [String: ConflictResolution] = [:]

        for conflict in conflicts {
            let resolution = await resolve(conflict: conflict, using: strategy)
            results[conflict.relativePath] = resolution
        }

        return results
    }

    // MARK: - Resolution Strategies

    /// 较新文件胜出策略
    private func resolveByNewerWins(_ conflict: ConflictInfo) -> ConflictResolution {
        let comparison = FileItem.compare(conflict.sourceFile, conflict.targetFile)

        switch comparison {
        case .orderedDescending:
            // 源文件更新
            return .useSource
        case .orderedAscending:
            // 目标文件更新
            return .useTarget
        case .orderedSame:
            // 修改时间相同，比较文件大小
            if conflict.sourceFile.fileSize >= conflict.targetFile.fileSize {
                return .useSource
            } else {
                return .useTarget
            }
        }
    }

    /// 较大文件胜出策略
    private func resolveByLargerWins(_ conflict: ConflictInfo) -> ConflictResolution {
        if conflict.sourceFile.fileSize > conflict.targetFile.fileSize {
            return .useSource
        } else if conflict.sourceFile.fileSize < conflict.targetFile.fileSize {
            return .useTarget
        } else {
            // 大小相同，使用较新的
            return resolveByNewerWins(conflict)
        }
    }

    /// 询问用户策略
    private func resolveByAskingUser(_ conflict: ConflictInfo) async -> ConflictResolution {
        // 添加到待处理列表
        pendingConflicts.append(conflict)

        // 在主线程显示对话框
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let resolution = self.showConflictDialog(conflict)
                continuation.resume(returning: resolution)

                // 从待处理列表移除
                if let index = self.pendingConflicts.firstIndex(where: { $0.relativePath == conflict.relativePath }) {
                    self.pendingConflicts.remove(at: index)
                }
            }
        }
    }

    /// 显示冲突对话框
    private func showConflictDialog(_ conflict: ConflictInfo) -> ConflictResolution {
        let alert = NSAlert()
        alert.messageText = "文件冲突"
        alert.informativeText = conflict.description
        alert.alertStyle = .warning

        alert.addButton(withTitle: "使用源文件 (较新)")
        alert.addButton(withTitle: "使用目标文件")
        alert.addButton(withTitle: "跳过")
        alert.addButton(withTitle: "保留两者")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            return .useSource
        case .alertSecondButtonReturn:
            return .useTarget
        case .alertThirdButtonReturn:
            return .skip
        default:
            return .keepBoth
        }
    }

    // MARK: - Conflict Detection

    /// 检测两个文件项之间的冲突
    /// - Parameters:
    ///   - sourceFile: 源文件
    ///   - targetFile: 目标文件
    /// - Returns: 是否存在冲突
    func detectConflict(
        between sourceFile: FileItem,
        and targetFile: FileItem
    ) -> Bool {
        // 如果修改时间差异在1秒内，认为不是冲突（考虑文件系统精度）
        if sourceFile.modificationDate.isEqual(to: targetFile.modificationDate, withTolerance: 1.0) {
            return false
        }

        // 如果文件大小和修改时间都相同，不是冲突
        if sourceFile.fileSize == targetFile.fileSize &&
            sourceFile.modificationDate == targetFile.modificationDate {
            return false
        }

        // 否则存在冲突
        return true
    }

    /// 创建冲突信息
    /// - Parameters:
    ///   - sourceFile: 源文件
    ///   - targetFile: 目标文件
    /// - Returns: 冲突信息
    func createConflictInfo(
        sourceFile: FileItem,
        targetFile: FileItem
    ) -> ConflictInfo {
        ConflictInfo(
            sourceFile: sourceFile,
            targetFile: targetFile,
            relativePath: sourceFile.relativePath
        )
    }

    // MARK: - Conflict Actions

    /// 执行冲突解决操作
    /// - Parameters:
    ///   - conflict: 冲突信息
    ///   - resolution: 解决方案
    ///   - sourceBaseURL: 源文件夹基础 URL
    ///   - targetBaseURL: 目标文件夹基础 URL
    func executeResolution(
        for conflict: ConflictInfo,
        resolution: ConflictResolution,
        sourceBaseURL: URL,
        targetBaseURL: URL
    ) throws {
        let sourceURL = sourceBaseURL.appendingPathComponent(conflict.relativePath)
        let targetURL = targetBaseURL.appendingPathComponent(conflict.relativePath)

        switch resolution {
        case .useSource:
            // 用源文件覆盖目标文件
            try FileManager.default.safeCopyItem(at: sourceURL, to: targetURL)
            logManager.info(
                "使用源文件覆盖: \(conflict.relativePath)",
                operation: .update
            )

        case .useTarget:
            // 用目标文件覆盖源文件
            try FileManager.default.safeCopyItem(at: targetURL, to: sourceURL)
            logManager.info(
                "使用目标文件覆盖: \(conflict.relativePath)",
                operation: .update
            )

        case .skip:
            // 跳过，不做任何操作
            logManager.info(
                "跳过冲突文件: \(conflict.relativePath)",
                operation: .conflictResolved
            )

        case .keepBoth:
            // 保留两者，重命名其中一个
            let timestamp = Date().formatted(with: "yyyyMMdd_HHmmss")
            let fileName = (conflict.relativePath as NSString).lastPathComponent
            let fileExtension = (fileName as NSString).pathExtension
            let baseName = (fileName as NSString).deletingPathExtension

            let newFileName = "\(baseName)_conflict_\(timestamp).\(fileExtension)"
            let newTargetURL = targetURL.deletingLastPathComponent().appendingPathComponent(newFileName)

            try FileManager.default.safeCopyItem(at: targetURL, to: newTargetURL)
            try FileManager.default.safeCopyItem(at: sourceURL, to: targetURL)

            logManager.info(
                "保留两者: \(conflict.relativePath) (重命名为 \(newFileName))",
                operation: .conflictResolved
            )
        }
    }

    // MARK: - Helper Methods

    /// 获取解决方案的描述
    private func resolutionDescription(_ resolution: ConflictResolution) -> String {
        switch resolution {
        case .useSource:
            return "使用源文件"
        case .useTarget:
            return "使用目标文件"
        case .skip:
            return "跳过"
        case .keepBoth:
            return "保留两者"
        }
    }

    /// 清除历史记录
    func clearHistory() {
        resolutionHistory.removeAll()
    }

    /// 获取历史解决方案
    func getHistoricalResolution(for path: String) -> ConflictResolution? {
        resolutionHistory[path]
    }

    /// 获取冲突统计
    func getConflictStatistics() -> (total: Int, resolved: Int, pending: Int) {
        let total = resolutionHistory.count + pendingConflicts.count
        let resolved = resolutionHistory.count
        let pending = pendingConflicts.count
        return (total, resolved, pending)
    }
}
