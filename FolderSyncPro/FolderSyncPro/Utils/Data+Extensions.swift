//
//  Data+Extensions.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation
import CryptoKit

extension Data {
    /// 计算 MD5 哈希值
    var md5Hash: String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    /// 计算 SHA256 哈希值
    var sha256Hash: String {
        let digest = SHA256.hash(data: self)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    /// 以十六进制字符串表示
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }

    /// 从十六进制字符串创建 Data
    /// - Parameter hexString: 十六进制字符串
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)

        for i in 0..<length {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]

            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }

        self = data
    }

    /// 格式化为人类可读的字节大小
    var formattedByteCount: String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
}

// MARK: - File Hashing Utilities
extension Data {
    /// 从文件 URL 计算 MD5 哈希值
    /// - Parameter url: 文件 URL
    /// - Returns: MD5 哈希值字符串
    static func md5Hash(of url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.md5Hash
    }

    /// 从文件 URL 计算 SHA256 哈希值
    /// - Parameter url: 文件 URL
    /// - Returns: SHA256 哈希值字符串
    static func sha256Hash(of url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.sha256Hash
    }

    /// 分块计算大文件的 SHA256 哈希值（用于大文件，避免内存占用过高）
    /// - Parameters:
    ///   - url: 文件 URL
    ///   - chunkSize: 每次读取的块大小（默认 4MB）
    /// - Returns: SHA256 哈希值字符串
    static func sha256HashForLargeFile(
        of url: URL,
        chunkSize: Int = 4 * 1024 * 1024
    ) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }

        var hasher = SHA256()

        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: chunkSize)
            if !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    /// 分块计算大文件的 MD5 哈希值（用于大文件，避免内存占用过高）
    /// - Parameters:
    ///   - url: 文件 URL
    ///   - chunkSize: 每次读取的块大小（默认 4MB）
    /// - Returns: MD5 哈希值字符串
    static func md5HashForLargeFile(
        of url: URL,
        chunkSize: Int = 4 * 1024 * 1024
    ) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }

        var hasher = Insecure.MD5()

        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: chunkSize)
            if !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - Data Compression (Optional)
extension Data {
    /// 压缩数据
    func compressed() throws -> Data {
        return try (self as NSData).compressed(using: .lzfse) as Data
    }

    /// 解压数据
    func decompressed() throws -> Data {
        return try (self as NSData).decompressed(using: .lzfse) as Data
    }
}
