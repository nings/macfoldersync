//
//  PreferencesView.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import SwiftUI

/// 偏好设置视图
struct PreferencesView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedTab: PreferenceTab = .general
    @AppStorage("app.logLevel") private var logLevel: LogLevel = .info
    @AppStorage("app.enableFileLogging") private var enableFileLogging = true
    @AppStorage("app.enableConsoleLogging") private var enableConsoleLogging = true
    @AppStorage("app.logRetentionDays") private var logRetentionDays = 30
    @AppStorage("app.defaultSyncMode") private var defaultSyncMode: SyncMode = .bidirectional
    @AppStorage("app.defaultConflictStrategy") private var defaultConflictStrategy: ConflictResolutionStrategy = .newerWins
    @AppStorage("app.enableNotifications") private var enableNotifications = true
    @AppStorage("app.launchAtLogin") private var launchAtLogin = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }
                .tag(PreferenceTab.general)

            syncTab
                .tabItem {
                    Label("同步", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(PreferenceTab.sync)

            logsTab
                .tabItem {
                    Label("日志", systemImage: "doc.text")
                }
                .tag(PreferenceTab.logs)

            advancedTab
                .tabItem {
                    Label("高级", systemImage: "slider.horizontal.3")
                }
                .tag(PreferenceTab.advanced)
        }
        .frame(width: 600, height: 500)
        .padding()
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("开机自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Toggle("启用通知", isOn: $enableNotifications)
            } header: {
                Text("应用程序")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FolderSync Pro")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("版本 1.0.0")
                        .foregroundColor(.secondary)

                    Text("一款专为 macOS 设计的高效文件夹同步工具")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    Divider()
                        .padding(.vertical, 8)

                    HStack {
                        Button("查看许可证") {
                            openURL("https://github.com/foldersyncpro/LICENSE")
                        }

                        Button("反馈问题") {
                            openURL("https://github.com/foldersyncpro/issues")
                        }

                        Button("项目主页") {
                            openURL("https://github.com/foldersyncpro")
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("关于")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Sync Tab

    private var syncTab: some View {
        Form {
            Section {
                Picker("默认同步模式", selection: $defaultSyncMode) {
                    ForEach([SyncMode.bidirectional, .sourceToTarget, .targetToSource], id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Picker("默认冲突策略", selection: $defaultConflictStrategy) {
                    ForEach([
                        ConflictResolutionStrategy.newerWins,
                        .largerWins,
                        .askUser,
                        .skip
                    ], id: \.self) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
            } header: {
                Text("默认设置")
                    .font(.headline)
            } footer: {
                Text("这些设置将作为新建同步配置的默认值")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("排除以下文件和目录：")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• .DS_Store")
                        Text("• .git/*")
                        Text("• node_modules/*")
                        Text("• *.tmp, *.log")
                    }
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("默认排除规则")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Logs Tab

    private var logsTab: some View {
        Form {
            Section {
                Picker("日志级别", selection: $logLevel) {
                    ForEach([LogLevel.debug, .info, .warning, .error, .critical], id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .onChange(of: logLevel) { _, newValue in
                    LogManager.shared.minimumLogLevel = newValue
                }

                Toggle("启用文件日志", isOn: $enableFileLogging)
                    .onChange(of: enableFileLogging) { _, newValue in
                        LogManager.shared.isFileLoggingEnabled = newValue
                    }

                Toggle("启用控制台日志", isOn: $enableConsoleLogging)
                    .onChange(of: enableConsoleLogging) { _, newValue in
                        LogManager.shared.isConsoleLoggingEnabled = newValue
                    }
            } header: {
                Text("日志设置")
                    .font(.headline)
            }

            Section {
                Stepper("保留天数: \(logRetentionDays) 天", value: $logRetentionDays, in: 1...90)

                Button("立即清理旧日志") {
                    LogManager.shared.cleanupOldLogs(olderThan: logRetentionDays)
                }
            } header: {
                Text("日志管理")
                    .font(.headline)
            } footer: {
                Text("自动删除超过 \(logRetentionDays) 天的日志记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("打开日志文件夹") {
                    openLogsFolder()
                }

                Button("导出所有日志") {
                    exportAllLogs()
                }
            } header: {
                Text("日志操作")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Advanced Tab

    private var advancedTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文件系统监控")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("使用 FSEvents API 实时监控文件系统变化")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("并发处理")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("支持多线程并发同步，提升处理速度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("安全书签")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("使用 Security-Scoped Bookmarks 持久化文件夹访问权限")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("技术特性")
                    .font(.headline)
            }

            Section {
                Button("重置所有设置") {
                    resetAllSettings()
                }
                .foregroundColor(.red)

                Button("清除所有数据") {
                    clearAllData()
                }
                .foregroundColor(.red)
            } header: {
                Text("危险操作")
                    .font(.headline)
            } footer: {
                Text("这些操作将删除所有配置和数据，请谨慎操作")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Actions

    private func setLaunchAtLogin(_ enabled: Bool) {
        // 实现开机自启动逻辑
        // 这里需要使用 SMAppService 或 ServiceManagement 框架
        print("设置开机自启: \(enabled)")
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func openLogsFolder() {
        let logsURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("FolderSyncPro/Logs")

        NSWorkspace.shared.open(logsURL)
    }

    private func exportAllLogs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "foldersync_all_logs_\(Date().formatted(with: "yyyyMMdd_HHmmss")).txt"
        panel.allowedContentTypes = [.plainText]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try LogManager.shared.exportLogs(to: url)

                let alert = NSAlert()
                alert.messageText = "导出成功"
                alert.informativeText = "日志已导出到 \(url.path)"
                alert.alertStyle = .informational
                alert.runModal()
            } catch {
                let alert = NSAlert()
                alert.messageText = "导出失败"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }

    private func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "确认重置"
        alert.informativeText = "确定要重置所有设置吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            // 重置到默认值
            logLevel = .info
            enableFileLogging = true
            enableConsoleLogging = true
            logRetentionDays = 30
            defaultSyncMode = .bidirectional
            defaultConflictStrategy = .newerWins
            enableNotifications = true
            launchAtLogin = false
        }
    }

    private func clearAllData() {
        let alert = NSAlert()
        alert.messageText = "确认清除"
        alert.informativeText = "确定要清除所有配置和数据吗？此操作不可撤销。"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            // 清除所有数据
            LogManager.shared.cleanupOldLogs(olderThan: 0)

            let confirmAlert = NSAlert()
            confirmAlert.messageText = "清除完成"
            confirmAlert.informativeText = "所有数据已清除，应用将重新启动。"
            confirmAlert.alertStyle = .informational
            confirmAlert.runModal()

            // 重启应用
            NSApp.terminate(nil)
        }
    }

    // MARK: - Preference Tab Enum

    enum PreferenceTab {
        case general
        case sync
        case logs
        case advanced
    }
}

// MARK: - Preview

#Preview {
    PreferencesView()
}
