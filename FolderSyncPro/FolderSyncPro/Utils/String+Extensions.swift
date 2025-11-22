//
//  String+Extensions.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation

extension String {
    /// 检查字符串是否匹配通配符模式
    /// - Parameter pattern: 通配符模式，支持 * 和 ?
    /// - Returns: 是否匹配
    func matchesPattern(_ pattern: String) -> Bool {
        // 转换通配符模式为正则表达式
        var regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")

        // 如果模式以 / 结尾，表示匹配目录
        if pattern.hasSuffix("/") {
            regexPattern = "^" + regexPattern
        } else {
            // 完全匹配或路径匹配
            regexPattern = "(^|\\/)" + regexPattern + "$"
        }

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return false
        }

        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }

    /// 从路径中提取文件扩展名
    var fileExtension: String {
        (self as NSString).pathExtension
    }

    /// 从路径中提取文件名（不含扩展名）
    var fileNameWithoutExtension: String {
        (self as NSString).deletingPathExtension.components(separatedBy: "/").last ?? ""
    }

    /// 从路径中提取最后一个路径组件
    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }

    /// 标准化路径（移除末尾的斜杠等）
    var normalizedPath: String {
        var path = self
        // 移除末尾的斜杠
        while path.hasSuffix("/") && path.count > 1 {
            path = String(path.dropLast())
        }
        // 展开波浪号
        path = (path as NSString).expandingTildeInPath
        // 标准化路径
        path = (path as NSString).standardizingPath
        return path
    }

    /// 检查路径是否为隐藏文件
    var isHiddenFile: Bool {
        lastPathComponent.hasPrefix(".")
    }

    /// 将字符串转换为 URL
    var fileURL: URL? {
        URL(fileURLWithPath: self)
    }

    /// 安全地将路径组件追加到路径
    /// - Parameter component: 要追加的路径组件
    /// - Returns: 新的路径
    func appendingPathComponent(_ component: String) -> String {
        (self as NSString).appendingPathComponent(component)
    }

    /// 删除路径扩展名
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    /// 删除最后一个路径组件
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    /// 截断字符串到指定长度，并添加省略号
    /// - Parameters:
    ///   - length: 最大长度
    ///   - trailing: 省略号字符串
    /// - Returns: 截断后的字符串
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }

    /// 移除字符串中的空白字符和换行符
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 检查字符串是否为空或只包含空白字符
    var isBlank: Bool {
        trimmed.isEmpty
    }
}

// MARK: - Path Utilities
extension String {
    /// 获取相对于基础路径的相对路径
    /// - Parameter basePath: 基础路径
    /// - Returns: 相对路径
    func relativePath(from basePath: String) -> String {
        let normalizedSelf = self.normalizedPath
        let normalizedBase = basePath.normalizedPath

        guard normalizedSelf.hasPrefix(normalizedBase) else {
            return normalizedSelf
        }

        var relativePath = normalizedSelf.replacingOccurrences(
            of: normalizedBase,
            with: ""
        )

        // 移除开头的斜杠
        if relativePath.hasPrefix("/") {
            relativePath = String(relativePath.dropFirst())
        }

        return relativePath
    }

    /// 检查路径是否在另一个路径下
    /// - Parameter basePath: 基础路径
    /// - Returns: 是否在基础路径下
    func isSubpath(of basePath: String) -> Bool {
        let normalizedSelf = self.normalizedPath
        let normalizedBase = basePath.normalizedPath
        return normalizedSelf.hasPrefix(normalizedBase + "/") || normalizedSelf == normalizedBase
    }
}

// MARK: - Validation
extension String {
    /// 验证路径是否有效
    var isValidPath: Bool {
        // 基本验证：不为空，不包含非法字符
        guard !self.isEmpty else { return false }

        // macOS 文件系统不允许的字符（主要是冒号和 null）
        let invalidCharacters = CharacterSet(charactersIn: ":\0")
        return self.rangeOfCharacter(from: invalidCharacters) == nil
    }

    /// 验证是否为有效的文件名
    var isValidFileName: Bool {
        guard !self.isEmpty else { return false }
        guard self != "." && self != ".." else { return false }

        // 不允许包含路径分隔符
        let invalidCharacters = CharacterSet(charactersIn: "/:\0")
        return self.rangeOfCharacter(from: invalidCharacters) == nil
    }
}
