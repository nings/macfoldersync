//
//  FileManager+Extensions.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation

extension FileManager {
    /// 安全地复制文件，如果目标存在则先删除
    /// - Parameters:
    ///   - source: 源文件 URL
    ///   - destination: 目标文件 URL
    /// - Throws: 文件操作错误
    func safeCopyItem(at source: URL, to destination: URL) throws {
        // 如果目标已存在，先删除
        if fileExists(atPath: destination.path) {
            try removeItem(at: destination)
        }

        // 确保目标目录存在
        let destinationDir = destination.deletingLastPathComponent()
        if !fileExists(atPath: destinationDir.path) {
            try createDirectory(at: destinationDir, withIntermediateDirectories: true)
        }

        // 复制文件
        try copyItem(at: source, to: destination)

        // 保留原文件的修改时间
        try preserveModificationDate(from: source, to: destination)
    }

    /// 安全地移动文件，如果目标存在则先删除
    /// - Parameters:
    ///   - source: 源文件 URL
    ///   - destination: 目标文件 URL
    /// - Throws: 文件操作错误
    func safeMoveItem(at source: URL, to destination: URL) throws {
        // 如果目标已存在，先删除
        if fileExists(atPath: destination.path) {
            try removeItem(at: destination)
        }

        // 确保目标目录存在
        let destinationDir = destination.deletingLastPathComponent()
        if !fileExists(atPath: destinationDir.path) {
            try createDirectory(at: destinationDir, withIntermediateDirectories: true)
        }

        // 移动文件
        try moveItem(at: source, to: destination)
    }

    /// 保留文件的修改时间
    /// - Parameters:
    ///   - source: 源文件 URL
    ///   - destination: 目标文件 URL
    /// - Throws: 文件操作错误
    func preserveModificationDate(from source: URL, to destination: URL) throws {
        let sourceAttributes = try attributesOfItem(atPath: source.path)
        guard let modificationDate = sourceAttributes[.modificationDate] as? Date else {
            return
        }

        try setAttributes([.modificationDate: modificationDate], ofItemAtPath: destination.path)
    }

    /// 获取目录大小（递归计算）
    /// - Parameter url: 目录 URL
    /// - Returns: 总大小（字节）
    func directorySize(at url: URL) throws -> Int64 {
        guard let enumerator = enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])

            // 跳过目录，只计算文件大小
            if resourceValues.isDirectory == true {
                continue
            }

            totalSize += Int64(resourceValues.fileSize ?? 0)
        }

        return totalSize
    }

    /// 获取目录中的文件数量（递归）
    /// - Parameter url: 目录 URL
    /// - Returns: 文件数量
    func fileCount(at url: URL) throws -> Int {
        guard let enumerator = enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var count = 0

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])

            // 只计算文件，不计算目录
            if resourceValues.isDirectory == false {
                count += 1
            }
        }

        return count
    }

    /// 检查路径是否为目录
    /// - Parameter path: 文件路径
    /// - Returns: 是否为目录
    func isDirectory(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    /// 获取可用磁盘空间
    /// - Parameter path: 路径
    /// - Returns: 可用空间（字节）
    func availableDiskSpace(atPath path: String) throws -> Int64 {
        let attributes = try attributesOfFileSystem(forPath: path)
        guard let freeSize = attributes[.systemFreeSize] as? NSNumber else {
            throw FileManagerError.cannotGetDiskSpace
        }
        return freeSize.int64Value
    }

    /// 检查磁盘空间是否足够
    /// - Parameters:
    ///   - path: 路径
    ///   - requiredSpace: 需要的空间（字节）
    /// - Returns: 是否有足够空间
    func hasEnoughDiskSpace(atPath path: String, requiredSpace: Int64) -> Bool {
        guard let availableSpace = try? availableDiskSpace(atPath: path) else {
            return false
        }
        // 保留 100MB 的缓冲空间
        let buffer: Int64 = 100 * 1024 * 1024
        return availableSpace > (requiredSpace + buffer)
    }

    /// 递归获取目录中的所有文件
    /// - Parameters:
    ///   - url: 目录 URL
    ///   - includeHidden: 是否包含隐藏文件
    /// - Returns: 文件 URL 数组
    func recursiveContents(
        of url: URL,
        includeHidden: Bool = false
    ) throws -> [URL] {
        let options: FileManager.DirectoryEnumerationOptions = includeHidden ? [] : [.skipsHiddenFiles]

        guard let enumerator = enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: options
        ) else {
            return []
        }

        var files: [URL] = []

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])

            // 只返回文件，不包括目录
            if resourceValues.isDirectory == false {
                files.append(fileURL)
            }
        }

        return files
    }

    /// 比较两个文件是否相同（基于内容）
    /// - Parameters:
    ///   - url1: 第一个文件 URL
    ///   - url2: 第二个文件 URL
    /// - Returns: 是否相同
    func contentsEqual(atPath url1: URL, andPath url2: URL) -> Bool {
        contentsEqual(atPath: url1.path, andPath: url2.path)
    }

    /// 创建备份文件
    /// - Parameter url: 原文件 URL
    /// - Returns: 备份文件 URL
    @discardableResult
    func createBackup(of url: URL) throws -> URL {
        let timestamp = Date().formatted(with: "yyyyMMdd_HHmmss")
        let backupName = "\(url.deletingPathExtension().lastPathComponent)_backup_\(timestamp).\(url.pathExtension)"
        let backupURL = url.deletingLastPathComponent().appendingPathComponent(backupName)

        try copyItem(at: url, to: backupURL)
        return backupURL
    }

    /// 清理旧的备份文件
    /// - Parameters:
    ///   - directory: 目录 URL
    ///   - olderThan: 删除早于指定天数的备份
    func cleanupBackups(in directory: URL, olderThan days: Int) throws {
        let cutoffDate = Date().addingDays(-days)
        let contents = try contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])

        for url in contents {
            if url.lastPathComponent.contains("_backup_") {
                let attributes = try url.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = attributes.creationDate,
                   creationDate < cutoffDate {
                    try removeItem(at: url)
                }
            }
        }
    }
}

// MARK: - FileManager Error
enum FileManagerError: Error, LocalizedError {
    case cannotGetDiskSpace
    case insufficientDiskSpace
    case pathNotFound
    case notADirectory

    var errorDescription: String? {
        switch self {
        case .cannotGetDiskSpace:
            return "无法获取磁盘空间信息"
        case .insufficientDiskSpace:
            return "磁盘空间不足"
        case .pathNotFound:
            return "路径不存在"
        case .notADirectory:
            return "不是一个有效的目录"
        }
    }
}

// MARK: - Security Scoped Bookmark
extension FileManager {
    /// 创建安全范围书签
    /// - Parameter url: 文件或目录 URL
    /// - Returns: 书签数据
    func createSecurityScopedBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// 从安全范围书签恢复 URL
    /// - Parameter bookmarkData: 书签数据
    /// - Returns: URL
    func resolveSecurityScopedBookmark(_ bookmarkData: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            // 书签已过期，需要重新创建
            throw BookmarkError.staleBookmark
        }

        return url
    }
}

// MARK: - Bookmark Error
enum BookmarkError: Error, LocalizedError {
    case staleBookmark
    case invalidBookmark

    var errorDescription: String? {
        switch self {
        case .staleBookmark:
            return "书签已过期，需要重新授权"
        case .invalidBookmark:
            return "无效的书签数据"
        }
    }
}
