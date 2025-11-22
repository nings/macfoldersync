//
//  SyncEngine.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
@preconcurrency import Combine

/// 同步状态
enum SyncStatus: String {
    case idle = "空闲"
    case scanning = "扫描中"
    case syncing = "同步中"
    case paused = "已暂停"
    case completed = "已完成"
    case error = "错误"
}

/// 同步进度信息
struct SyncProgress {
    var totalFiles: Int = 0
    var processedFiles: Int = 0
    var totalBytes: Int64 = 0
    var processedBytes: Int64 = 0
    var currentFile: String = ""
    var errors: Int = 0

    var percentage: Double {
        guard totalFiles > 0 else { return 0 }
        return Double(processedFiles) / Double(totalFiles) * 100
    }

    var formattedProgress: String {
        "\(processedFiles)/\(totalFiles) 文件 (\(String(format: "%.1f", percentage))%)"
    }
}

/// 同步结果
struct SyncResult {
    let filesAdded: Int
    let filesModified: Int
    let filesDeleted: Int
    let filesSkipped: Int
    let conflictsResolved: Int
    let errors: [Error]
    let duration: TimeInterval
    let bytesProcessed: Int64

    var totalFilesProcessed: Int {
        filesAdded + filesModified + filesDeleted
    }

    var isSuccess: Bool {
        errors.isEmpty
    }

    var summary: String {
        """
        同步完成:
        - 新增: \(filesAdded) 个
        - 修改: \(filesModified) 个
        - 删除: \(filesDeleted) 个
        - 跳过: \(filesSkipped) 个
        - 冲突: \(conflictsResolved) 个
        - 错误: \(errors.count) 个
        - 耗时: \(String(format: "%.2f", duration)) 秒
        - 数据量: \(ByteCountFormatter.string(fromByteCount: bytesProcessed, countStyle: .file))
        """
    }
}

/// 同步引擎 - 核心同步逻辑
@MainActor
final class SyncEngine: ObservableObject {
    // MARK: - Properties

    /// 当前同步状态
    @Published private(set) var status: SyncStatus = .idle

    /// 同步进度
    @Published private(set) var progress: SyncProgress = SyncProgress()

    /// 日志管理器
    private let logManager: LogManager

    /// 冲突解决器
    private let conflictResolver: ConflictResolver

    /// 同步任务
    private var syncTask: Task<Void, Never>?

    /// 是否已取消
    private var isCancelled: Bool = false

    /// 并发队列
    private let syncQueue = DispatchQueue(label: "com.foldersyncpro.sync", qos: .userInitiated, attributes: .concurrent)

    // MARK: - Initialization

    init(
        logManager: LogManager? = nil,
        conflictResolver: ConflictResolver
    ) {
        self.logManager = logManager ?? LogManager.shared
        self.conflictResolver = conflictResolver
    }

    // MARK: - Sync Control

    /// 开始同步
    /// - Parameter configuration: 同步配置
    func startSync(configuration: SyncConfiguration) async -> SyncResult {
        guard status == .idle else {
            logManager.warning("同步已在进行中", configurationId: configuration.id)
            return SyncResult(
                filesAdded: 0,
                filesModified: 0,
                filesDeleted: 0,
                filesSkipped: 0,
                conflictsResolved: 0,
                errors: [NSError(domain: "SyncEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "同步已在进行中"])],
                duration: 0,
                bytesProcessed: 0
            )
        }

        isCancelled = false
        status = .scanning
        progress = SyncProgress()

        let startTime = Date()

        logManager.info(
            "开始同步: \(configuration.name)",
            operation: .scan,
            configurationId: configuration.id
        )

        // 保存 security-scoped URLs 以在整个同步期间保持权限
        var sourceSecurityScopedURL: URL?
        var targetSecurityScopedURL: URL?

        // 确保在同步结束时释放权限并重置状态
        defer {
            sourceSecurityScopedURL?.stopAccessingSecurityScopedResource()
            targetSecurityScopedURL?.stopAccessingSecurityScopedResource()
            // 重置状态为 idle，以便下次可以再次同步
            if status != .idle {
                status = .idle
            }
        }

        do {
            // 验证配置
            guard configuration.isValid() else {
                throw SyncError.invalidConfiguration
            }

            logManager.debug(
                "配置验证通过: 源=\(configuration.sourcePath), 目标=\(configuration.targetPath)",
                operation: .scan,
                configurationId: configuration.id
            )

            // 恢复 security-scoped bookmarks 并开始访问
            let fileManager = FileManager.default

            if let sourceBookmark = configuration.sourceBookmarkData {
                do {
                    let url = try fileManager.resolveSecurityScopedBookmark(sourceBookmark)
                    if url.startAccessingSecurityScopedResource() {
                        sourceSecurityScopedURL = url
                        logManager.debug(
                            "已恢复源文件夹访问权限: \(url.path)",
                            operation: .scan,
                            configurationId: configuration.id
                        )
                    } else {
                        logManager.warning(
                            "无法访问源文件夹: \(url.path)",
                            operation: .scan,
                            configurationId: configuration.id
                        )
                    }
                } catch {
                    logManager.warning("恢复源文件夹权限失败: \(error.localizedDescription)")
                }
            }

            if let targetBookmark = configuration.targetBookmarkData {
                do {
                    let url = try fileManager.resolveSecurityScopedBookmark(targetBookmark)
                    if url.startAccessingSecurityScopedResource() {
                        targetSecurityScopedURL = url
                        logManager.debug(
                            "已恢复目标文件夹访问权限: \(url.path)",
                            operation: .scan,
                            configurationId: configuration.id
                        )
                    } else {
                        logManager.warning(
                            "无法访问目标文件夹: \(url.path)",
                            operation: .scan,
                            configurationId: configuration.id
                        )
                    }
                } catch {
                    logManager.warning("恢复目标文件夹权限失败: \(error.localizedDescription)")
                }
            }

            // 检查路径
            try validatePaths(configuration: configuration)

            logManager.debug(
                "路径验证通过",
                operation: .scan,
                configurationId: configuration.id
            )

            // 扫描文件
            let (sourceFiles, targetFiles) = try await scanFiles(configuration: configuration)

            // 分析差异
            let changes = analyzeChanges(
                sourceFiles: sourceFiles,
                targetFiles: targetFiles,
                configuration: configuration
            )

            // 执行同步
            let result = try await performSync(
                changes: changes,
                configuration: configuration,
                startTime: startTime
            )

            status = .completed
            configuration.updateLastSyncTime()

            logManager.log(
                level: .info,
                operation: .scan,
                message: "同步完成: \(result.summary)",
                configurationId: configuration.id,
                filesProcessed: result.totalFilesProcessed,
                bytesProcessed: result.bytesProcessed
            )

            return result

        } catch {
            status = .error

            logManager.error(
                "同步失败: \(error.localizedDescription)",
                operation: .error,
                configurationId: configuration.id,
                error: error
            )

            let duration = Date().timeIntervalSince(startTime)
            return SyncResult(
                filesAdded: 0,
                filesModified: 0,
                filesDeleted: 0,
                filesSkipped: 0,
                conflictsResolved: 0,
                errors: [error],
                duration: duration,
                bytesProcessed: 0
            )
        }
    }

    /// 取消同步
    func cancelSync() {
        isCancelled = true
        syncTask?.cancel()
        status = .idle

        logManager.warning("同步已取消", operation: .scan)
    }

    /// 暂停同步
    func pauseSync() {
        status = .paused
        logManager.info("同步已暂停", operation: .scan)
    }

    /// 恢复同步
    func resumeSync() {
        if status == .paused {
            status = .syncing
            logManager.info("同步已恢复", operation: .scan)
        }
    }

    // MARK: - Path Validation

    /// 验证路径
    private func validatePaths(configuration: SyncConfiguration) throws {
        let fileManager = FileManager.default

        // 检查源路径
        guard fileManager.fileExists(atPath: configuration.sourcePath) else {
            throw SyncError.sourcePathNotFound
        }

        // 检查目标路径
        guard fileManager.fileExists(atPath: configuration.targetPath) else {
            throw SyncError.targetPathNotFound
        }

        // 检查是否为目录
        guard fileManager.isDirectory(atPath: configuration.sourcePath) else {
            throw SyncError.sourceNotDirectory
        }

        guard fileManager.isDirectory(atPath: configuration.targetPath) else {
            throw SyncError.targetNotDirectory
        }
    }

    // MARK: - File Scanning

    /// 扫描文件
    private func scanFiles(
        configuration: SyncConfiguration
    ) async throws -> ([String: FileItem], [String: FileItem]) {
        status = .scanning

        logManager.info("开始扫描文件...", operation: .scan, configurationId: configuration.id)

        let sourceURL = URL(fileURLWithPath: configuration.sourcePath)
        let targetURL = URL(fileURLWithPath: configuration.targetPath)

        async let sourceFiles = scanDirectory(url: sourceURL, location: .source, configuration: configuration)
        async let targetFiles = scanDirectory(url: targetURL, location: .target, configuration: configuration)

        let (source, target) = try await (sourceFiles, targetFiles)

        logManager.info(
            "扫描完成: 源(\(source.count)个文件) 目标(\(target.count)个文件)",
            operation: .scan,
            configurationId: configuration.id
        )

        return (source, target)
    }

    /// 扫描目录
    private func scanDirectory(
        url: URL,
        location: FileLocation,
        configuration: SyncConfiguration
    ) async throws -> [String: FileItem] {
        // 添加详细的调试信息
        logManager.debug(
            "开始扫描目录: \(url.path) (\(location == .source ? "源" : "目标"))",
            operation: .scan,
            configurationId: configuration.id
        )

        // 检查目录是否存在
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            logManager.error(
                "目录不存在: \(url.path)",
                operation: .error,
                configurationId: configuration.id
            )
            throw FileManagerError.pathNotFound
        }

        guard isDirectory.boolValue else {
            logManager.error(
                "路径不是目录: \(url.path)",
                operation: .error,
                configurationId: configuration.id
            )
            throw FileManagerError.notADirectory
        }

        // 在后台线程扫描文件列表（避免阻塞主线程）
        let fileURLs = try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let urls = try fileManager.recursiveContents(of: url, includeHidden: false)
                    continuation.resume(returning: urls)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        logManager.debug(
            "扫描到 \(fileURLs.count) 个文件 (位置: \(location == .source ? "源" : "目标"))",
            operation: .scan,
            configurationId: configuration.id
        )

        // 如果没有文件，记录警告
        if fileURLs.isEmpty {
            logManager.warning(
                "目录为空或无法访问: \(url.path)",
                operation: .scan,
                configurationId: configuration.id
            )
        }

        var files: [String: FileItem] = [:]
        var processedCount = 0
        var excludedCount = 0

        // 处理文件列表
        for fileURL in fileURLs {
            // 检查是否取消
            if isCancelled { break }

            let relativePath = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")

            // 检查是否应该排除
            if configuration.shouldExclude(relativePath) {
                excludedCount += 1
                continue
            }

            do {
                // 在后台读取文件属性
                var fileItem = try await withCheckedThrowingContinuation { continuation in
                    Task.detached {
                        do {
                            let item = try FileItem.from(url: fileURL, baseURL: url, location: location)
                            continuation.resume(returning: item)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }

                // 如果需要验证完整性，计算校验和
                if configuration.verifyFileIntegrity && !fileItem.isDirectory {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        Task.detached {
                            do {
                                try fileItem.calculateSHA256()
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }

                files[relativePath] = fileItem
                processedCount += 1

            } catch {
                logManager.warning(
                    "跳过文件: \(relativePath) - \(error.localizedDescription)",
                    operation: .scan
                )
            }
        }

        logManager.debug(
            "扫描完成 (\(location == .source ? "源" : "目标")): 处理了 \(processedCount) 个文件, 排除了 \(excludedCount) 个文件",
            operation: .scan,
            configurationId: configuration.id
        )

        return files
    }

    // MARK: - Change Analysis

    /// 分析变化
    private func analyzeChanges(
        sourceFiles: [String: FileItem],
        targetFiles: [String: FileItem],
        configuration: SyncConfiguration
    ) -> SyncChanges {
        logManager.debug(
            "开始分析变化: 源文件 \(sourceFiles.count) 个, 目标文件 \(targetFiles.count) 个",
            operation: .scan,
            configurationId: configuration.id
        )

        var changes = SyncChanges()

        // 检查源文件
        for (path, sourceFile) in sourceFiles {
            if let targetFile = targetFiles[path] {
                // 文件在两边都存在 - 检查是否需要更新
                if shouldUpdate(source: sourceFile, target: targetFile, configuration: configuration) {
                    if conflictResolver.detectConflict(between: sourceFile, and: targetFile) {
                        // 存在冲突
                        let conflict = conflictResolver.createConflictInfo(
                            sourceFile: sourceFile,
                            targetFile: targetFile
                        )
                        changes.conflicts.append(conflict)
                        logManager.debug(
                            "发现冲突: \(path)",
                            operation: .scan,
                            configurationId: configuration.id
                        )
                    } else {
                        // 需要更新
                        changes.toUpdate.append(sourceFile)
                        logManager.debug(
                            "需要更新: \(path)",
                            operation: .scan,
                            configurationId: configuration.id
                        )
                    }
                }
            } else {
                // 文件只在源存在 - 需要添加
                changes.toAdd.append(sourceFile)
                logManager.debug(
                    "需要添加: \(path)",
                    operation: .scan,
                    configurationId: configuration.id
                )
            }
        }

        // 检查目标文件（查找需要删除的）
        if configuration.syncMode == .bidirectional || configuration.syncMode == .sourceToTarget {
            for (path, targetFile) in targetFiles {
                if sourceFiles[path] == nil {
                    // 文件只在目标存在 - 可能需要删除
                    changes.toDelete.append(targetFile)
                    logManager.debug(
                        "需要删除: \(path)",
                        operation: .scan,
                        configurationId: configuration.id
                    )
                }
            }
        }

        logManager.info(
            "变化分析完成: 添加 \(changes.toAdd.count), 更新 \(changes.toUpdate.count), 删除 \(changes.toDelete.count), 冲突 \(changes.conflicts.count)",
            operation: .scan,
            configurationId: configuration.id
        )

        return changes
    }

    /// 判断是否应该更新
    private func shouldUpdate(
        source: FileItem,
        target: FileItem,
        configuration: SyncConfiguration
    ) -> Bool {
        // 如果验证完整性且校验和相同，不需要更新
        if configuration.verifyFileIntegrity,
           let sourceSHA = source.sha256Checksum,
           let targetSHA = target.sha256Checksum,
           sourceSHA == targetSHA {
            return false
        }

        // 比较修改时间
        return !source.modificationDate.isEqual(to: target.modificationDate, withTolerance: 1.0)
    }

    // MARK: - Sync Execution

    /// 执行同步
    private func performSync(
        changes: SyncChanges,
        configuration: SyncConfiguration,
        startTime: Date
    ) async throws -> SyncResult {
        status = .syncing

        var filesAdded = 0
        var filesModified = 0
        var filesDeleted = 0
        var filesSkipped = 0
        var conflictsResolved = 0
        var errors: [Error] = []
        var totalBytes: Int64 = 0

        let sourceURL = URL(fileURLWithPath: configuration.sourcePath)
        let targetURL = URL(fileURLWithPath: configuration.targetPath)

        // 设置进度
        progress.totalFiles = changes.toAdd.count + changes.toUpdate.count +
                             changes.toDelete.count + changes.conflicts.count

        logManager.info(
            "开始执行同步操作: 总共 \(progress.totalFiles) 个操作",
            operation: .copy,
            configurationId: configuration.id
        )

        // 如果没有任何变化，直接返回
        if progress.totalFiles == 0 {
            logManager.info(
                "没有需要同步的文件",
                operation: .scan,
                configurationId: configuration.id
            )

            let duration = Date().timeIntervalSince(startTime)
            return SyncResult(
                filesAdded: 0,
                filesModified: 0,
                filesDeleted: 0,
                filesSkipped: 0,
                conflictsResolved: 0,
                errors: [],
                duration: duration,
                bytesProcessed: 0
            )
        }

        // 处理新增文件
        if !changes.toAdd.isEmpty {
            logManager.info(
                "开始复制新文件: \(changes.toAdd.count) 个",
                operation: .copy,
                configurationId: configuration.id
            )
        }

        for file in changes.toAdd {
            if isCancelled { break }

            do {
                logManager.debug(
                    "复制文件: \(file.relativePath)",
                    operation: .copy,
                    configurationId: configuration.id
                )
                try await copyFile(file, from: sourceURL, to: targetURL)
                filesAdded += 1
                totalBytes += file.fileSize
                updateProgress(currentFile: file.relativePath)
            } catch {
                logManager.error(
                    "复制文件失败: \(file.relativePath) - \(error.localizedDescription)",
                    operation: .error,
                    configurationId: configuration.id,
                    error: error
                )
                errors.append(error)
                filesSkipped += 1
            }
        }

        // 处理更新文件
        if !changes.toUpdate.isEmpty {
            logManager.info(
                "开始更新文件: \(changes.toUpdate.count) 个",
                operation: .copy,
                configurationId: configuration.id
            )
        }

        for file in changes.toUpdate {
            if isCancelled { break }

            do {
                logManager.debug(
                    "更新文件: \(file.relativePath)",
                    operation: .copy,
                    configurationId: configuration.id
                )
                try await copyFile(file, from: sourceURL, to: targetURL)
                filesModified += 1
                totalBytes += file.fileSize
                updateProgress(currentFile: file.relativePath)
            } catch {
                logManager.error(
                    "更新文件失败: \(file.relativePath) - \(error.localizedDescription)",
                    operation: .error,
                    configurationId: configuration.id,
                    error: error
                )
                errors.append(error)
                filesSkipped += 1
            }
        }

        // 处理删除文件
        if !changes.toDelete.isEmpty {
            logManager.info(
                "开始删除文件: \(changes.toDelete.count) 个",
                operation: .delete,
                configurationId: configuration.id
            )
        }

        for file in changes.toDelete {
            if isCancelled { break }

            do {
                logManager.debug(
                    "删除文件: \(file.relativePath)",
                    operation: .delete,
                    configurationId: configuration.id
                )
                try await deleteFile(file, at: targetURL)
                filesDeleted += 1
                updateProgress(currentFile: file.relativePath)
            } catch {
                logManager.error(
                    "删除文件失败: \(file.relativePath) - \(error.localizedDescription)",
                    operation: .error,
                    configurationId: configuration.id,
                    error: error
                )
                errors.append(error)
                filesSkipped += 1
            }
        }

        // 处理冲突
        if !changes.conflicts.isEmpty {
            logManager.info(
                "开始解决冲突: \(changes.conflicts.count) 个",
                operation: .conflictResolved,
                configurationId: configuration.id
            )
        }

        for conflict in changes.conflicts {
            if isCancelled { break }

            do {
                let resolution = await conflictResolver.resolve(
                    conflict: conflict,
                    using: configuration.conflictStrategy
                )

                logManager.debug(
                    "解决冲突: \(conflict.relativePath) - 策略: \(configuration.conflictStrategy)",
                    operation: .conflictResolved,
                    configurationId: configuration.id
                )

                try conflictResolver.executeResolution(
                    for: conflict,
                    resolution: resolution,
                    sourceBaseURL: sourceURL,
                    targetBaseURL: targetURL
                )

                conflictsResolved += 1
                updateProgress(currentFile: conflict.relativePath)
            } catch {
                errors.append(error)
                filesSkipped += 1
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        return SyncResult(
            filesAdded: filesAdded,
            filesModified: filesModified,
            filesDeleted: filesDeleted,
            filesSkipped: filesSkipped,
            conflictsResolved: conflictsResolved,
            errors: errors,
            duration: duration,
            bytesProcessed: totalBytes
        )
    }

    // MARK: - File Operations

    /// 复制文件
    private func copyFile(_ file: FileItem, from sourceBase: URL, to targetBase: URL) async throws {
        let sourceURL = sourceBase.appendingPathComponent(file.relativePath)
        let targetURL = targetBase.appendingPathComponent(file.relativePath)

        try FileManager.default.safeCopyItem(at: sourceURL, to: targetURL)

        logManager.debug(
            "复制文件: \(file.relativePath)",
            operation: .copy
        )
    }

    /// 删除文件
    private func deleteFile(_ file: FileItem, at baseURL: URL) async throws {
        let fileURL = baseURL.appendingPathComponent(file.relativePath)

        try FileManager.default.removeItem(at: fileURL)

        logManager.debug(
            "删除文件: \(file.relativePath)",
            operation: .delete
        )
    }

    /// 更新进度
    private func updateProgress(currentFile: String) {
        progress.processedFiles += 1
        progress.currentFile = currentFile
    }
}

// MARK: - Supporting Types

/// 同步变化集合
private struct SyncChanges {
    var toAdd: [FileItem] = []
    var toUpdate: [FileItem] = []
    var toDelete: [FileItem] = []
    var conflicts: [ConflictInfo] = []
}

/// 同步错误
enum SyncError: Error, LocalizedError {
    case invalidConfiguration
    case sourcePathNotFound
    case targetPathNotFound
    case sourceNotDirectory
    case targetNotDirectory
    case insufficientDiskSpace
    case syncInProgress

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "无效的同步配置"
        case .sourcePathNotFound:
            return "源路径不存在"
        case .targetPathNotFound:
            return "目标路径不存在"
        case .sourceNotDirectory:
            return "源路径不是目录"
        case .targetNotDirectory:
            return "目标路径不是目录"
        case .insufficientDiskSpace:
            return "磁盘空间不足"
        case .syncInProgress:
            return "同步已在进行中"
        }
    }
}
