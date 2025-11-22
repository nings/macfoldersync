# 第一阶段详细实施计划

## 📋 阶段概览

**目标**: 基础增强 - 菜单栏快捷操作 + 定时同步功能
**预估时间**: 3-5 天
**优先级**: 最高

---

## 🎯 功能 1: 菜单栏快捷操作

### 第 1 天：菜单栏集成

#### 上午：创建 MenuBarController

**任务清单**:
- [ ] 创建 `MenuBarController.swift`
- [ ] 实现 NSStatusItem 管理
- [ ] 设计菜单结构
- [ ] 添加图标资源

**代码结构**:
```swift
// App/MenuBarController.swift
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu!
    private var syncEngine: SyncEngine

    // 菜单项
    private var syncStatusItem: NSMenuItem!
    private var configsSubmenu: NSMenu!
    private var statisticsItem: NSMenuItem!

    // 状态图标
    enum StatusIcon {
        case idle       // 空闲 - folder.badge.gearshape
        case syncing    // 同步中 - arrow.triangle.2.circlepath (动画)
        case error      // 错误 - exclamationmark.triangle
        case paused     // 暂停 - pause.circle
    }
}
```

**技术要点**:
- 使用 `NSStatusBar.system.statusItem(withLength:)` 创建状态栏项
- 图标使用 SF Symbols，支持深色模式自动适配
- 实现图标动画效果（同步中旋转）

---

#### 下午：实现菜单项和事件处理

**任务清单**:
- [ ] 实现主菜单项
- [ ] 添加配置子菜单
- [ ] 实现快捷操作
- [ ] 连接 SyncEngine

**菜单结构**:
```
┌─────────────────────────────────┐
│ 📊 同步状态: 空闲               │
├─────────────────────────────────┤
│ 🚀 开始所有同步                 │
│ ⏸  暂停所有同步                 │
│ 🔄 刷新状态                     │
├─────────────────────────────────┤
│ 📁 最近配置 ▶                   │
│    ├─ 文档同步                  │
│    ├─ 照片备份                  │
│    └─ 项目同步                  │
├─────────────────────────────────┤
│ 📈 统计信息                     │
│    今日: 15 个文件, 2.3 MB      │
│    本周: 142 个文件, 45 MB      │
├─────────────────────────────────┤
│ 🪟 打开主窗口                   │
│ ⚙️  偏好设置...                 │
├─────────────────────────────────┤
│ ❓ 帮助                         │
│ 🔄 检查更新...                  │
├─────────────────────────────────┤
│ 🚪 退出 FolderSync Pro          │
└─────────────────────────────────┘
```

**实现代码**:
```swift
func buildMenu() {
    menu = NSMenu()

    // 状态显示
    syncStatusItem = NSMenuItem(title: "同步状态: 空闲", action: nil, keyEquivalent: "")
    syncStatusItem.isEnabled = false
    menu.addItem(syncStatusItem)

    menu.addItem(NSMenuItem.separator())

    // 快捷操作
    menu.addItem(NSMenuItem(
        title: "开始所有同步",
        action: #selector(startAllSync),
        keyEquivalent: "s"
    ))

    menu.addItem(NSMenuItem(
        title: "暂停所有同步",
        action: #selector(pauseAllSync),
        keyEquivalent: "p"
    ))

    // ... 更多菜单项
}
```

---

### 第 2 天：状态监控和通知

#### 上午：实时状态更新

**任务清单**:
- [ ] 实现状态监控机制
- [ ] 订阅 SyncEngine 事件
- [ ] 实现进度显示
- [ ] 添加图标动画

**状态订阅**:
```swift
class MenuBarController {
    func setupObservers() {
        // 监听同步状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncStatusChanged),
            name: .syncStatusChanged,
            object: nil
        )

        // 监听同步进度
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncProgressUpdated),
            name: .syncProgressUpdated,
            object: nil
        )
    }

    @objc func syncStatusChanged(_ notification: Notification) {
        guard let status = notification.object as? SyncStatus else { return }

        DispatchQueue.main.async {
            self.updateIcon(for: status)
            self.updateStatusText(for: status)
        }
    }
}
```

**图标动画**:
```swift
func startRotationAnimation() {
    guard let button = statusItem?.button else { return }

    let rotation = CABasicAnimation(keyPath: "transform.rotation")
    rotation.fromValue = 0
    rotation.toValue = 2 * Double.pi
    rotation.duration = 1.5
    rotation.repeatCount = .infinity

    button.layer?.add(rotation, forKey: "rotationAnimation")
}

func stopRotationAnimation() {
    statusItem?.button?.layer?.removeAllAnimations()
}
```

---

#### 下午：通知集成

**任务清单**:
- [ ] 创建 NotificationManager
- [ ] 实现通知发送逻辑
- [ ] 处理通知交互
- [ ] 测试通知权限

**通知管理器**:
```swift
// Services/NotificationManager.swift
class NotificationManager: NSObject {
    static let shared = NotificationManager()

    func sendSyncCompletedNotification(result: SyncResult, config: SyncConfiguration) {
        let content = UNMutableNotificationContent()
        content.title = "同步完成"
        content.body = """
        配置: \(config.name)
        处理: \(result.totalFilesProcessed) 个文件
        """
        content.sound = .default
        content.categoryIdentifier = "SYNC_COMPLETED"
        content.userInfo = [
            "configId": config.id.uuidString,
            "action": "sync_completed"
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendSyncErrorNotification(error: Error, config: SyncConfiguration) {
        let content = UNMutableNotificationContent()
        content.title = "同步失败"
        content.body = """
        配置: \(config.name)
        错误: \(error.localizedDescription)
        """
        content.sound = .defaultCritical
        content.categoryIdentifier = "SYNC_ERROR"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// 处理通知交互
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let configId = userInfo["configId"] as? String,
           let uuid = UUID(uuidString: configId) {
            // 打开主窗口并导航到该配置
            NotificationCenter.default.post(
                name: .openConfiguration,
                object: uuid
            )
        }

        completionHandler()
    }
}
```

---

### 测试和优化

**测试场景**:
- [ ] 菜单栏图标正确显示
- [ ] 状态变化及时更新
- [ ] 图标动画流畅
- [ ] 通知正确发送和接收
- [ ] 菜单交互响应快速
- [ ] 深色模式适配正确

---

## 🔔 功能 2: 定时同步功能

### 第 3 天：定时器框架

#### 上午：创建 SyncScheduler

**任务清单**:
- [ ] 创建 `SyncScheduler.swift`
- [ ] 实现定时器管理
- [ ] 设计调度策略
- [ ] 持久化配置

**调度器结构**:
```swift
// Services/SyncScheduler.swift
@MainActor
class SyncScheduler: ObservableObject {
    // MARK: - Properties

    @Published private(set) var activeSchedules: [ScheduleInfo] = []

    private var timers: [UUID: DispatchSourceTimer] = [:]
    private let queue = DispatchQueue(label: "com.foldersyncpro.scheduler", qos: .utility)

    private let syncEngine: SyncEngine
    private let logManager: LogManager

    // MARK: - Schedule Management

    func addSchedule(for configuration: SyncConfiguration) {
        guard configuration.schedulingEnabled else { return }

        let scheduleInfo = ScheduleInfo(
            configurationId: configuration.id,
            type: configuration.schedulingType,
            interval: configuration.schedulingInterval,
            specificTime: configuration.schedulingTime,
            onlyWhenIdle: configuration.onlyWhenIdle
        )

        createTimer(for: scheduleInfo)
        activeSchedules.append(scheduleInfo)

        logManager.info("已添加定时任务: \(configuration.name)")
    }

    func removeSchedule(for configurationId: UUID) {
        timers[configurationId]?.cancel()
        timers.removeValue(forKey: configurationId)
        activeSchedules.removeAll { $0.configurationId == configurationId }

        logManager.info("已移除定时任务")
    }
}
```

**定时类型**:
```swift
enum SchedulingType: String, Codable {
    case interval   // 间隔重复
    case daily      // 每日指定时间
    case weekly     // 每周指定时间
    case hourly     // 每小时
}

struct ScheduleInfo: Identifiable {
    let id = UUID()
    let configurationId: UUID
    let type: SchedulingType
    let interval: TimeInterval  // 秒
    let specificTime: Date?     // 特定时间
    let onlyWhenIdle: Bool
    var nextRun: Date?
    var lastRun: Date?
}
```

---

#### 下午：实现定时逻辑

**任务清单**:
- [ ] 实现各种定时策略
- [ ] 计算下次运行时间
- [ ] 实现定时器触发
- [ ] 添加错误处理

**定时器创建**:
```swift
private func createTimer(for schedule: ScheduleInfo) {
    let timer = DispatchSource.makeTimerSource(queue: queue)

    switch schedule.type {
    case .interval:
        timer.schedule(
            deadline: .now() + schedule.interval,
            repeating: schedule.interval
        )

    case .daily:
        if let nextRun = calculateNextDailyRun(time: schedule.specificTime) {
            timer.schedule(deadline: .now() + nextRun.timeIntervalSinceNow)
        }

    case .weekly:
        if let nextRun = calculateNextWeeklyRun(time: schedule.specificTime) {
            timer.schedule(deadline: .now() + nextRun.timeIntervalSinceNow)
        }

    case .hourly:
        timer.schedule(deadline: .now() + 3600, repeating: 3600)
    }

    timer.setEventHandler { [weak self] in
        self?.handleTimerFired(for: schedule)
    }

    timer.resume()
    timers[schedule.configurationId] = timer
}

private func handleTimerFired(for schedule: ScheduleInfo) {
    Task { @MainActor in
        // 检查是否应该执行
        if schedule.onlyWhenIdle && !isSystemIdle() {
            logManager.debug("系统繁忙，跳过定时同步")
            return
        }

        // 获取配置并执行同步
        if let config = getConfiguration(id: schedule.configurationId) {
            logManager.info("开始定时同步: \(config.name)")
            let result = await syncEngine.startSync(configuration: config)

            if result.isSuccess {
                logManager.info("定时同步完成")
            } else {
                logManager.error("定时同步失败")
            }
        }
    }
}
```

**时间计算**:
```swift
private func calculateNextDailyRun(time: Date?) -> Date? {
    guard let targetTime = time else { return nil }

    let calendar = Calendar.current
    let now = Date()

    // 获取目标时间的小时和分钟
    let components = calendar.dateComponents([.hour, .minute], from: targetTime)

    // 今天的目标时间
    var todayTarget = calendar.date(
        bySettingHour: components.hour!,
        minute: components.minute!,
        second: 0,
        of: now
    )!

    // 如果已经过了今天的时间，设置为明天
    if todayTarget < now {
        todayTarget = calendar.date(byAdding: .day, value: 1, to: todayTarget)!
    }

    return todayTarget
}
```

---

### 第 4 天：空闲检测和配置界面

#### 上午：系统空闲检测

**任务清单**:
- [ ] 实现空闲状态检测
- [ ] 使用 IOKit 获取空闲时间
- [ ] 设置空闲阈值
- [ ] 测试检测准确性

**空闲检测**:
```swift
// Utils/SystemIdleDetector.swift
import IOKit
import IOKit.pwr_mgt

class SystemIdleDetector {
    private static let idleThreshold: TimeInterval = 300 // 5分钟

    static func isSystemIdle() -> Bool {
        var idleTime: mach_port_t = 0

        if IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &idleTime
        ) != KERN_SUCCESS {
            return false
        }

        var properties: Unmanaged<CFMutableDictionary>?

        if IORegistryEntryCreateCFProperties(
            idleTime,
            &properties,
            kCFAllocatorDefault,
            0
        ) == KERN_SUCCESS,
           let dict = properties?.takeRetainedValue() as? [String: Any],
           let hidIdleTime = dict["HIDIdleTime"] as? UInt64 {

            let idleSeconds = TimeInterval(hidIdleTime) / 1_000_000_000.0
            return idleSeconds >= idleThreshold
        }

        return false
    }

    static func getIdleTime() -> TimeInterval {
        // 类似实现，返回实际空闲时间
        return 0
    }
}
```

---

#### 下午：配置界面

**任务清单**:
- [ ] 扩展 SyncConfigView
- [ ] 添加定时设置面板
- [ ] 实现时间选择器
- [ ] 添加预览下次运行

**界面设计**:
```swift
// Views/SchedulingSettingsView.swift
struct SchedulingSettingsView: View {
    @Binding var configuration: SyncConfiguration

    var body: some View {
        Form {
            Section("定时同步") {
                Toggle("启用定时同步", isOn: $configuration.schedulingEnabled)

                if configuration.schedulingEnabled {
                    Picker("同步频率", selection: $configuration.schedulingType) {
                        Text("间隔时间").tag(SchedulingType.interval)
                        Text("每小时").tag(SchedulingType.hourly)
                        Text("每天").tag(SchedulingType.daily)
                        Text("每周").tag(SchedulingType.weekly)
                    }

                    switch configuration.schedulingType {
                    case .interval:
                        intervalSettings

                    case .daily:
                        dailySettings

                    case .weekly:
                        weeklySettings

                    case .hourly:
                        EmptyView()
                    }

                    Toggle("仅在系统空闲时同步", isOn: $configuration.onlyWhenIdle)
                        .help("当系统空闲超过 5 分钟时才执行同步")

                    // 下次运行时间预览
                    if let nextRun = calculateNextRun() {
                        HStack {
                            Image(systemName: "clock")
                            Text("下次同步: \(nextRun.formatted())")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }

    private var intervalSettings: some View {
        HStack {
            Text("每")
            TextField("间隔", value: $intervalMinutes, format: .number)
                .frame(width: 60)
            Text("分钟同步一次")
        }
    }

    private var dailySettings: some View {
        DatePicker(
            "每天",
            selection: $dailyTime,
            displayedComponents: .hourAndMinute
        )
    }

    private var weeklySettings: some View {
        VStack(alignment: .leading) {
            Picker("星期", selection: $selectedWeekday) {
                ForEach(Weekday.allCases) { day in
                    Text(day.displayName).tag(day)
                }
            }

            DatePicker(
                "时间",
                selection: $weeklyTime,
                displayedComponents: .hourAndMinute
            )
        }
    }
}
```

---

### 第 5 天：测试和优化

#### 全天：综合测试

**测试清单**:

**菜单栏测试**:
- [ ] 图标显示正确
- [ ] 状态更新及时
- [ ] 动画流畅
- [ ] 菜单响应快速
- [ ] 通知正常工作
- [ ] 深色模式兼容

**定时同步测试**:
- [ ] 间隔定时准确
- [ ] 每日定时准确
- [ ] 每周定时准确
- [ ] 空闲检测准确
- [ ] 系统休眠后恢复正常
- [ ] 多个定时任务不冲突

**集成测试**:
- [ ] 菜单栏显示定时状态
- [ ] 定时同步触发通知
- [ ] 定时失败正确处理
- [ ] 配置修改立即生效

**性能测试**:
- [ ] 菜单打开无延迟
- [ ] 状态更新不阻塞 UI
- [ ] 定时器不占用过多资源
- [ ] 长时间运行稳定

---

## 📦 交付物

### 代码文件

```
FolderSyncPro/FolderSyncPro/
├── App/
│   └── MenuBarController.swift         (新建)
├── Services/
│   ├── SyncScheduler.swift             (新建)
│   └── NotificationManager.swift       (新建)
├── Utils/
│   └── SystemIdleDetector.swift        (新建)
├── Views/
│   └── SchedulingSettingsView.swift    (新建)
└── Models/
    └── ScheduleInfo.swift               (新建)
```

### 修改文件

```
- App/FolderSyncProApp.swift             (集成 MenuBarController)
- App/AppDelegate.swift                  (移除重复功能)
- Models/SyncConfiguration.swift         (添加定时字段)
- Views/SyncConfigView.swift             (添加定时设置标签)
```

### 资源文件

```
- Resources/Assets.xcassets/
  └── MenuBarIcons/                      (新建菜单栏图标)
      ├── idle.png
      ├── syncing.png
      ├── error.png
      └── paused.png
```

---

## 🧪 测试用例

### 菜单栏测试用例

```swift
// FolderSyncProTests/MenuBarControllerTests.swift
class MenuBarControllerTests: XCTestCase {
    var controller: MenuBarController!

    func testMenuBarCreation() {
        XCTAssertNotNil(controller.statusItem)
        XCTAssertNotNil(controller.menu)
    }

    func testStatusUpdate() {
        controller.updateStatus(.syncing)
        XCTAssertEqual(controller.currentIcon, .syncing)
    }

    func testQuickActions() {
        controller.startAllSync()
        // 验证所有配置开始同步
    }
}
```

### 定时器测试用例

```swift
// FolderSyncProTests/SyncSchedulerTests.swift
class SyncSchedulerTests: XCTestCase {
    var scheduler: SyncScheduler!

    func testIntervalScheduling() async {
        let expectation = expectation(description: "Timer fired")

        scheduler.addSchedule(for: testConfig)

        await fulfillment(of: [expectation], timeout: 65)
    }

    func testIdleDetection() {
        XCTAssertTrue(SystemIdleDetector.isSystemIdle())
    }
}
```

---

## 📊 进度跟踪

### Day 1: 菜单栏集成
- [⏳] 上午: MenuBarController 创建
- [⏳] 下午: 菜单项和事件处理

### Day 2: 状态和通知
- [⏳] 上午: 实时状态更新
- [⏳] 下午: 通知集成

### Day 3: 定时器框架
- [⏳] 上午: SyncScheduler 创建
- [⏳] 下午: 定时逻辑实现

### Day 4: 空闲检测和界面
- [⏳] 上午: 空闲检测
- [⏳] 下午: 配置界面

### Day 5: 测试和优化
- [⏳] 全天: 综合测试和 Bug 修复

---

## 🎯 验收标准

### 功能完整性
- [x] 菜单栏图标显示正确
- [x] 所有快捷操作可用
- [x] 通知正常发送
- [x] 定时同步准确触发
- [x] 空闲检测工作正常

### 性能要求
- [x] 菜单打开 < 100ms
- [x] 状态更新 < 50ms
- [x] 定时精度 ± 5 秒
- [x] CPU 使用 < 1%（空闲时）
- [x] 内存占用 < 50MB

### 用户体验
- [x] 界面响应快速
- [x] 操作流畅无卡顿
- [x] 错误提示清晰
- [x] 图标动画流畅

---

## 🚀 部署计划

### Beta 测试
1. 构建 Beta 版本
2. 发布到测试用户
3. 收集反馈
4. 快速修复问题

### 正式发布
1. 完成所有测试
2. 更新文档
3. 发布 v1.1.0
4. 发布公告

---

**准备开始第一阶段了吗？** 🚀
