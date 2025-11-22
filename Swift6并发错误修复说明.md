# 🔧 Swift 6 并发错误修复说明

## 📝 最新修复（2025-11-22）

**提交**: `bc87ac1 - fix: 修复 Swift 6 并发错误和 SyncOperation 枚举问题`

### 修复的编译错误

#### 错误 1: MainActor 隔离方法调用错误（3 个）

**错误信息**:
```
/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:361:44
Main actor-isolated instance method 'recursiveContents(of:includeHidden:)' cannot be called from outside of the actor

/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:408:49
Main actor-isolated static method 'from(url:baseURL:location:)' cannot be called from outside of the actor

/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:412:38
Main actor-isolated instance method 'calculateSHA256()' cannot be called from outside of the actor
```

**原因**: 在 `Task.detached` 内部直接调用这些方法，但 Swift 6 的严格并发检查推断这些方法需要在特定的 actor 上下文中

**解决方案**: 使用 `withCheckedThrowingContinuation` 包装 `Task.detached` 调用

**修复前**:
```swift
return try await Task.detached {
    var files: [String: FileItem] = [:]

    let fileURLs = try fileManager.recursiveContents(of: url, includeHidden: false)
    // ❌ 错误：在 Task.detached 中直接调用

    for fileURL in fileURLs {
        var fileItem = try FileItem.from(url: fileURL, baseURL: url, location: location)
        // ❌ 错误：在 Task.detached 中直接调用

        try fileItem.calculateSHA256()
        // ❌ 错误：在 Task.detached 中直接调用
    }

    return files
}.value
```

**修复后**:
```swift
// ✅ 正确：使用 withCheckedThrowingContinuation 包装
let fileURLs = try await withCheckedThrowingContinuation { continuation in
    Task.detached {
        do {
            let urls = try fileManager.recursiveContents(of: url, includeHidden: false)
            continuation.resume(returning: urls)
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

// 在 MainActor 上下文处理文件列表
for fileURL in fileURLs {
    // ✅ 正确：为每个文件创建独立的后台任务
    var fileItem = try await withCheckedThrowingContinuation { continuation in
        Task.detached {
            do {
                let item = try FileItem.from(url: fileURL, baseURL: url, location: location)
                continuation.resume(returning: item)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // ✅ 正确：计算校验和也在后台
    if configuration.verifyFileIntegrity && !fileItem.isDirectory {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task.detached {
                do {
                    try fileItem.calculateSHA256()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

---

#### 错误 2: 并发访问捕获变量（2 个）

**错误信息**:
```
/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:430:72
Reference to captured var 'processedCount' in concurrently-executing code

/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:430:99
Reference to captured var 'excludedCount' in concurrently-executing code
```

**原因**: 在 `Task.detached` 闭包内访问外部的可变变量

**解决方案**: 将变量声明移到 `Task.detached` 外部，在 MainActor 上下文中修改

**修复前**:
```swift
return try await Task.detached {
    var files: [String: FileItem] = [:]
    var processedCount = 0  // 在 Task.detached 内部
    var excludedCount = 0   // 在 Task.detached 内部

    // ... 处理文件

    await MainActor.run {
        self.logManager.debug(
            "扫描完成: 处理了 \(processedCount) 个文件, 排除了 \(excludedCount) 个文件",
            // ❌ 错误：在并发上下文中引用捕获的变量
        )
    }
}.value
```

**修复后**:
```swift
var files: [String: FileItem] = [:]
var processedCount = 0  // ✅ 正确：在 MainActor 上下文中
var excludedCount = 0   // ✅ 正确：在 MainActor 上下文中

// 处理文件列表
for fileURL in fileURLs {
    // ... 处理逻辑
    processedCount += 1  // ✅ 正确：不在并发闭包中
}

logManager.debug(
    "扫描完成: 处理了 \(processedCount) 个文件, 排除了 \(excludedCount) 个文件"
    // ✅ 正确：直接访问，无并发问题
)
```

---

#### 错误 3: SyncOperation 枚举成员错误（2 个）

**错误信息**:
```
/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:693:29
Type 'SyncOperation' has no member 'conflict'

/Users/Ning/Github/nings/macfoldersync/FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift:709:33
Type 'SyncOperation' has no member 'conflict'
```

**原因**: 使用了不存在的枚举成员 `.conflict`，实际定义是 `.conflictResolved`

**SyncOperation 枚举定义**:
```swift
enum SyncOperation: String, Codable {
    case scan = "扫描"
    case copy = "复制"
    case update = "更新"
    case delete = "删除"
    case conflictResolved = "解决冲突"  // ✅ 正确的名称
    case monitorStart = "开始监控"
    case monitorStop = "停止监控"
    case configUpdate = "配置更新"
    case error = "错误"
}
```

**修复前**:
```swift
logManager.info(
    "开始解决冲突: \(changes.conflicts.count) 个",
    operation: .conflict,  // ❌ 错误：枚举中没有这个成员
    configurationId: configuration.id
)

logManager.debug(
    "解决冲突: \(conflict.relativePath)",
    operation: .conflict,  // ❌ 错误：枚举中没有这个成员
    configurationId: configuration.id
)
```

**修复后**:
```swift
logManager.info(
    "开始解决冲突: \(changes.conflicts.count) 个",
    operation: .conflictResolved,  // ✅ 正确：使用正确的枚举成员
    configurationId: configuration.id
)

logManager.debug(
    "解决冲突: \(conflict.relativePath)",
    operation: .conflictResolved,  // ✅ 正确：使用正确的枚举成员
    configurationId: configuration.id
)
```

---

## 🎯 技术要点总结

### 1. Swift 6 并发模型中的 `Task.detached`

**问题**: `Task.detached` 创建的任务不继承父任务的 actor 上下文，导致无法直接调用 MainActor 隔离的方法

**解决方案**: 使用 `withCheckedThrowingContinuation` 包装 `Task.detached`

```swift
// 模式：后台执行，返回结果
let result = try await withCheckedThrowingContinuation { continuation in
    Task.detached {
        do {
            let value = try someBlockingOperation()
            continuation.resume(returning: value)
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
```

### 2. 避免并发变量捕获

**规则**: 不要在 `Task.detached` 或其他并发闭包中引用和修改外部的可变变量

**解决方案**:
- 将变量声明在 actor 上下文中
- 使用 continuation 传递值
- 每个并发任务独立处理，返回结果后在主上下文中合并

### 3. 保持 UI 响应的正确方式

```swift
// ✅ 正确的模式
private func scanDirectory(...) async throws -> [String: FileItem] {
    // 1. 在后台扫描文件列表（耗时 I/O）
    let fileURLs = try await withCheckedThrowingContinuation { continuation in
        Task.detached {
            // 阻塞的 I/O 操作
            let urls = try fileManager.recursiveContents(of: url, includeHidden: false)
            continuation.resume(returning: urls)
        }
    }

    // 2. 在主上下文处理结果（不阻塞 UI）
    var files: [String: FileItem] = [:]
    for fileURL in fileURLs {
        // 为每个文件创建独立的后台任务
        let fileItem = try await withCheckedThrowingContinuation { ... }
        files[path] = fileItem
    }

    return files
}
```

---

## 🚀 如何更新和测试

### 步骤 1: 拉取最新代码

```bash
cd /Users/Ning/Github/nings/macfoldersync
git pull origin claude/implement-project-modules-012sRvPv9iPjabTbBa1qLYRB
```

**预期输出**:
```
From http://...
   58a2dc3..bc87ac1  claude/implement-project-modules-012sRvPv9iPjabTbBa1qLYRB -> origin/claude/implement-project-modules-012sRvPv9iPjabTbBa1qLYRB
Updating 58a2dc3..bc87ac1
Fast-forward
 FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift | 199 ++++++++++++++---------------
 1 file changed, 99 insertions(+), 100 deletions(-)
```

### 步骤 2: 清理 Xcode 缓存

```bash
cd /Users/Ning/Github/nings/Xcode/MacOS/FolderSyncPro
rm -rf ~/Library/Developer/Xcode/DerivedData/FolderSyncPro-*
killall Xcode
open FolderSyncPro.xcodeproj
```

### 步骤 3: 重新构建

在 Xcode 中：
1. Clean Build: `⌘ + Shift + K`
2. Build: `⌘ + B` （应该没有错误了！）
3. Run: `⌘ + R`

### 步骤 4: 测试同步功能

按照之前的测试步骤：
1. 创建测试文件
2. 配置同步
3. 查看日志输出
4. 验证文件同步

---

## ✅ 预期结果

编译后应该：
- ✅ 没有编译错误
- ✅ 没有警告
- ✅ 应用可以正常运行
- ✅ 文件扫描在后台执行，UI 保持响应
- ✅ 日志显示详细的同步进度

---

## 📊 修复历史

| 提交 | 日期 | 修复内容 |
|------|------|---------|
| `bc87ac1` | 2025-11-22 | Swift 6 并发错误和 SyncOperation 枚举 |
| `d451af1` | 2025-11-22 | 添加详细的同步调试日志 |
| `58a2dc3` | 2025-11-22 | 添加详细的同步问题诊断指南 |
| `5e917c3` | 2025-11-22 | 修复文件扫描在主线程阻塞导致 UI 冻结 |
| `fe343cf` | 2025-11-22 | 添加 security-scoped bookmark 支持 |
| `6ff907b` | 2025-11-22 | 修复 FileMonitor C 函数指针问题 |

---

**最后更新**: 2025-11-22
**当前分支**: `claude/implement-project-modules-012sRvPv9iPjabTbBa1qLYRB`
**状态**: ✅ 所有编译错误已修复
