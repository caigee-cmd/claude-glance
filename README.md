# ClaudeDash

原生 macOS 状态栏应用，用于监控 Claude Code 任务完成通知和工作统计。

## 功能特性

- **状态栏常驻** — SF Symbol sparkles 图标 + 今日完成次数动态徽章
- **毛玻璃仪表盘** — 概览统计 / 设置 / 实时监控三个 Tab
- **一键安装 Hook** — 自动配置 Claude Code Stop Hook，零手动操作
- **原生通知** — 自定义模板、声音、智能总结
- **实时监控** — DispatchSource 监听 transcript.jsonl，追踪活跃 session
- **本地统计** — 今日/30天历史数据，Swift Charts 柱状图

## 技术栈

- Swift 6 + SwiftUI + AppKit
- 纯原生框架（UserNotifications, Swift Charts, Foundation）
- 无任何第三方依赖
- 体积约 5MB

## 项目结构

```
ClaudeDash/
├── ClaudeDash/
│   ├── Sources/
│   │   ├── ClaudeDashApp.swift      # @main 入口
│   │   ├── Models.swift             # 共享数据模型
│   │   ├── StatusBarController.swift # 状态栏控制器
│   │   ├── StatsManager.swift       # 统计管理器
│   │   ├── DashboardView.swift      # 仪表盘主视图
│   │   ├── OverviewTab.swift        # 概览 Tab
│   │   ├── SettingsTab.swift        # 设置 Tab
│   │   ├── MonitorTab.swift         # 实时监控 Tab
│   │   ├── HookInstaller.swift      # Hook 安装器
│   │   ├── NotificationSender.swift # 通知发送器
│   │   ├── TranscriptParser.swift   # JSONL 解析器
│   │   └── SessionMonitor.swift     # 文件监控器
│   └── Resources/
│       └── Info.plist               # 应用配置
├── ClaudeDashHelper/
│   └── main.swift                   # CLI 工具入口
└── README.md
```

## 新建 Xcode 项目步骤

### 1. 创建主 App Target

1. 打开 Xcode → File → New → Project
2. 选择 **macOS → App**
3. 填写：
   - Product Name: `ClaudeDash`
   - Bundle Identifier: `com.yourname.claudedash`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. 选择保存位置，创建项目

### 2. 添加 Helper Target

1. File → New → Target
2. 选择 **macOS → Command Line Tool**
3. 填写：
   - Product Name: `ClaudeDashHelper`
   - Language: **Swift**
4. 点击 Finish

### 3. 将 Helper 嵌入 App Bundle

1. 选择 `ClaudeDash` target → Build Phases
2. 点击 **+** → New Copy Files Phase
3. 设置：
   - Destination: **Executables**（或选择 Wrapper → 子路径填 `Contents/MacOS`）
4. 点击 **+** 添加 `ClaudeDashHelper` 产品

### 4. 粘贴代码

1. 删除 Xcode 自动生成的 `ContentView.swift` 和 `ClaudeDashApp.swift`
2. 将 `ClaudeDash/Sources/` 下所有 `.swift` 文件拖入 Xcode 的 ClaudeDash target
3. 将 `ClaudeDashHelper/main.swift` 替换 Helper target 的 `main.swift`
4. 将 `Resources/Info.plist` 替换项目的 Info.plist

### 5. 配置 Info.plist

确保以下配置正确：
- `LSUIElement` = `YES`（不在 Dock 显示）
- Bundle Identifier 一致

### 6. 编译运行

1. 选择 `ClaudeDash` scheme
2. Product → Build (⌘B)
3. Product → Run (⌘R)
4. 状态栏出现 ✨ 图标即成功

## 测试步骤

### 1. 基础功能测试

```bash
# 启动 App 后检查状态栏图标
# 点击图标 → 应出现菜单

# 点击「打开仪表盘」→ 应弹出毛玻璃窗口
# 关闭窗口 → App 应继续在状态栏运行

# 点击「测试通知」→ 应收到系统通知
```

### 2. Hook 安装测试

```bash
# 点击「一键安装 Hook」
# 检查备份文件
ls ~/.claude/settings.json.backup.*

# 检查 Hook 配置
cat ~/.claude/settings.json | python3 -m json.tool
# 应看到 hooks.Stop 数组中有 ClaudeDashHelper 条目
```

### 3. Helper 手动测试

```bash
# 模拟 Claude Code 调用 Helper
echo '{
  "last_assistant_message": "任务已完成，创建了 3 个文件。",
  "cwd": "/Users/you/project",
  "total_duration_ms": 30000,
  "cost": 0.0234,
  "transcript_path": "/tmp/test-transcript.jsonl"
}' | /path/to/ClaudeDash.app/Contents/MacOS/ClaudeDashHelper

# 应收到通知，并在 ~/Library/Application Support/ClaudeDash/sessions.json 中看到记录
```

### 4. 实时监控测试

```bash
# 创建测试 transcript 文件
echo '{"role":"assistant","content":"正在分析代码..."}' > /tmp/test-transcript.jsonl

# 在 App 监控 Tab 中应看到 session 出现

# 追加新行测试实时更新
echo '{"role":"assistant","content":[{"type":"tool_use","name":"Read"}]}' >> /tmp/test-transcript.jsonl
```

## 打包发布

```bash
# Xcode 打包
# Product → Archive → Distribute App → Copy App

# 或使用命令行
xcodebuild archive \
  -scheme ClaudeDash \
  -archivePath build/ClaudeDash.xcarchive

xcodebuild -exportArchive \
  -archivePath build/ClaudeDash.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

## 数据存储位置

| 数据 | 路径 |
|------|------|
| 统计设置 | `UserDefaults (com.yourname.claudedash)` |
| Session 记录 | `~/Library/Application Support/ClaudeDash/sessions.json` |
| 历史数据 | `~/Library/Application Support/ClaudeDash/history.json` |
| Hook 配置 | `~/.claude/settings.json` |
| 配置备份 | `~/.claude/settings.json.backup.*` |

## 许可证

MIT License
