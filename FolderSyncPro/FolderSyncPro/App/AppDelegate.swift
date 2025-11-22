//
//  AppDelegate.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private let logManager = LogManager.shared

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        logManager.info("应用程序启动", operation: .scan)

        // 设置菜单栏图标
        setupStatusBarItem()

        // 请求通知权限
        requestNotificationPermission()

        // 设置应用程序外观
        setupAppearance()

        logManager.info("应用程序初始化完成", operation: .scan)
    }

    func applicationWillTerminate(_ notification: Notification) {
        logManager.info("应用程序即将退出", operation: .scan)

        // 清理资源
        cleanup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭最后一个窗口时不退出应用
        return false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Setup

    private func setupStatusBarItem() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: "FolderSync Pro")
            button.action = #selector(statusBarItemClicked)
            button.target = self
        }

        // 创建菜单
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "打开主窗口", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "偏好设置...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "关于 FolderSync Pro", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupAppearance() {
        // 设置默认窗口样式
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.logManager.info("通知权限已授予")
            } else if let error = error {
                self.logManager.error("请求通知权限失败", error: error)
            }
        }

        center.delegate = self
    }

    // MARK: - Menu Actions

    @objc private func statusBarItemClicked() {
        // 点击状态栏图标时显示菜单
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // 创建新窗口
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "FolderSync Pro",
            .applicationVersion: "1.0.0",
            .version: "1.0.0",
            .credits: NSAttributedString(string: "一款专为 macOS 设计的高效文件夹同步工具")
        ])
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Notifications

    func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logManager.error("发送通知失败", error: error)
            }
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        // 清理状态栏项
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        logManager.info("资源清理完成")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 即使应用在前台也显示通知
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 处理通知点击
        openMainWindow()
        completionHandler()
    }
}
