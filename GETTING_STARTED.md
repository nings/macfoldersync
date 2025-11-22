# FolderSync Pro - 快速启动指南

## 🎉 欢迎使用 FolderSync Pro

这是一款专为 macOS 设计的高效文件夹同步工具，基于文件时间戳智能判断文件新旧，实现两个文件夹之间的双向同步。

---

## 📖 目录

1. [项目状态](#项目状态)
2. [快速开始](#快速开始)
3. [开发路线图](#开发路线图)
4. [如何贡献](#如何贡献)
5. [文档导航](#文档导航)

---

## 🚀 项目状态

### ✅ 已完成 (v1.0.0)

- ✅ 核心同步引擎
- ✅ 实时文件监控
- ✅ 冲突解决机制
- ✅ 完整的用户界面
- ✅ 日志管理系统
- ✅ 数据持久化

### 🔄 开发中

**当前版本**: v1.0.0
**下一版本**: v1.1.0 (菜单栏快捷操作 + 定时同步)
**预计发布**: 5-7 天后

---

## 🏃 快速开始

### 1. 环境要求

- **系统**: macOS 12.0+ (推荐 macOS 13.0+)
- **Xcode**: 15.0+
- **Swift**: 5.8+

### 2. 克隆项目

```bash
git clone https://github.com/nings/macfoldersync.git
cd macfoldersync
```

### 3. 打开项目

```bash
open FolderSyncPro/FolderSyncPro.xcodeproj
```

### 4. 构建运行

1. 在 Xcode 中选择你的开发团队
2. 按 `⌘ + B` 构建项目
3. 按 `⌘ + R` 运行应用

### 5. 创建第一个同步配置

1. 点击左上角的 **"+ 添加配置"** 按钮
2. 填写配置名称（如：文档同步）
3. 选择源文件夹和目标文件夹
4. 选择同步模式（推荐：双向同步）
5. 选择冲突策略（推荐：较新文件胜出）
6. 点击 **"创建"**

### 6. 开始同步

1. 在左侧配置列表中选择刚创建的配置
2. 点击右上角的 **"开始同步"** 按钮
3. 等待同步完成
4. 在日志标签页查看详细记录

---

## 🗺️ 开发路线图

我们规划了 4 个阶段的功能增强，详见 [ROADMAP.md](ROADMAP.md)

### 第一阶段：基础增强 (1-5 天)
- 🔲 菜单栏快捷操作
- 🔲 定时同步功能

### 第二阶段：过滤和预览 (6-13 天)
- 🔲 高级过滤规则
- 🔲 同步预览功能

### 第三阶段：网络支持 (14-18 天)
- 🔲 网络文件夹同步

### 第四阶段：质量保证 (19-25 天)
- 🔲 完整测试套件

**详细计划**: 查看 [ROADMAP.md](ROADMAP.md)

---

## 🛠️ 项目结构

```
FolderSyncPro/
├── App/                    # 应用入口
│   ├── FolderSyncProApp.swift
│   └── AppDelegate.swift
├── Models/                 # 数据模型
│   ├── SyncConfiguration.swift
│   ├── FileItem.swift
│   └── SyncLog.swift
├── Services/               # 核心服务
│   ├── SyncEngine.swift
│   ├── FileMonitor.swift
│   ├── ConflictResolver.swift
│   └── LogManager.swift
├── Views/                  # 用户界面
│   ├── MainWindow.swift
│   ├── SyncConfigView.swift
│   ├── LogView.swift
│   └── PreferencesView.swift
├── Utils/                  # 工具扩展
└── Resources/              # 资源文件
```

**详细说明**: 查看 [BUILD.md](BUILD.md)

---

## 👥 如何贡献

我们欢迎所有形式的贡献！

### 报告问题

在 [GitHub Issues](https://github.com/nings/macfoldersync/issues) 中报告 Bug 或提出功能建议。

### 提交代码

1. Fork 项目
2. 创建功能分支
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. 提交更改
   ```bash
   git commit -m 'feat: 添加某个功能'
   ```
4. 推送到分支
   ```bash
   git push origin feature/amazing-feature
   ```
5. 创建 Pull Request

### 开发规范

- 遵循 Swift 代码风格指南
- 为新功能添加测试
- 更新相关文档
- 确保所有测试通过

---

## 📚 文档导航

### 核心文档

- **[README.md](README.md)** - 项目概述和功能介绍
- **[BUILD.md](BUILD.md)** - 详细的构建和开发指南
- **[ROADMAP.md](ROADMAP.md)** - 完整的功能路线图

### 阶段计划

- **[第一阶段计划](docs/PHASE1_PLAN.md)** - 菜单栏 + 定时同步详细计划
- 第二阶段计划 - 即将推出
- 第三阶段计划 - 即将推出
- 第四阶段计划 - 即将推出

### API 文档

- 即将推出

---

## 💡 使用技巧

### 1. 选择正确的同步模式

- **双向同步**: 两个文件夹保持完全一致
- **源到目标**: 只从源同步到目标（备份场景）
- **目标到源**: 只从目标同步到源（还原场景）

### 2. 选择合适的冲突策略

- **较新文件胜出**: 根据修改时间（推荐）
- **较大文件胜出**: 根据文件大小
- **询问用户**: 手动选择（谨慎操作时）
- **跳过冲突**: 保持现状

### 3. 排除不需要的文件

默认排除规则已经包含：
- `.DS_Store`
- `.git/*`
- `node_modules/*`
- `*.tmp`
- `*.log`

你可以在配置中添加自定义排除模式。

### 4. 启用实时监控

启用后，文件变化会自动触发同步，无需手动操作。

### 5. 查看日志

遇到问题时，查看日志标签页的详细记录，可以帮助诊断问题。

---

## 🔧 故障排除

### 同步失败

1. 检查文件夹权限
2. 确保磁盘空间充足
3. 查看日志中的错误信息
4. 尝试手动重新同步

### 实时监控不工作

1. 检查是否启用了实时监控
2. 重启应用
3. 重新授权文件夹权限

### 应用崩溃

1. 查看崩溃日志
2. 在 GitHub Issues 中报告问题
3. 提供复现步骤

---

## 📞 获取帮助

- **GitHub Issues**: https://github.com/nings/macfoldersync/issues
- **项目 Wiki**: https://github.com/nings/macfoldersync/wiki
- **讨论区**: https://github.com/nings/macfoldersync/discussions

---

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 🙏 致谢

感谢所有贡献者和用户的支持！

---

## 🎯 下一步

选择你感兴趣的内容：

1. **开始使用** → 阅读 [BUILD.md](BUILD.md) 了解详细构建步骤
2. **了解路线图** → 查看 [ROADMAP.md](ROADMAP.md) 了解未来计划
3. **参与开发** → 查看 [第一阶段计划](docs/PHASE1_PLAN.md) 加入我们
4. **报告问题** → 访问 [GitHub Issues](https://github.com/nings/macfoldersync/issues)

**祝你使用愉快！** 🚀
