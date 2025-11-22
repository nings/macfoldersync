//
//  Date+Extensions.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Foundation

extension Date {
    /// 获取相对时间描述（例如：2分钟前、1小时前）
    var relativeDescription: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: self,
            to: now
        )

        if let years = components.year, years > 0 {
            return "\(years)年前"
        }
        if let months = components.month, months > 0 {
            return "\(months)个月前"
        }
        if let days = components.day, days > 0 {
            return "\(days)天前"
        }
        if let hours = components.hour, hours > 0 {
            return "\(hours)小时前"
        }
        if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分钟前"
        }
        if let seconds = components.second, seconds > 0 {
            return "\(seconds)秒前"
        }

        return "刚刚"
    }

    /// 格式化为标准日期时间字符串
    var standardFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 格式化为短日期字符串
    var shortDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 格式化为短时间字符串
    var shortTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 格式化为完整日期时间字符串
    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 自定义格式化
    /// - Parameter format: 日期格式字符串
    /// - Returns: 格式化后的字符串
    func formatted(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 检查是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 检查是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// 检查是否是本周
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// 检查是否是本月
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// 检查是否是本年
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// 获取日期的开始时间（当天0点）
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 获取日期的结束时间（当天23:59:59）
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// 添加天数
    /// - Parameter days: 要添加的天数
    /// - Returns: 新日期
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// 添加小时
    /// - Parameter hours: 要添加的小时数
    /// - Returns: 新日期
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// 添加分钟
    /// - Parameter minutes: 要添加的分钟数
    /// - Returns: 新日期
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// 计算两个日期之间的天数差异
    /// - Parameter date: 另一个日期
    /// - Returns: 天数差异
    func daysDifference(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: self)
        return components.day ?? 0
    }

    /// 计算两个日期之间的秒数差异
    /// - Parameter date: 另一个日期
    /// - Returns: 秒数差异
    func secondsDifference(from date: Date) -> TimeInterval {
        self.timeIntervalSince(date)
    }

    /// 智能格式化（根据时间自动选择格式）
    var smartFormatted: String {
        if isToday {
            return "今天 " + shortTimeFormatted
        } else if isYesterday {
            return "昨天 " + shortTimeFormatted
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE HH:mm"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: self)
        } else if isThisYear {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: self)
        } else {
            return standardFormatted
        }
    }
}

// MARK: - Comparison Utilities
extension Date {
    /// 检查是否比另一个日期更新
    /// - Parameter date: 另一个日期
    /// - Returns: 是否更新
    func isNewer(than date: Date) -> Bool {
        self > date
    }

    /// 检查是否比另一个日期更旧
    /// - Parameter date: 另一个日期
    /// - Returns: 是否更旧
    func isOlder(than date: Date) -> Bool {
        self < date
    }

    /// 检查两个日期是否在指定容差范围内相同
    /// - Parameters:
    ///   - date: 另一个日期
    ///   - tolerance: 容差（秒）
    /// - Returns: 是否在容差范围内相同
    func isEqual(to date: Date, withTolerance tolerance: TimeInterval = 1.0) -> Bool {
        abs(self.timeIntervalSince(date)) <= tolerance
    }
}
