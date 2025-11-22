//
//  MainWindow.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import SwiftUI
import SwiftData

/// 主窗口视图
struct MainWindow: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Query

    @Query(sort: \SyncConfiguration.createdAt, order: .reverse)
    private var configurations: [SyncConfiguration]

    // MARK: - State

    @State private var selectedConfiguration: SyncConfiguration?
    @State private var showingAddConfig = false
    @State private var showingPreferences = false

    // MARK: - Services

    @StateObject private var syncEngine: SyncEngine
    @StateObject private var conflictResolver = ConflictResolver()
    @StateObject private var fileMonitor = FileMonitor()

    // MARK: - Initialization

    init() {
        let conflictResolver = ConflictResolver()
        _syncEngine = StateObject(wrappedValue: SyncEngine(conflictResolver: conflictResolver))
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            if let config = selectedConfiguration {
                SyncConfigView(
                    configuration: config,
                    syncEngine: syncEngine,
                    fileMonitor: fileMonitor
                )
            } else {
                emptyStateView
            }
        }
        .navigationTitle("FolderSync Pro")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddConfig) {
            AddConfigurationView()
        }
        .sheet(isPresented: $showingPreferences) {
            PreferencesView()
        }
    }

    // MARK: - Sidebar View

    private var sidebarView: some View {
        List(selection: $selectedConfiguration) {
            Section("同步配置") {
                ForEach(configurations) { config in
                    ConfigurationRow(configuration: config)
                        .tag(config)
                        .contextMenu {
                            configContextMenu(for: config)
                        }
                }
                .onDelete(perform: deleteConfigurations)
            }
        }
        .frame(minWidth: 250)
        .navigationTitle("配置列表")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("没有选择配置")
                .font(.title2)
                .fontWeight(.semibold)

            Text("选择一个同步配置或创建新的配置")
                .foregroundColor(.secondary)

            Button("创建新配置") {
                showingAddConfig = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: toggleSidebar) {
                Image(systemName: "sidebar.left")
            }
        }

        ToolbarItem {
            Button(action: { showingAddConfig = true }) {
                Label("添加配置", systemImage: "plus")
            }
        }

        ToolbarItem {
            Button(action: { showingPreferences = true }) {
                Label("偏好设置", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func configContextMenu(for config: SyncConfiguration) -> some View {
        Button("编辑") {
            selectedConfiguration = config
        }

        Button("复制") {
            duplicateConfiguration(config)
        }

        Divider()

        Button("删除", role: .destructive) {
            deleteConfiguration(config)
        }
    }

    // MARK: - Actions

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }

    private func deleteConfigurations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(configurations[index])
        }
        try? modelContext.save()
    }

    private func deleteConfiguration(_ config: SyncConfiguration) {
        modelContext.delete(config)
        try? modelContext.save()

        if selectedConfiguration?.id == config.id {
            selectedConfiguration = configurations.first
        }
    }

    private func duplicateConfiguration(_ config: SyncConfiguration) {
        let newConfig = SyncConfiguration(
            name: config.name + " (副本)",
            sourcePath: config.sourcePath,
            targetPath: config.targetPath,
            syncMode: config.syncMode,
            conflictStrategy: config.conflictStrategy,
            isRealtimeMonitorEnabled: config.isRealtimeMonitorEnabled,
            excludePatterns: config.excludePatterns,
            includePatterns: config.includePatterns
        )

        modelContext.insert(newConfig)
        try? modelContext.save()
    }
}

// MARK: - Configuration Row

struct ConfigurationRow: View {
    let configuration: SyncConfiguration

    var body: some View {
        HStack {
            Image(systemName: configuration.isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(configuration.isActive ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(configuration.name)
                    .font(.headline)

                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)

                    Text(configuration.syncMode.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let lastSync = configuration.lastSyncedAt {
                        Text("• 最后同步: \(lastSync.relativeDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if configuration.isRealtimeMonitorEnabled {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                    .help("实时监控已启用")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Configuration View

struct AddConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sourcePath = ""
    @State private var targetPath = ""
    @State private var sourceBookmarkData: Data?
    @State private var targetBookmarkData: Data?
    @State private var syncMode: SyncMode = .bidirectional
    @State private var conflictStrategy: ConflictResolutionStrategy = .newerWins
    @State private var isRealtimeMonitorEnabled = true

    var body: some View {
        VStack(spacing: 20) {
            Text("添加同步配置")
                .font(.title)
                .fontWeight(.bold)

            Form {
                TextField("配置名称", text: $name)

                HStack {
                    TextField("源文件夹", text: $sourcePath)
                    Button("选择...") {
                        selectFolder(for: .source)
                    }
                }

                HStack {
                    TextField("目标文件夹", text: $targetPath)
                    Button("选择...") {
                        selectFolder(for: .target)
                    }
                }

                Picker("同步模式", selection: $syncMode) {
                    ForEach([SyncMode.bidirectional, .sourceToTarget, .targetToSource], id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Picker("冲突策略", selection: $conflictStrategy) {
                    ForEach([
                        ConflictResolutionStrategy.newerWins,
                        .largerWins,
                        .askUser,
                        .skip
                    ], id: \.self) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }

                Toggle("启用实时监控", isOn: $isRealtimeMonitorEnabled)
            }
            .padding()

            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("创建") {
                    createConfiguration()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .padding()
    }

    private var isValid: Bool {
        !name.isEmpty && !sourcePath.isEmpty && !targetPath.isEmpty
    }

    private func selectFolder(for type: FolderType) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            // 保存路径
            switch type {
            case .source:
                sourcePath = url.path
            case .target:
                targetPath = url.path
            }

            // 创建并保存 security-scoped bookmark
            do {
                let bookmarkData = try FileManager.default.createSecurityScopedBookmark(for: url)
                switch type {
                case .source:
                    sourceBookmarkData = bookmarkData
                case .target:
                    targetBookmarkData = bookmarkData
                }
            } catch {
                print("创建 bookmark 失败: \(error)")
            }
        }
    }

    private func createConfiguration() {
        let config = SyncConfiguration(
            name: name,
            sourcePath: sourcePath,
            targetPath: targetPath,
            syncMode: syncMode,
            conflictStrategy: conflictStrategy,
            isRealtimeMonitorEnabled: isRealtimeMonitorEnabled
        )

        // 保存 security-scoped bookmarks
        config.sourceBookmarkData = sourceBookmarkData
        config.targetBookmarkData = targetBookmarkData

        modelContext.insert(config)
        try? modelContext.save()

        dismiss()
    }

    enum FolderType {
        case source, target
    }
}

// MARK: - Preview

#Preview {
    MainWindow()
        .modelContainer(for: [SyncConfiguration.self, SyncLog.self])
}
