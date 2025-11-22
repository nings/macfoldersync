# FolderSync Pro - 构建指南

## 项目结构

项目采用模块化设计，各模块职责清晰：

```
FolderSyncPro/
├── FolderSyncPro/
│   ├── App/                     # 应用程序入口
│   │   ├── FolderSyncProApp.swift    - SwiftUI App 入口
│   │   └── AppDelegate.swift         - 应用程序代理
│   ├── Models/                  # 数据模型层
│   │   ├── SyncConfiguration.swift   - 同步配置模型
│   │   ├── FileItem.swift            - 文件项模型
│   │   └── SyncLog.swift             - 同步日志模型
│   ├── Services/                # 业务逻辑层
│   │   ├── SyncEngine.swift          - 核心同步引擎
│   │   ├── FileMonitor.swift         - 文件监控服务
│   │   ├── ConflictResolver.swift    - 冲突解决器
│   │   └── LogManager.swift          - 日志管理器
│   ├── Views/                   # 用户界面层
│   │   ├── MainWindow.swift          - 主窗口
│   │   ├── SyncConfigView.swift      - 同步配置视图
│   │   ├── LogView.swift             - 日志视图
│   │   └── PreferencesView.swift     - 偏好设置视图
│   ├── Utils/                   # 工具类
│   │   ├── FileManager+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── Data+Extensions.swift
│   └── Resources/               # 资源文件
│       ├── Assets.xcassets
│       ├── Info.plist
│       └── FolderSyncPro.entitlements
└── FolderSyncPro.xcodeproj/     # Xcode 项目文件
```

## 技术栈

- **UI 框架**: SwiftUI + AppKit
- **数据持久化**: SwiftData (Core Data)
- **文件监控**: FSEvents API
- **并发处理**: Swift Concurrency (async/await)
- **加密**: CryptoKit (MD5, SHA256)
- **最低系统**: macOS 12.0 (Monterey)
- **推荐系统**: macOS 13.0+ (Ventura)

## 核心功能实现

### 1. 同步引擎 (SyncEngine)

**位置**: `Services/SyncEngine.swift`

**功能**:
- 智能文件扫描和比较
- 多线程并发同步处理
- 冲突检测和解决
- 进度跟踪和状态更新
- 支持双向和单向同步

**关键方法**:
```swift
func startSync(configuration: SyncConfiguration) async -> SyncResult
```

### 2. 文件监控 (FileMonitor)

**位置**: `Services/FileMonitor.swift`

**功能**:
- 基于 FSEvents API 的实时监控
- 智能事件过滤和去重
- 事件延迟合并（避免频繁触发）
- 自动触发同步操作

**关键方法**:
```swift
func startMonitoring(paths: [String], callback: @escaping (FileChangeEvent) -> Void)
```

### 3. 冲突解决器 (ConflictResolver)

**位置**: `Services/ConflictResolver.swift`

**功能**:
- 多种冲突解决策略（较新文件胜出、较大文件胜出、询问用户、跳过）
- 可视化冲突对话框
- 批量冲突处理

**关键方法**:
```swift
func resolve(conflict: ConflictInfo, using strategy: ConflictResolutionStrategy) async -> ConflictResolution
```

### 4. 日志管理 (LogManager)

**位置**: `Services/LogManager.swift`

**功能**:
- 分级日志记录系统（Debug, Info, Warning, Error, Critical）
- 文件和控制台双重输出
- 日志文件自动清理
- 日志导出和分析

**关键方法**:
```swift
func log(level: LogLevel, operation: SyncOperation, message: String, ...)
```

## 使用 Xcode 构建

### 1. 打开项目

```bash
cd macfoldersync
open FolderSyncPro/FolderSyncPro.xcodeproj
```

### 2. 配置签名

1. 在 Xcode 中选择项目文件
2. 选择 "Signing & Capabilities"
3. 选择你的开发团队
4. Xcode 会自动管理证书

### 3. 构建项目

- **快捷键**: `⌘ + B`
- **菜单**: Product → Build

### 4. 运行项目

- **快捷键**: `⌘ + R`
- **菜单**: Product → Run

## 使用命令行构建（可选）

如果你更喜欢使用命令行：

```bash
# 清理构建
xcodebuild clean -project FolderSyncPro/FolderSyncPro.xcodeproj -scheme FolderSyncPro

# 构建项目
xcodebuild build -project FolderSyncPro/FolderSyncPro.xcodeproj -scheme FolderSyncPro -configuration Debug

# 归档应用
xcodebuild archive -project FolderSyncPro/FolderSyncPro.xcodeproj -scheme FolderSyncPro -archivePath ./build/FolderSyncPro.xcarchive

# 导出应用
xcodebuild -exportArchive -archivePath ./build/FolderSyncPro.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
```

## 权限说明

应用需要以下权限：

1. **文件访问权限**: 读写用户选择的文件夹
2. **通知权限**: 发送同步状态通知
3. **后台运行**: 文件监控和定时同步

所有权限都在 `FolderSyncPro.entitlements` 中配置，符合 macOS 沙盒要求。

## 数据存储

- **配置数据**: 使用 SwiftData 存储在 Application Support 目录
- **日志文件**: 存储在 `~/Library/Application Support/FolderSyncPro/Logs/`
- **安全书签**: 持久化用户授权的文件夹访问权限

## 性能优化

### 文件扫描优化
- 增量扫描，只检查变化的文件
- 多线程并发扫描，提升处理速度
- 智能缓存机制，减少重复操作

### 同步性能优化
- 并发同步操作，可配置并发数（默认 4）
- 大文件分块传输，支持进度显示
- 内存管理优化，使用 `autoreleasepool` 避免内存峰值

### 监控性能优化
- 事件延迟和合并，避免频繁触发（默认 1 秒）
- 智能过滤，忽略无关事件（.DS_Store, .tmp 等）
- 资源自动清理，防止内存泄漏

## 测试

### 单元测试

```bash
xcodebuild test -project FolderSyncPro/FolderSyncPro.xcodeproj -scheme FolderSyncPro -destination 'platform=macOS'
```

### 手动测试场景

1. **基本同步测试**
   - 创建同步配置
   - 添加、修改、删除文件
   - 验证同步结果

2. **冲突处理测试**
   - 在两个文件夹同时修改同一文件
   - 验证冲突检测
   - 测试各种冲突解决策略

3. **实时监控测试**
   - 启用实时监控
   - 修改文件
   - 验证自动同步

4. **性能测试**
   - 创建大量文件（1000+）
   - 测试同步速度
   - 监控内存和 CPU 使用

## 常见问题

### Q: 为什么需要授权文件夹访问权限？

A: macOS 沙盒环境要求应用必须获得用户明确授权才能访问文件系统。应用使用安全书签（Security-Scoped Bookmarks）持久化这些权限。

### Q: 如何调整日志级别？

A: 在偏好设置中可以调整日志级别。开发时建议使用 Debug 级别，生产环境使用 Info 或 Warning 级别。

### Q: 同步失败怎么办？

A: 检查日志视图中的详细错误信息。常见原因包括：
- 磁盘空间不足
- 文件被占用
- 权限问题
- 路径不存在

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 联系方式

如有问题或建议，请通过 GitHub Issues 联系。
