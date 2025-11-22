# 手动修复补丁 - 适用于 Xcode/MacOS/FolderSyncPro

## 📋 需要修复的 5 个文件

### 1️⃣ Models/SyncLog.swift

**问题**: SwiftData @Model 宏冲突

**查找并删除以下代码**（如果存在）:
```swift
// 删除这整个扩展（如果存在）
extension SyncLog: Hashable, Equatable {
    static func == (lhs: SyncLog, rhs: SyncLog) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

**原因**: `@Model` 宏自动生成 Hashable/Equatable，手动实现会冲突。

---

### 2️⃣ Models/SyncConfiguration.swift

**问题**: SwiftData @Model 宏冲突

**查找并删除以下代码**（如果存在）:
```swift
// 删除这整个扩展（如果存在）
extension SyncConfiguration: Hashable, Equatable {
    static func == (lhs: SyncConfiguration, rhs: SyncConfiguration) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

---

### 3️⃣ Services/ConflictResolver.swift

**问题**:
1. Combine 导入缺失
2. MainActor 隔离问题

**修改 1 - 导入语句**（文件顶部）:
```swift
// 原来：
import Foundation
import AppKit
import Combine

// 改为：
import Foundation
import AppKit
@preconcurrency import Combine
```

**修改 2 - LogManager 初始化**（找到 `init()` 方法）:

查找：
```swift
init(logManager: LogManager = .shared) {
    self.logManager = logManager
}
```

改为：
```swift
init(logManager: LogManager? = nil) {
    self.logManager = logManager ?? LogManager.shared
}
```

---

### 4️⃣ Services/SyncEngine.swift

**问题**: Combine 导入和 MainActor 隔离

**修改 1 - 导入语句**（文件顶部）:
```swift
// 原来：
import Foundation
import Combine

// 改为：
import Foundation
@preconcurrency import Combine
```

**修改 2 - LogManager 初始化**（找到 `init()` 方法）:

查找：
```swift
init(
    logManager: LogManager = .shared,
    conflictResolver: ConflictResolver
) {
    self.logManager = logManager
    self.conflictResolver = conflictResolver
}
```

改为：
```swift
init(
    logManager: LogManager? = nil,
    conflictResolver: ConflictResolver
) {
    self.logManager = logManager ?? LogManager.shared
    self.conflictResolver = conflictResolver
}
```

**修改 3 - LogManager 方法调用**（在同步完成时）:

查找类似这样的代码：
```swift
logManager.info(
    "同步完成: \(result.summary)",
    operation: .scan,
    configurationId: configuration.id,
    filesProcessed: result.totalFilesProcessed,
    bytesProcessed: result.bytesProcessed
)
```

改为：
```swift
logManager.log(
    level: .info,
    operation: .scan,
    message: "同步完成: \(result.summary)",
    configurationId: configuration.id,
    filesProcessed: result.totalFilesProcessed,
    bytesProcessed: result.bytesProcessed
)
```

---

### 5️⃣ Services/FileMonitor.swift

**问题**: Combine 导入

**修改 - 导入语句**（文件顶部）:
```swift
// 原来：
import Foundation
import CoreServices
import Combine

// 改为：
import Foundation
import CoreServices
@preconcurrency import Combine
```

---

### 6️⃣ Services/LogManager.swift

**问题**: Combine 导入

**修改 - 导入语句**（文件顶部）:
```swift
// 原来：
import Foundation
import SwiftData
import Combine
import os.log

// 改为：
import Foundation
import SwiftData
@preconcurrency import Combine
import os.log
```

---

### 7️⃣ Views/PreferencesView.swift

**问题**: UniformTypeIdentifiers 导入缺失

**修改 - 导入语句**（文件顶部）:
```swift
// 原来：
import SwiftUI

// 改为：
import SwiftUI
import UniformTypeIdentifiers
```

---

### 8️⃣ Resources/Assets.xcassets/AccentColor.colorset/Contents.json

**问题**: AccentColor 缺失

**如果不存在，创建以下文件结构**:

```
Resources/Assets.xcassets/
└── AccentColor.colorset/
    └── Contents.json
```

**Contents.json 内容**:
```json
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

## 🔧 修复步骤

### 步骤 1: 关闭 Xcode
完全退出 Xcode（⌘ + Q）

### 步骤 2: 应用上述所有修改
按照上面的说明，逐一修改每个文件

### 步骤 3: 清理 Xcode 缓存
```bash
# 删除 Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/FolderSyncPro-*

# 删除 Swift 缓存
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm
```

### 步骤 4: 重新打开和构建
```bash
cd /Users/Ning/Github/nings/Xcode/MacOS
open FolderSyncPro/FolderSyncPro.xcodeproj
```

在 Xcode 中：
1. ⌘ + Shift + K（Clean Build Folder）
2. ⌘ + B（Build）

---

## 📊 快速检查清单

修改完成后，检查以下内容：

- [ ] SyncLog.swift - 没有手动 Hashable 扩展
- [ ] SyncConfiguration.swift - 没有手动 Hashable 扩展
- [ ] ConflictResolver.swift - 使用 `@preconcurrency import Combine`
- [ ] ConflictResolver.swift - init 使用 `logManager: LogManager? = nil`
- [ ] SyncEngine.swift - 使用 `@preconcurrency import Combine`
- [ ] SyncEngine.swift - init 使用 `logManager: LogManager? = nil`
- [ ] SyncEngine.swift - 使用 `logManager.log()` 而不是 `info()`
- [ ] FileMonitor.swift - 使用 `@preconcurrency import Combine`
- [ ] LogManager.swift - 使用 `@preconcurrency import Combine`
- [ ] PreferencesView.swift - 导入了 UniformTypeIdentifiers
- [ ] AccentColor.colorset 存在

---

## 🎯 自动化脚本（可选）

如果您想自动应用这些修复，可以保存以下脚本为 `apply-fixes.sh`:

```bash
#!/bin/bash

PROJECT_DIR="/Users/Ning/Github/nings/Xcode/MacOS/FolderSyncPro"
cd "$PROJECT_DIR" || exit 1

echo "🔧 应用修复补丁..."

# 1. 修复 SyncLog.swift - 删除手动 Hashable 扩展
echo "1️⃣  修复 SyncLog.swift"
if grep -q "extension SyncLog.*Hashable" FolderSyncPro/Models/SyncLog.swift; then
    # 找到并删除 extension
    sed -i '' '/^extension SyncLog.*Hashable/,/^}/d' FolderSyncPro/Models/SyncLog.swift
    echo "   ✅ 已删除 Hashable 扩展"
else
    echo "   ✓ 无需修改"
fi

# 2. 修复 SyncConfiguration.swift - 删除手动 Hashable 扩展
echo "2️⃣  修复 SyncConfiguration.swift"
if grep -q "extension SyncConfiguration.*Hashable" FolderSyncPro/Models/SyncConfiguration.swift; then
    sed -i '' '/^extension SyncConfiguration.*Hashable/,/^}/d' FolderSyncPro/Models/SyncConfiguration.swift
    echo "   ✅ 已删除 Hashable 扩展"
else
    echo "   ✓ 无需修改"
fi

# 3. 修复 ConflictResolver.swift - Combine 导入
echo "3️⃣  修复 ConflictResolver.swift"
sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/ConflictResolver.swift
sed -i '' 's/logManager: LogManager = \.shared/logManager: LogManager? = nil/' FolderSyncPro/Services/ConflictResolver.swift
sed -i '' 's/self\.logManager = logManager$/self.logManager = logManager ?? LogManager.shared/' FolderSyncPro/Services/ConflictResolver.swift
echo "   ✅ 已修复"

# 4. 修复 SyncEngine.swift - Combine 导入
echo "4️⃣  修复 SyncEngine.swift"
sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/SyncEngine.swift
sed -i '' 's/logManager: LogManager = \.shared/logManager: LogManager? = nil/' FolderSyncPro/Services/SyncEngine.swift
echo "   ✅ 已修复"

# 5. 修复 FileMonitor.swift
echo "5️⃣  修复 FileMonitor.swift"
sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/FileMonitor.swift
echo "   ✅ 已修复"

# 6. 修复 LogManager.swift
echo "6️⃣  修复 LogManager.swift"
sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/LogManager.swift
echo "   ✅ 已修复"

# 7. 修复 PreferencesView.swift
echo "7️⃣  修复 PreferencesView.swift"
if ! grep -q "import UniformTypeIdentifiers" FolderSyncPro/Views/PreferencesView.swift; then
    sed -i '' '/^import SwiftUI$/a\
import UniformTypeIdentifiers
' FolderSyncPro/Views/PreferencesView.swift
    echo "   ✅ 已添加 UniformTypeIdentifiers 导入"
else
    echo "   ✓ 无需修改"
fi

# 8. 创建 AccentColor
echo "8️⃣  创建 AccentColor.colorset"
mkdir -p FolderSyncPro/Resources/Assets.xcassets/AccentColor.colorset
cat > FolderSyncPro/Resources/Assets.xcassets/AccentColor.colorset/Contents.json <<'EOF'
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
echo "   ✅ 已创建"

echo ""
echo "✨ 所有修复已应用！"
echo ""
echo "📋 下一步："
echo "1. 删除缓存: rm -rf ~/Library/Developer/Xcode/DerivedData/FolderSyncPro-*"
echo "2. 打开 Xcode: open FolderSyncPro.xcodeproj"
echo "3. Clean Build: ⌘ + Shift + K"
echo "4. Rebuild: ⌘ + B"
```

运行方式：
```bash
chmod +x apply-fixes.sh
./apply-fixes.sh
```

---

## ⚠️ 重要提醒

**强烈建议使用 Git 仓库中的代码**，而不是手动修复副本：

```bash
cd /Users/Ning/Github/nings/macfoldersync
git pull origin claude/implement-project-modules-012sRvPv9iPjabTbBa1qLYRB
open FolderSyncPro/FolderSyncPro.xcodeproj
```

这样可以：
- ✅ 自动获取所有修复
- ✅ 版本控制
- ✅ 避免手动错误
- ✅ 与 Git 保持同步

---

**最后更新**: 2025-11-22
**适用于**: `/Users/Ning/Github/nings/Xcode/MacOS/FolderSyncPro/`
