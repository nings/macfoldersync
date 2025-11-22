//
//  FolderSyncProApp.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import SwiftUI
import SwiftData

@main
struct FolderSyncProApp: App {
    // MARK: - Properties

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Model Container

    let modelContainer: ModelContainer = {
        let schema = Schema([
            SyncConfiguration.self,
            SyncLog.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // 设置日志管理器的模型上下文
            Task { @MainActor in
                LogManager.shared.setup(modelContext: container.mainContext)
            }

            return container
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .modelContainer(modelContainer)
                .onAppear {
                    setupAppearance()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            appCommands
        }

        // 设置窗口
        Settings {
            PreferencesView()
        }
    }

    // MARK: - Commands

    @CommandsBuilder
    private var appCommands: some Commands {
        // 文件菜单
        CommandGroup(replacing: .newItem) {
            Button("新建同步配置...") {
                // 触发新建配置
                NotificationCenter.default.post(name: .showAddConfiguration, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        // 同步菜单
        CommandMenu("同步") {
            Button("开始同步") {
                NotificationCenter.default.post(name: .startSync, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("停止同步") {
                NotificationCenter.default.post(name: .stopSync, object: nil)
            }
            .keyboardShortcut(".", modifiers: .command)

            Divider()

            Button("查看日志") {
                NotificationCenter.default.post(name: .showLogs, object: nil)
            }
            .keyboardShortcut("l", modifiers: .command)
        }

        // 帮助菜单
        CommandGroup(replacing: .help) {
            Button("FolderSync Pro 帮助") {
                openHelp()
            }

            Button("检查更新...") {
                checkForUpdates()
            }

            Divider()

            Button("报告问题...") {
                reportIssue()
            }

            Button("访问项目主页") {
                openProjectWebsite()
            }
        }
    }

    // MARK: - Setup

    private func setupAppearance() {
        // 设置窗口外观
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        }
    }

    // MARK: - Actions

    private func openHelp() {
        if let url = URL(string: "https://github.com/foldersyncpro/wiki") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkForUpdates() {
        let alert = NSAlert()
        alert.messageText = "检查更新"
        alert.informativeText = "当前版本: 1.0.0\n您已经在使用最新版本。"
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func reportIssue() {
        if let url = URL(string: "https://github.com/foldersyncpro/issues/new") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openProjectWebsite() {
        if let url = URL(string: "https://github.com/foldersyncpro") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showAddConfiguration = Notification.Name("showAddConfiguration")
    static let startSync = Notification.Name("startSync")
    static let stopSync = Notification.Name("stopSync")
    static let showLogs = Notification.Name("showLogs")
}
