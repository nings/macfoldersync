# 常见编译错误修复指南

## ✅ 已修复的问题

### 1. Combine 框架导入错误

**错误信息**:
```
Type 'ConflictResolver' does not conform to protocol 'ObservableObject'
Initializer 'init(wrappedValue:)' is not available due to missing import of defining module 'Combine'
```

**原因**: `@Published` 和 `ObservableObject` 需要 `Combine` 框架支持。

**已修复**: 在以下文件中添加了 `import Combine`：
- ✅ Services/ConflictResolver.swift
- ✅ Services/SyncEngine.swift
- ✅ Services/FileMonitor.swift
- ✅ Services/LogManager.swift

---

## 🔧 其他可能的编译错误

### 错误 1: "Cannot find type in scope"

**可能原因**:
- 文件没有正确添加到项目
- Target Membership 未勾选

**解决方案**:
1. 在 Xcode 项目导航器中选择文件
2. 在右侧 File Inspector 中检查 **Target Membership**
3. 确保 **FolderSyncPro** 被勾选

### 错误 2: "Missing required module"

**常见缺失框架**:
- `import SwiftUI` - 用于 UI
- `import SwiftData` - 用于数据持久化
- `import Combine` - 用于响应式编程
- `import AppKit` - 用于 macOS 原生功能
- `import CoreServices` - 用于 FSEvents

**解决方案**: 在文件顶部添加相应的 import 语句。

### 错误 3: SwiftData 不可用

**错误信息**:
```
SwiftData is only available in macOS 14.0 or newer
```

**解决方案**: 有两个选择：

**选项 A**: 提升最低部署目标
```
项目设置 → General → Minimum Deployments → macOS 14.0
```

**选项 B**: 使用 Core Data 替代 SwiftData
- 修改数据模型使用 Core Data
- 这需要较大改动，建议使用选项 A

### 错误 4: "Use of unresolved identifier"

**常见原因**:
- 文件中的类型名称拼写错误
- 相关文件未正确添加到项目

**解决方案**:
1. 检查拼写
2. 确保所有依赖文件都在项目中
3. 使用 `⌘ + B` 清理并重新构建

### 错误 5: "Ambiguous use of"

**原因**: 多个模块定义了相同名称的类型

**解决方案**: 使用完全限定名称
```swift
// 而不是
Date()

// 使用
Foundation.Date()
```

---

## 📋 完整导入清单

### Services 层

**ConflictResolver.swift**:
```swift
import Foundation
import AppKit
import Combine
```

**SyncEngine.swift**:
```swift
import Foundation
import Combine
```

**FileMonitor.swift**:
```swift
import Foundation
import CoreServices
import Combine
```

**LogManager.swift**:
```swift
import Foundation
import SwiftData
import Combine
import os.log
```

### Models 层

**SyncConfiguration.swift**:
```swift
import Foundation
import SwiftData
```

**FileItem.swift**:
```swift
import Foundation
```

**SyncLog.swift**:
```swift
import Foundation
import SwiftData
```

### Utils 层

所有 Extensions 文件:
```swift
import Foundation
```

**Data+Extensions.swift** 额外需要:
```swift
import Foundation
import CryptoKit
```

### Views 层

所有 View 文件:
```swift
import SwiftUI
import SwiftData
```

### App 层

**FolderSyncProApp.swift**:
```swift
import SwiftUI
import SwiftData
```

**AppDelegate.swift**:
```swift
import Cocoa
import SwiftUI
import UserNotifications
```

---

## 🚀 构建步骤

### 1. 清理构建
```
⌘ + Shift + K (或 Product → Clean Build Folder)
```

### 2. 构建项目
```
⌘ + B (或 Product → Build)
```

### 3. 运行项目
```
⌘ + R (或 Product → Run)
```

---

## 🔍 调试技巧

### 查看详细错误
在 Xcode 中:
1. 点击错误信息
2. 查看右侧 Issue Navigator
3. 点击错误查看详细堆栈

### 检查文件是否在项目中
```
1. 选择文件
2. 右侧 File Inspector
3. 检查 Target Membership
4. 确保 FolderSyncPro 被勾选 ✅
```

### 验证导入
在文件顶部按 `⌘ + 点击` import 语句:
- 如果能跳转到框架定义 = 正确
- 如果显示 "No Quick Help" = 框架缺失

---

## ✅ 验证清单

构建成功后，确认：

- [ ] 没有红色错误
- [ ] 没有黄色警告（可选）
- [ ] 所有文件都有蓝色图标
- [ ] Target Membership 都正确
- [ ] 可以成功运行 (⌘ + R)

---

## 💡 提示

1. **遇到错误先清理**: `⌘ + Shift + K` 然后重新构建
2. **检查 macOS 版本**: 确保部署目标正确设置
3. **导入顺序**: 通常按字母顺序，Foundation 在最前
4. **使用 Xcode 自动补全**: 输入 `import` 然后空格，Xcode 会提示可用框架

---

## 📞 仍然遇到问题？

如果遇到其他编译错误:

1. 复制完整错误信息
2. 记录文件名和行号
3. 告诉我，我会立即帮你解决！

---

**当前状态**: ✅ 所有已知编译错误已修复
**最后更新**: 2025-11-22
