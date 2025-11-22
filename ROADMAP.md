# FolderSync Pro - 功能实施路线图

## 📋 总览

本路线图规划了 6 个主要功能的分批实施计划，按照优先级和依赖关系分为 4 个阶段。

---

## 🎯 第一阶段：基础增强（优先级：高）

**目标**: 完善现有功能，提升用户体验

### 1.1 添加菜单栏快捷操作 ⭐⭐⭐⭐⭐

**优先级**: 最高
**预估工时**: 1-2 天
**依赖**: 无

#### 实施内容

- [ ] **状态栏增强**
  - 显示实时同步状态图标
  - 动态更新同步进度
  - 区分空闲/同步中/错误状态

- [ ] **快捷操作菜单**
  - 快速启动/停止所有同步
  - 快速访问最近使用的配置
  - 一键打开主窗口
  - 显示同步统计信息

- [ ] **通知集成**
  - 同步完成通知
  - 错误警告通知
  - 点击通知跳转到详情

#### 技术实现
```
文件位置: App/MenuBarController.swift
- 使用 NSStatusItem 管理菜单栏
- 实时订阅 SyncEngine 状态变化
- 集成 UNUserNotification
```

#### 验收标准
- [x] 菜单栏图标正确显示状态
- [x] 所有快捷操作正常工作
- [x] 通知及时准确
- [x] 性能无影响

---

### 1.2 实现定时同步功能 ⭐⭐⭐⭐

**优先级**: 高
**预估工时**: 2-3 天
**依赖**: 菜单栏快捷操作

#### 实施内容

- [ ] **定时器管理器**
  - 支持多种定时策略（间隔、每日、每周）
  - 智能避开系统休眠
  - 后台同步支持

- [ ] **配置界面**
  - 定时同步开关
  - 时间间隔选择器
  - 自定义时间表（高级）
  - 仅在空闲时同步选项

- [ ] **智能调度**
  - 检测用户活动状态
  - 避免资源竞争
  - 支持暂停/恢复

#### 技术实现
```
文件位置: Services/SyncScheduler.swift
- 使用 Timer 和 DispatchSourceTimer
- 集成 IOKit 检测空闲状态
- 持久化定时配置
```

#### 数据模型扩展
```swift
// SyncConfiguration 新增字段
var schedulingEnabled: Bool
var schedulingInterval: TimeInterval  // 秒
var schedulingType: SchedulingType    // .interval, .daily, .weekly
var schedulingTime: Date?             // 特定时间
var onlyWhenIdle: Bool                // 仅空闲时
```

#### 验收标准
- [x] 定时器准确触发
- [x] 支持所有配置的定时策略
- [x] 休眠后正确恢复
- [x] 空闲检测准确

---

## 🔧 第二阶段：过滤和预览（优先级：中高）

**目标**: 增强同步控制能力

### 2.1 实现更多的过滤规则配置 ⭐⭐⭐⭐

**优先级**: 中高
**预估工时**: 3-4 天
**依赖**: 无

#### 实施内容

- [ ] **高级过滤规则**
  - 正则表达式支持
  - 文件大小过滤（最小/最大）
  - 修改日期过滤（新于/旧于）
  - 文件属性过滤（只读、隐藏等）

- [ ] **规则管理界面**
  - 规则列表编辑器
  - 拖拽排序优先级
  - 规则模板库（预设）
  - 规则测试工具

- [ ] **智能规则**
  - 文件类型分类（文档、图片、视频等）
  - 自定义规则组合（AND/OR/NOT）
  - 规则导入/导出

#### 技术实现
```
文件位置:
- Models/FilterRule.swift (新建)
- Services/FilterEngine.swift (新建)
- Views/FilterRuleEditor.swift (新建)
```

#### 数据模型
```swift
struct FilterRule: Codable {
    var id: UUID
    var name: String
    var type: FilterType  // .pattern, .size, .date, .attribute, .regex
    var operation: FilterOperation  // .include, .exclude
    var value: String
    var isEnabled: Bool
    var priority: Int
}

enum FilterType {
    case pattern        // 通配符模式
    case regex          // 正则表达式
    case fileSize       // 文件大小
    case modifiedDate   // 修改日期
    case fileType       // 文件类型
    case attribute      // 文件属性
}
```

#### 验收标准
- [x] 所有过滤类型正确工作
- [x] 规则优先级正确应用
- [x] 规则测试工具准确
- [x] 性能测试通过（1000+ 文件）

---

### 2.2 添加同步预览功能 ⭐⭐⭐⭐⭐

**优先级**: 高
**预估工时**: 3-4 天
**依赖**: 过滤规则配置

#### 实施内容

- [ ] **预览扫描**
  - 完整的同步前扫描
  - 显示所有待操作文件
  - 分类显示（新增/修改/删除/冲突）
  - 估算传输数据量和时间

- [ ] **预览界面**
  - 树形/列表视图切换
  - 文件详情面板
  - 冲突高亮显示
  - 可选择性同步（勾选）

- [ ] **差异对比**
  - 并排文件对比
  - 高亮差异部分
  - 文本文件内容对比
  - 元数据对比（大小、时间等）

#### 技术实现
```
文件位置:
- Views/SyncPreviewView.swift (新建)
- Models/SyncPreviewResult.swift (新建)
- Services/PreviewEngine.swift (新建)
```

#### 数据模型
```swift
struct SyncPreviewResult {
    var filesToAdd: [FileItem]
    var filesToUpdate: [FileItem]
    var filesToDelete: [FileItem]
    var conflicts: [ConflictInfo]
    var totalSize: Int64
    var estimatedDuration: TimeInterval
}

struct FileComparison {
    let sourceFile: FileItem
    let targetFile: FileItem?
    let action: SyncAction
    let differences: [FileDifference]
}
```

#### 验收标准
- [x] 预览准确显示所有变化
- [x] 选择性同步正确工作
- [x] 差异对比清晰准确
- [x] 大量文件时性能良好

---

## 🌐 第三阶段：网络支持（优先级：中）

**目标**: 扩展同步范围到网络位置

### 3.1 支持网络文件夹同步 ⭐⭐⭐

**优先级**: 中
**预估工时**: 4-5 天
**依赖**: 预览功能

#### 实施内容

- [ ] **网络协议支持**
  - SMB/CIFS 支持
  - AFP 支持
  - WebDAV 支持
  - SFTP 支持（可选）

- [ ] **连接管理**
  - 凭证安全存储（Keychain）
  - 自动重连机制
  - 连接状态监控
  - 离线队列支持

- [ ] **网络优化**
  - 断点续传
  - 带宽限制
  - 压缩传输
  - 多连接并发

- [ ] **错误处理**
  - 网络超时处理
  - 连接失败重试
  - 部分失败恢复
  - 详细错误日志

#### 技术实现
```
文件位置:
- Services/NetworkSyncEngine.swift (新建)
- Services/NetworkConnectionManager.swift (新建)
- Models/NetworkCredential.swift (新建)
- Utils/NetworkUtils.swift (新建)
```

#### 数据模型扩展
```swift
enum SyncLocationType {
    case local
    case smb(host: String, share: String)
    case afp(host: String, share: String)
    case webdav(url: URL)
    case sftp(host: String, port: Int)
}

struct NetworkCredential {
    var id: UUID
    var locationType: SyncLocationType
    var username: String
    var passwordKeychainKey: String  // 引用 Keychain
    var autoConnect: Bool
}

// SyncConfiguration 扩展
var sourceLocationType: SyncLocationType
var targetLocationType: SyncLocationType
var sourceCredential: NetworkCredential?
var targetCredential: NetworkCredential?
var networkOptions: NetworkSyncOptions
```

#### 网络配置
```swift
struct NetworkSyncOptions {
    var connectionTimeout: TimeInterval = 30
    var maxRetries: Int = 3
    var bandwidthLimit: Int64? = nil  // bytes/s
    var enableCompression: Bool = true
    var enableResume: Bool = true
}
```

#### 验收标准
- [x] 支持所有网络协议
- [x] 凭证安全存储和使用
- [x] 网络中断自动恢复
- [x] 大文件传输稳定
- [x] 性能符合预期

---

## 🧪 第四阶段：测试和质量保证（优先级：高）

**目标**: 确保代码质量和稳定性

### 4.1 添加单元测试和 UI 测试 ⭐⭐⭐⭐⭐

**优先级**: 高
**预估工时**: 5-7 天
**依赖**: 所有功能完成后

#### 实施内容

- [ ] **单元测试（70% 覆盖率目标）**

  **Models 层测试**
  - SyncConfiguration 验证逻辑
  - FileItem 比较和校验
  - FilterRule 匹配逻辑

  **Services 层测试**
  - SyncEngine 核心逻辑
  - ConflictResolver 策略
  - FilterEngine 过滤逻辑
  - LogManager 日志记录
  - FileMonitor 事件处理
  - SyncScheduler 定时逻辑

  **Utils 层测试**
  - 所有扩展方法
  - 文件操作
  - 路径处理
  - 校验和计算

- [ ] **集成测试**
  - 完整同步流程
  - 冲突处理流程
  - 网络同步流程
  - 定时同步流程

- [ ] **UI 测试**
  - 配置创建流程
  - 同步操作流程
  - 预览界面交互
  - 设置修改流程

- [ ] **性能测试**
  - 大量文件扫描（10,000+ 文件）
  - 并发同步性能
  - 内存泄漏检测
  - CPU 使用率监控

#### 技术实现
```
文件位置:
- FolderSyncProTests/
  - Models/
    - SyncConfigurationTests.swift
    - FileItemTests.swift
    - FilterRuleTests.swift
  - Services/
    - SyncEngineTests.swift
    - ConflictResolverTests.swift
    - FilterEngineTests.swift
    - LogManagerTests.swift
    - FileMonitorTests.swift
    - SyncSchedulerTests.swift
  - Utils/
    - ExtensionsTests.swift
  - Integration/
    - SyncFlowTests.swift
    - NetworkSyncTests.swift

- FolderSyncProUITests/
  - ConfigurationUITests.swift
  - SyncOperationUITests.swift
  - PreviewUITests.swift
  - SettingsUITests.swift
```

#### 测试工具
```swift
// Mock 对象
class MockFileManager: FileManagerProtocol { }
class MockSyncEngine: SyncEngineProtocol { }
class MockLogManager: LogManagerProtocol { }

// 测试工具类
class TestFileSystemBuilder {
    // 创建测试文件结构
}

class SyncTestHelper {
    // 同步测试辅助方法
}
```

#### 验收标准
- [x] 单元测试覆盖率 ≥ 70%
- [x] 所有集成测试通过
- [x] UI 测试覆盖主要流程
- [x] 性能测试达标
- [x] 无内存泄漏
- [x] CI/CD 集成

---

## 📊 实施时间表

| 阶段 | 功能 | 预估时间 | 人员 | 状态 |
|------|------|----------|------|------|
| **第一阶段** | 菜单栏快捷操作 | 1-2 天 | 1 人 | ⏳ 待开始 |
| | 定时同步功能 | 2-3 天 | 1 人 | ⏳ 待开始 |
| **第二阶段** | 过滤规则配置 | 3-4 天 | 1 人 | ⏳ 待开始 |
| | 同步预览功能 | 3-4 天 | 1 人 | ⏳ 待开始 |
| **第三阶段** | 网络文件夹同步 | 4-5 天 | 1 人 | ⏳ 待开始 |
| **第四阶段** | 单元测试 & UI 测试 | 5-7 天 | 1 人 | ⏳ 待开始 |
| **总计** | | **18-25 天** | | |

---

## 🎯 里程碑

### Milestone 1: 基础增强 (第 1-5 天)
- ✅ 菜单栏快捷操作
- ✅ 定时同步功能
- 🎉 **发布**: v1.1.0

### Milestone 2: 过滤和预览 (第 6-13 天)
- ✅ 高级过滤规则
- ✅ 同步预览功能
- 🎉 **发布**: v1.2.0

### Milestone 3: 网络支持 (第 14-18 天)
- ✅ 网络文件夹同步
- 🎉 **发布**: v1.3.0

### Milestone 4: 质量保证 (第 19-25 天)
- ✅ 完整测试套件
- ✅ 性能优化
- 🎉 **发布**: v2.0.0 (正式版)

---

## 📝 实施建议

### 优先级排序理由

1. **菜单栏快捷操作** (最先) - 显著提升用户体验，工作量小
2. **定时同步功能** (第二) - 核心功能补充，依赖菜单栏状态显示
3. **过滤规则配置** (第三) - 为预览功能提供基础
4. **同步预览功能** (第四) - 提升同步安全性，需要过滤规则
5. **网络文件夹同步** (第五) - 功能扩展，相对独立
6. **单元测试** (最后) - 在所有功能完成后统一测试

### 开发建议

1. **分支策略**
   ```
   feature/menubar-shortcuts    (第一阶段)
   feature/scheduled-sync       (第一阶段)
   feature/advanced-filters     (第二阶段)
   feature/sync-preview         (第二阶段)
   feature/network-sync         (第三阶段)
   feature/testing-suite        (第四阶段)
   ```

2. **代码审查**
   - 每个功能完成后进行 Code Review
   - 使用 Pull Request 流程
   - 确保代码质量和一致性

3. **文档更新**
   - 同步更新 README.md
   - 更新 BUILD.md 构建指南
   - 编写功能使用文档

4. **用户反馈**
   - 每个阶段发布 Beta 版本
   - 收集用户反馈
   - 快速迭代改进

---

## 🔄 迭代计划

### v1.1.0 - 基础增强
- 菜单栏快捷操作
- 定时同步功能
- Bug 修复和性能优化

### v1.2.0 - 高级控制
- 高级过滤规则
- 同步预览功能
- 用户体验改进

### v1.3.0 - 网络扩展
- 网络文件夹同步
- 多协议支持
- 稳定性提升

### v2.0.0 - 正式版
- 完整测试覆盖
- 性能优化
- 文档完善
- 生产就绪

---

## 📌 注意事项

### 技术风险

1. **网络同步复杂度高**
   - 建议预留更多时间
   - 充分测试各种网络场景
   - 考虑分阶段实现协议

2. **测试覆盖率**
   - 需要投入足够时间
   - 考虑引入测试自动化
   - 持续集成很重要

3. **性能优化**
   - 大文件和大量文件场景
   - 网络带宽优化
   - 内存使用优化

### 资源需求

- **开发人员**: 1 名全职开发
- **测试人员**: 建议配备 1 名兼职测试
- **设计师**: 可选，用于 UI 优化

---

## 🎓 成功标准

### 功能完整性
- [ ] 所有计划功能已实现
- [ ] 功能测试通过
- [ ] 用户文档完整

### 质量标准
- [ ] 单元测试覆盖率 ≥ 70%
- [ ] 无已知严重 Bug
- [ ] 性能测试通过

### 用户体验
- [ ] 界面友好直观
- [ ] 操作流畅无卡顿
- [ ] 错误提示清晰

### 稳定性
- [ ] 长时间运行稳定
- [ ] 内存无泄漏
- [ ] 崩溃率 < 0.1%

---

## 📞 联系和支持

如有问题或建议，请通过以下方式联系：
- GitHub Issues: https://github.com/foldersyncpro/issues
- 项目 Wiki: https://github.com/foldersyncpro/wiki

---

**最后更新**: 2025-11-22
**版本**: 1.0
**作者**: FolderSync Pro Team
