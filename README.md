# FolderSync Pro

一款专为 macOS 设计的高效文件夹同步工具，基于文件时间戳智能判断文件新旧，实现两个文件夹之间的双向同步。

## 功能特性

### 核心功能
- ✅ 基于修改时间戳的智能文件同步
- ✅ 支持实时监控和手动同步
- ✅ 智能冲突检测与解决策略
- ✅ 详细的同步历史记录和日志
- ✅ 多种同步模式（双向、单向）
- ✅ 文件过滤和排除规则

### 技术特性
- ✅ SwiftUI + AppKit 现代化界面
- ✅ FSEvents API 实时文件监控
- ✅ Core Data + SwiftData 数据持久化
- ✅ 多线程并发同步处理
- ✅ 完整的错误处理和恢复机制
- ✅ 沙盒环境兼容

## 系统要求

- **最低版本**: macOS 12.0 (Monterey)
- **推荐版本**: macOS 13.0+ (Ventura)
- **架构支持**: Intel x64 + Apple Silicon (Universal Binary)

## 项目结构

```
FolderSyncPro/
├── FolderSyncPro/
│   ├── App/                     # 应用程序入口
│   │   ├── FolderSyncProApp.swift
│   │   └── AppDelegate.swift
│   ├── Views/                   # 用户界面
│   │   ├── MainWindow.swift
│   │   ├── SyncConfigView.swift
│   │   ├── LogView.swift
│   │   └── PreferencesView.swift
│   ├── Models/                  # 数据模型
│   │   ├── SyncConfiguration.swift
│   │   ├── FileItem.swift
│   │   └── SyncLog.swift
│   ├── Services/                # 核心服务
│   │   ├── SyncEngine.swift
│   │   ├── FileMonitor.swift
│   │   ├── ConflictResolver.swift
│   │   └── LogManager.swift
│   ├── Utils/                   # 工具类和扩展
│   │   ├── FileManager+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── String+Extensions.swift
│   └── Resources/               # 资源文件
│       ├── Assets.xcassets
│       ├── Info.plist
│       └── FolderSyncPro.entitlements
├── FolderSyncProTests/          # 单元测试
└── FolderSyncProUITests/        # UI测试
```

## 核心组件

### 1. 同步引擎 (SyncEngine)
- 智能文件扫描和比较
- 多线程并发同步处理
- 冲突检测和解决
- 进度跟踪和状态更新

### 2. 文件监控 (FileMonitor)
- 基于 FSEvents API 的实时监控
- 智能事件过滤和去重
- 自动触发同步操作
- 资源管理和性能优化

### 3. 冲突解决器 (ConflictResolver)
- 多种冲突解决策略
- 可视化冲突对话框
- 批量冲突处理
- 用户交互式选择

### 4. 日志管理 (LogManager)
- 分级日志记录系统
- 文件和控制台双重输出
- 日志文件自动清理
- 日志导出和分析

## 同步策略

### 双向同步 (Bidirectional)
- 源文件夹和目标文件夹相互同步
- 自动检测新增、修改和删除的文件
- 基于时间戳的智能冲突解决

### 单向同步 (Unidirectional)
- **源到目标**: 只从源文件夹同步到目标文件夹
- **目标到源**: 只从目标文件夹同步到源文件夹
- 适用于备份和分发场景

## 冲突解决策略

1. **较新文件胜出**: 根据修改时间选择较新的文件
2. **较大文件胜出**: 根据文件大小选择较大的文件
3. **询问用户**: 弹出对话框让用户手动选择
4. **跳过冲突**: 保持现状，不处理冲突文件

## 过滤规则

### 排除模式
- 支持通配符匹配 (`*.tmp`, `*.log`)
- 支持路径匹配 (`node_modules/*`)
- 预设常见排除规则 (`.DS_Store`, `.git/`)

### 包含模式
- 可设置只同步特定类型的文件
- 支持多种匹配模式
- 优先级高于排除模式

## 性能优化

### 文件扫描优化
- 增量扫描，只检查变化的文件
- 多线程并发扫描，提升处理速度
- 智能缓存机制，减少重复操作

### 同步性能优化
- 并发同步操作，可配置并发数
- 大文件分块传输，支持进度显示
- 内存管理优化，避免大量文件导致的内存峰值

### 监控性能优化
- 事件延迟和合并，避免频繁触发
- 智能过滤，忽略无关事件
- 资源自动清理，防止内存泄漏

## 安全特性

### 权限管理
- 安全书签 (Security-Scoped Bookmarks) 持久化权限
- 沙盒环境完全兼容
- 最小权限原则，只请求必要权限

### 数据完整性
- MD5/SHA256 校验和验证
- 原子操作，确保文件完整性
- 自动备份机制，防止数据丢失

## 错误处理

### 错误类型
- 权限错误处理和用户引导
- 磁盘空间不足检测和提醒
- 网络错误和重试机制
- 文件锁定和占用处理

### 恢复机制
- 自动重试失败的操作
- 事务性同步，可回滚操作
- 详细错误日志，便于问题排查

## 用户界面

### 现代化设计
- SwiftUI 原生界面，支持深色模式
- 响应式布局，适配不同屏幕尺寸
- 直观的操作流程和状态显示

### 核心界面
- **主窗口**: 同步配置列表和状态监控
- **配置编辑**: 完整的同步参数设置
- **日志查看**: 详细的操作记录和过滤
- **偏好设置**: 应用程序全局设置

## 开发和构建

### 开发环境
- Xcode 15.0+
- Swift 5.8+
- macOS 12.0+ SDK

### 构建步骤
1. 克隆项目到本地
2. 使用 Xcode 打开 `FolderSyncPro.xcodeproj`
3. 选择合适的开发团队和证书
4. 编译和运行项目

### 测试
- 单元测试覆盖核心逻辑
- UI 测试验证用户交互
- 性能测试确保大规模文件处理能力

## 部署和分发

### 代码签名
- 开发者证书签名
- Hardened Runtime 加固
- 公证 (Notarization) 通过

### 分发方式
- **Mac App Store**: 符合 App Store 审核指南
- **直接分发**: DMG 安装包
- **Homebrew Cask**: 命令行安装

## 版本历史

### v1.0.0
- ✅ 基础同步功能实现
- ✅ 实时文件监控
- ✅ 冲突解决机制
- ✅ 完整的用户界面
- ✅ 日志管理系统

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 联系方式

如有问题或建议，请通过 GitHub Issues 联系。
