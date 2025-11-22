# FolderSync Pro - Xcode 项目设置指南

## 🚨 问题说明

Xcode 项目文件 (`project.pbxproj`) 格式非常复杂，手动创建容易导致解析错误。正确的做法是在 Xcode 中创建项目，然后导入现有代码文件。

---

## ✅ 解决方案：在 Xcode 中创建项目

### 步骤 1：创建新的 macOS App 项目

1. 打开 Xcode
2. 选择 **File → New → Project** (或按 `⌘ + Shift + N`)
3. 选择 **macOS → App**
4. 点击 **Next**

### 步骤 2：配置项目信息

填写以下信息：

| 字段 | 值 |
|------|-----|
| **Product Name** | FolderSyncPro |
| **Team** | 选择你的开发团队 |
| **Organization Identifier** | com.foldersyncpro |
| **Bundle Identifier** | com.foldersyncpro.FolderSyncPro |
| **Interface** | SwiftUI |
| **Language** | Swift |
| **Storage** | SwiftData |
| **Include Tests** | ✅ 勾选 |

点击 **Next**

### 步骤 3：选择保存位置

⚠️ **重要**：不要保存在现有的 `FolderSyncPro` 目录中！

1. 选择临时位置（如桌面）
2. 点击 **Create**

### 步骤 4：删除默认文件

Xcode 会创建一些默认文件，我们需要删除它们：

在左侧项目导航器中，**右键点击**以下文件并选择 **Delete → Move to Trash**：

- `FolderSyncProApp.swift` (我们有自己的版本)
- `ContentView.swift`
- `Item.swift`

**保留**：
- `Assets.xcassets`
- `FolderSyncPro.entitlements`
- `Preview Content` 文件夹

### 步骤 5：导入现有代码文件

#### 方法 A：使用 Finder 拖拽（推荐）

1. 在 Finder 中打开 `macfoldersync/FolderSyncPro/FolderSyncPro/` 目录
2. 选中所有文件夹：`App`、`Models`、`Services`、`Utils`、`Views`
3. 拖拽到 Xcode 左侧项目导航器的 **FolderSyncPro** 组中
4. 在弹出对话框中：
   - ✅ 勾选 **Copy items if needed**
   - ✅ 勾选 **Create groups**
   - ✅ 确保 **FolderSyncPro** target 被勾选
5. 点击 **Finish**

#### 方法 B：手动添加文件

右键点击 **FolderSyncPro** 组 → **Add Files to "FolderSyncPro"...**

重复以下操作，逐个添加文件夹：
1. 选择 `macfoldersync/FolderSyncPro/FolderSyncPro/App` 文件夹
2. ✅ 勾选 **Copy items if needed**
3. ✅ 勾选 **Create groups**
4. 点击 **Add**

对以下文件夹重复上述操作：
- `Models`
- `Services`
- `Utils`
- `Views`

### 步骤 6：配置资源文件

#### 替换 Assets

1. 删除默认的 `Assets.xcassets`
2. 从 `macfoldersync/FolderSyncPro/FolderSyncPro/Resources/` 复制我们的 `Assets.xcassets`
3. 拖拽到 Xcode 项目中

#### 更新 Entitlements

1. 在 Xcode 中打开 `FolderSyncPro.entitlements`
2. 替换为以下内容：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>com.apple.security.files.bookmarks.app-scope</key>
	<true/>
	<key>com.apple.security.files.bookmarks.document-scope</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

### 步骤 7：配置项目设置

1. 在左侧选择项目文件（蓝色图标）
2. 选择 **FolderSyncPro** target
3. 在 **General** 标签页：
   - **Minimum Deployments**: macOS 12.0
   - **Bundle Identifier**: com.foldersyncpro.FolderSyncPro

4. 在 **Signing & Capabilities** 标签页：
   - 选择你的开发团队
   - ✅ 确保 **Hardened Runtime** 已启用
   - ✅ 确保 **App Sandbox** 已添加

5. 在 **Info** 标签页，添加以下权限描述：

| Key | Type | Value |
|-----|------|-------|
| Privacy - Desktop Folder Usage Description | String | FolderSync Pro 需要访问桌面文件夹来进行文件同步。 |
| Privacy - Documents Folder Usage Description | String | FolderSync Pro 需要访问文稿文件夹来进行文件同步。 |
| Privacy - Downloads Folder Usage Description | String | FolderSync Pro 需要访问下载文件夹来进行文件同步。 |

### 步骤 8：构建和运行

1. 选择 **My Mac** 作为目标设备
2. 按 `⌘ + B` 构建项目
3. 检查是否有编译错误
4. 修复任何导入或依赖问题
5. 按 `⌘ + R` 运行应用

---

## 🔧 常见编译错误修复

### 错误 1: "Cannot find type 'xxx' in scope"

**原因**: 文件没有正确添加到项目中

**解决方案**:
1. 检查文件是否在项目导航器中可见
2. 选择文件，在右侧检查器中确保 **Target Membership** 中 **FolderSyncPro** 被勾选

### 错误 2: "Missing required module 'CoreServices'"

**原因**: 框架没有链接

**解决方案**:
1. 选择项目 → FolderSyncPro target
2. **General** → **Frameworks, Libraries, and Embedded Content**
3. 点击 **+** 添加：
   - `CoreServices.framework`

### 错误 3: SwiftData 相关错误

**原因**: 需要 macOS 14.0+ 或使用旧版 API

**解决方案**:
如果你的最低部署目标是 macOS 12.0，需要修改代码使用 Core Data 而不是 SwiftData。

或者，将最低版本提升到 macOS 14.0：
- 项目设置 → General → Minimum Deployments → macOS 14.0

---

## 🎯 验证项目结构

构建成功后，你的项目结构应该是这样的：

```
FolderSyncPro
├── FolderSyncPro
│   ├── App
│   │   ├── FolderSyncProApp.swift
│   │   └── AppDelegate.swift
│   ├── Models
│   │   ├── SyncConfiguration.swift
│   │   ├── FileItem.swift
│   │   └── SyncLog.swift
│   ├── Services
│   │   ├── SyncEngine.swift
│   │   ├── FileMonitor.swift
│   │   ├── ConflictResolver.swift
│   │   └── LogManager.swift
│   ├── Utils
│   │   ├── FileManager+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── Data+Extensions.swift
│   ├── Views
│   │   ├── MainWindow.swift
│   │   ├── SyncConfigView.swift
│   │   ├── LogView.swift
│   │   └── PreferencesView.swift
│   ├── Assets.xcassets
│   └── FolderSyncPro.entitlements
├── FolderSyncProTests
└── FolderSyncProUITests
```

---

## 📝 替代方案：使用提供的脚本

我会创建一个自动化脚本来帮助你设置项目。

---

## 💡 下一步

1. 按照上述步骤在 Xcode 中创建项目
2. 导入所有代码文件
3. 构建并修复任何编译错误
4. 运行应用测试功能

如果遇到问题，请告诉我具体的错误信息，我会帮你解决！

---

## 🚀 快速开始脚本

我将在下一个回复中提供一个自动化设置脚本。
