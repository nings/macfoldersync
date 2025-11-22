//
//  LogView.swift
//  FolderSyncPro
//
//  Created by FolderSyncPro on 2025-11-22.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 日志视图
struct LogView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let configurationId: UUID?

    // MARK: - Query

    @Query private var logs: [SyncLog]

    // MARK: - State

    @State private var selectedLevel: LogLevel? = nil
    @State private var selectedOperation: SyncOperation? = nil
    @State private var searchText = ""
    @State private var showingExportDialog = false

    // MARK: - Initialization

    init(configurationId: UUID? = nil) {
        self.configurationId = configurationId

        // 构建查询谓词
        let predicate: Predicate<SyncLog>
        if let configId = configurationId {
            predicate = #Predicate { $0.configurationId == configId }
        } else {
            predicate = #Predicate { _ in true }
        }

        _logs = Query(
            filter: predicate,
            sort: [SortDescriptor(\.timestamp, order: .reverse)],
            animation: .default
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView

            Divider()

            // Logs List
            if filteredLogs.isEmpty {
                emptyStateView
            } else {
                logsListView
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("搜索日志...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Level Filter
            Menu {
                Button("全部级别") {
                    selectedLevel = nil
                }

                Divider()

                ForEach([LogLevel.debug, .info, .warning, .error, .critical], id: \.self) { level in
                    Button(level.rawValue) {
                        selectedLevel = level
                    }
                }
            } label: {
                Label(selectedLevel?.rawValue ?? "级别", systemImage: "line.3.horizontal.decrease.circle")
            }

            // Operation Filter
            Menu {
                Button("全部操作") {
                    selectedOperation = nil
                }

                Divider()

                ForEach([
                    SyncOperation.scan,
                    .copy,
                    .update,
                    .delete,
                    .conflictResolved,
                    .monitorStart,
                    .monitorStop
                ], id: \.self) { operation in
                    Button(operation.rawValue) {
                        selectedOperation = operation
                    }
                }
            } label: {
                Label(selectedOperation?.rawValue ?? "操作", systemImage: "list.bullet.circle")
            }

            // Export
            Button(action: { showingExportDialog = true }) {
                Label("导出", systemImage: "square.and.arrow.up")
            }

            // Clear
            Button(action: clearLogs) {
                Label("清空", systemImage: "trash")
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Logs List

    private var logsListView: some View {
        List {
            ForEach(filteredLogs) { log in
                LogRow(log: log)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("没有日志记录")
                .font(.title2)
                .fontWeight(.semibold)

            if !searchText.isEmpty || selectedLevel != nil || selectedOperation != nil {
                Text("尝试调整筛选条件")
                    .foregroundColor(.secondary)

                Button("清除筛选") {
                    searchText = ""
                    selectedLevel = nil
                    selectedOperation = nil
                }
                .buttonStyle(.bordered)
            } else {
                Text("开始同步后将显示日志")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtering

    private var filteredLogs: [SyncLog] {
        logs.filter { log in
            // 级别过滤
            if let level = selectedLevel, log.level != level {
                return false
            }

            // 操作过滤
            if let operation = selectedOperation, log.operation != operation {
                return false
            }

            // 搜索过滤
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return log.message.lowercased().contains(searchLower) ||
                       (log.filePath?.lowercased().contains(searchLower) ?? false)
            }

            return true
        }
    }

    // MARK: - Actions

    private func clearLogs() {
        let alert = NSAlert()
        alert.messageText = "确认清空日志"
        alert.informativeText = "此操作不可撤销，确定要清空所有日志吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清空")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            for log in logs {
                modelContext.delete(log)
            }
            try? modelContext.save()
        }
    }

    private func exportLogs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "foldersync_logs_\(Date().formatted(with: "yyyyMMdd_HHmmss")).txt"
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
}

// MARK: - Log Row

struct LogRow: View {
    let log: SyncLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Level Icon
            Image(systemName: levelIcon)
                .font(.title3)
                .foregroundColor(levelColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text(log.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(log.operation.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let duration = log.formattedDuration {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let filesProcessed = log.filesProcessed {
                        Text("\(filesProcessed) 个文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Message
                Text(log.message)
                    .font(.body)

                // File Path
                if let filePath = log.filePath {
                    Text(filePath)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                // Details
                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }

                // Bytes Processed
                if let bytes = log.formattedBytesProcessed {
                    Text("数据量: \(bytes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(rowBackground)
        .cornerRadius(8)
    }

    private var levelIcon: String {
        switch log.level {
        case .debug:
            return "ant.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }

    private var levelColor: Color {
        switch log.level {
        case .debug:
            return .gray
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        }
    }

    private var rowBackground: Color {
        switch log.level {
        case .error, .critical:
            return Color.red.opacity(0.05)
        case .warning:
            return Color.orange.opacity(0.05)
        default:
            return Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    LogView()
        .modelContainer(for: SyncLog.self)
        .frame(width: 800, height: 600)
}
