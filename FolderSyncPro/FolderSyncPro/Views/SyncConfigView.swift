//
//  SyncConfigView.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import SwiftUI

/// 同步配置详情视图
struct SyncConfigView: View {
    // MARK: - Properties

    let configuration: SyncConfiguration

    @ObservedObject var syncEngine: SyncEngine
    @ObservedObject var fileMonitor: FileMonitor

    // MARK: - State

    @State private var selectedTab: Tab = .overview
    @State private var showingSyncProgress = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Tab View
            TabView(selection: $selectedTab) {
                overviewTab
                    .tabItem {
                        Label("概览", systemImage: "info.circle")
                    }
                    .tag(Tab.overview)

                LogView(configurationId: configuration.id)
                    .tabItem {
                        Label("日志", systemImage: "doc.text")
                    }
                    .tag(Tab.logs)

                settingsTab
                    .tabItem {
                        Label("设置", systemImage: "gearshape")
                    }
                    .tag(Tab.settings)
            }
        }
        .sheet(isPresented: $showingSyncProgress) {
            SyncProgressView(
                progress: syncEngine.progress,
                status: syncEngine.status
            )
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(configuration.name)
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 16) {
                    Label(configuration.syncMode.rawValue, systemImage: "arrow.left.arrow.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let lastSync = configuration.lastSyncedAt {
                        Label("最后同步: \(lastSync.relativeDescription)", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Sync Button
            syncButton
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Sync Button

    private var syncButton: some View {
        HStack(spacing: 12) {
            if syncEngine.status != .idle {
                statusBadge
            }

            Button(action: performSync) {
                HStack {
                    Image(systemName: syncButtonIcon)
                    Text(syncButtonTitle)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(syncEngine.status != .idle && syncEngine.status != .completed)
        }
    }

    private var syncButtonTitle: String {
        switch syncEngine.status {
        case .idle, .completed:
            return "开始同步"
        case .scanning:
            return "扫描中..."
        case .syncing:
            return "同步中..."
        case .paused:
            return "已暂停"
        case .error:
            return "错误"
        }
    }

    private var syncButtonIcon: String {
        switch syncEngine.status {
        case .idle, .completed:
            return "arrow.triangle.2.circlepath"
        case .scanning, .syncing:
            return "hourglass"
        case .paused:
            return "pause.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(syncEngine.status.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch syncEngine.status {
        case .idle, .completed:
            return .green
        case .scanning, .syncing:
            return .blue
        case .paused:
            return .orange
        case .error:
            return .red
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Paths Section
                pathsSection

                // Statistics Section
                statisticsSection

                // Progress Section
                if syncEngine.status != .idle && syncEngine.status != .completed {
                    progressSection
                }
            }
            .padding()
        }
    }

    private var pathsSection: some View {
        GroupBox("同步路径") {
            VStack(spacing: 12) {
                PathRow(
                    label: "源文件夹",
                    path: configuration.sourcePath,
                    icon: "folder"
                )

                Divider()

                PathRow(
                    label: "目标文件夹",
                    path: configuration.targetPath,
                    icon: "folder.fill"
                )
            }
            .padding()
        }
    }

    private var statisticsSection: some View {
        GroupBox("统计信息") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "源文件数",
                    value: "计算中...",
                    icon: "doc.on.doc",
                    color: .blue
                )

                StatCard(
                    title: "目标文件数",
                    value: "计算中...",
                    icon: "doc.fill",
                    color: .green
                )

                StatCard(
                    title: "同步次数",
                    value: "-",
                    icon: "arrow.triangle.2.circlepath",
                    color: .purple
                )
            }
            .padding()
        }
    }

    private var progressSection: some View {
        GroupBox("同步进度") {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: syncEngine.progress.percentage, total: 100) {
                    HStack {
                        Text("进度")
                        Spacer()
                        Text(syncEngine.progress.formattedProgress)
                            .foregroundColor(.secondary)
                    }
                }

                if !syncEngine.progress.currentFile.isEmpty {
                    Text("当前: \(syncEngine.progress.currentFile)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if syncEngine.progress.errors > 0 {
                    Label("\(syncEngine.progress.errors) 个错误", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        Form {
            Section("基本设置") {
                TextField("配置名称", text: .constant(configuration.name))
                    .disabled(true)

                Picker("同步模式", selection: .constant(configuration.syncMode)) {
                    ForEach([SyncMode.bidirectional, .sourceToTarget, .targetToSource], id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .disabled(true)

                Picker("冲突策略", selection: .constant(configuration.conflictStrategy)) {
                    ForEach([
                        ConflictResolutionStrategy.newerWins,
                        .largerWins,
                        .askUser,
                        .skip
                    ], id: \.self) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
                .disabled(true)
            }

            Section("高级设置") {
                Toggle("启用实时监控", isOn: .constant(configuration.isRealtimeMonitorEnabled))
                    .disabled(true)

                Toggle("验证文件完整性", isOn: .constant(configuration.verifyFileIntegrity))
                    .disabled(true)

                Stepper("最大并发数: \(configuration.maxConcurrentOperations)",
                       value: .constant(configuration.maxConcurrentOperations),
                       in: 1...10)
                    .disabled(true)
            }

            Section("过滤规则") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("排除模式:")
                        .font(.headline)

                    ForEach(configuration.excludePatterns, id: \.self) { pattern in
                        Text("• \(pattern)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Actions

    private func performSync() {
        Task {
            showingSyncProgress = true
            _ = await syncEngine.startSync(configuration: configuration)
            showingSyncProgress = false
        }
    }

    // MARK: - Tab Enum

    enum Tab {
        case overview
        case logs
        case settings
    }
}

// MARK: - Supporting Views

struct PathRow: View {
    let label: String
    let path: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)

            Text(path)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button("打开") {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }
            .buttonStyle(.borderless)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct SyncProgressView: View {
    let progress: SyncProgress
    let status: SyncStatus

    var body: some View {
        VStack(spacing: 20) {
            Text("同步进度")
                .font(.title)
                .fontWeight(.bold)

            ProgressView(value: progress.percentage, total: 100) {
                Text(progress.formattedProgress)
            }
            .progressViewStyle(.linear)

            if !progress.currentFile.isEmpty {
                Text("当前文件: \(progress.currentFile)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(status.rawValue)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(width: 400, height: 200)
        .padding()
    }
}
