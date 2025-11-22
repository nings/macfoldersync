//
//  FileItem.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation

/// 文件状态枚举
enum FileStatus: String, Codable {
    case added = "新增"
    case modified = "修改"
    case deleted = "删除"
    case unchanged = "未变化"
    case conflict = "冲突"
}

/// 文件位置枚举
enum FileLocation: String, Codable {
    case source = "源文件夹"
    case target = "目标文件夹"
    case both = "两侧都有"
}

/// 文件项数据模型
struct FileItem: Identifiable, Codable {
    // MARK: - Properties

    /// 唯一标识符
    let id: UUID

    /// 相对路径（相对于源或目标文件夹的路径）
    let relativePath: String

    /// 文件名
    let fileName: String

    /// 完整路径
    let fullPath: String

    /// 文件大小（字节）
    let fileSize: Int64

    /// 修改时间
    let modificationDate: Date

    /// 创建时间
    let creationDate: Date

    /// 文件状态
    var status: FileStatus

    /// 文件位置
    let location: FileLocation

    /// 是否为目录
    let isDirectory: Bool

    /// MD5 校验和（可选）
    var md5Checksum: String?

    /// SHA256 校验和（可选）
    var sha256Checksum: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        relativePath: String,
        fileName: String,
        fullPath: String,
        fileSize: Int64,
        modificationDate: Date,
        creationDate: Date,
        status: FileStatus = .unchanged,
        location: FileLocation,
        isDirectory: Bool,
        md5Checksum: String? = nil,
        sha256Checksum: String? = nil
    ) {
        self.id = id
        self.relativePath = relativePath
        self.fileName = fileName
        self.fullPath = fullPath
        self.fileSize = fileSize
        self.modificationDate = modificationDate
        self.creationDate = creationDate
        self.status = status
        self.location = location
        self.isDirectory = isDirectory
        self.md5Checksum = md5Checksum
        self.sha256Checksum = sha256Checksum
    }

    // MARK: - Static Factory Methods

    /// 从 URL 创建文件项
    static func from(url: URL, baseURL: URL, location: FileLocation) throws -> FileItem {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        guard let fileSize = attributes[.size] as? Int64,
              let modificationDate = attributes[.modificationDate] as? Date,
              let creationDate = attributes[.creationDate] as? Date else {
            throw FileItemError.invalidAttributes
        }

        let relativePath = url.path.replacingOccurrences(of: baseURL.path + "/", with: "")

        return FileItem(
            relativePath: relativePath,
            fileName: url.lastPathComponent,
            fullPath: url.path,
            fileSize: fileSize,
            modificationDate: modificationDate,
            creationDate: creationDate,
            location: location,
            isDirectory: url.hasDirectoryPath
        )
    }

    // MARK: - Methods

    /// 计算文件的 MD5 校验和
    mutating func calculateMD5() throws {
        guard !isDirectory else { return }
        let url = URL(fileURLWithPath: fullPath)
        self.md5Checksum = try FileChecksumCalculator.md5(for: url)
    }

    /// 计算文件的 SHA256 校验和
    mutating func calculateSHA256() throws {
        guard !isDirectory else { return }
        let url = URL(fileURLWithPath: fullPath)
        self.sha256Checksum = try FileChecksumCalculator.sha256(for: url)
    }

    /// 比较两个文件项
    static func compare(_ source: FileItem, _ target: FileItem) -> ComparisonResult {
        if source.modificationDate > target.modificationDate {
            return .orderedDescending // source 更新
        } else if source.modificationDate < target.modificationDate {
            return .orderedAscending // target 更新
        } else {
            return .orderedSame // 相同
        }
    }

    /// 获取格式化的文件大小
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - FileItem Error
enum FileItemError: Error {
    case invalidAttributes
    case checksumCalculationFailed
    case fileNotFound
}

// MARK: - Hashable & Equatable
extension FileItem: Hashable, Equatable {
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.relativePath == rhs.relativePath && lhs.location == rhs.location
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(relativePath)
        hasher.combine(location)
    }
}

// MARK: - CustomStringConvertible
extension FileItem: CustomStringConvertible {
    var description: String {
        """
        FileItem(
            path: \(relativePath),
            size: \(formattedFileSize),
            modified: \(modificationDate),
            status: \(status.rawValue)
        )
        """
    }
}

// MARK: - File Checksum Calculator
struct FileChecksumCalculator {
    /// 计算文件的 MD5 校验和
    static func md5(for url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.md5Hash
    }

    /// 计算文件的 SHA256 校验和
    static func sha256(for url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.sha256Hash
    }
}
