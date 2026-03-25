# ClaudeDash Open Source P0 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 ClaudeDash 以“开发者用户可自行下载安装和排障”的标准完成首次公开发布，不依赖 Apple Developer Program、Developer ID、notarization 或自动更新。

**Architecture:** 保持当前“源码仓库 + 外部分发 unsigned app”的路线。P0 只解决真实文档、稳定构建、基础测试、可重复打包和发布说明，不引入 Sparkle、签名、公证等会放大维护成本的能力。

**Tech Stack:** Swift 6, SwiftUI/AppKit, XcodeGen, xcodebuild, shell script, GitHub Actions

---

### Task 1: 对齐对外文档与真实产品范围

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Step 1: 盘点当前真实功能**

检查这些文件中的事实来源：
- `ClaudeDash/Sources/DashboardView.swift`
- `ClaudeDash/Sources/StatsDetailView.swift`
- `ClaudeDash/Sources/StatusBarPopoverView.swift`
- `ClaudeDash/Sources/FloatingPanelView.swift`
- `ClaudeDash/Sources/HookInstaller.swift`

目标：
- 确认当前公开功能是 2 个 Dashboard Tab，5 个 Stats Tab
- 确认 Settings 已移除，不再对外宣传
- 确认通知能力当前主要由 `ClaudeDashHelper` 执行

**Step 2: 重写 `README.md` 的开头和功能列表**

必须覆盖这些段落：
- 项目定位：macOS 状态栏工具，监控 Claude Code 完成通知和本地统计
- 当前功能：状态栏 Popover、Stats 窗口、浮动面板、Hook 安装、历史扫描、导出
- 当前限制：仅 macOS 14+；当前发布为 unsigned build；首次打开可能需手动允许

删掉或改写这些过时信息：
- `SettingsTab.swift`
- “概览 / 设置 / 实时监控三个 Tab”
- 旧的“新建 Xcode 项目步骤”
- `com.yourname.claudedash`

**Step 3: 为 README 增加开发者用户真正需要的说明**

新增这些小节：
- `Installation`
- `First Launch on macOS`
- `Privacy`
- `What ClaudeDash changes`
- `Uninstall`
- `Troubleshooting`

每节至少包含以下事实：
- 安装产物来自 GitHub Release 的 `.zip` 或本地构建
- unsigned app 首次打开要去“系统设置 -> 隐私与安全”允许
- 应用会读取 `~/.claude/projects/`
- Hook 安装会修改 `~/.claude/settings.json` 并创建带时间戳备份
- 卸载时如何删除 app、清理 `~/Library/Application Support/ClaudeDash/`、恢复 Hook

**Step 4: 修正 `CHANGELOG.md` 的版本描述**

把已失真的条目改成真实状态：
- 删掉或标记移除 `Settings Tab`
- 删掉未确认仍可用的通知自定义描述
- 增加 “Changed” 或 “Removed” 区块描述当前 UI 架构

**Step 5: 运行文档回归检查**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
rg -n "SettingsTab|com\\.yourname|三个 Tab|设置 Tab" README.md CHANGELOG.md ClaudeDash
```

Expected:
- README / CHANGELOG 中不再出现旧功能或占位符

**Step 6: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: align public docs with current product scope"
```

### Task 2: 统一共享配置标识，移除占位符

**Files:**
- Modify: `ClaudeDash/Sources/Models.swift`
- Modify: `ClaudeDashHelper/main.swift`
- Modify: `README.md`

**Step 1: 先确认旧占位符只剩这些位置**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
rg -n "com\\.yourname\\.claudedash" .
```

Expected:
- 命中 `Models.swift`
- 命中 `ClaudeDashHelper/main.swift`
- 可能命中 README

**Step 2: 将共享 defaults domain 改为正式值**

目标值：
```swift
"com.claudedash.shared"
```

需要同时修改：
- `ClaudeDash/Sources/Models.swift`
- `ClaudeDashHelper/main.swift`

**Step 3: 在 README 记录迁移影响**

如果旧版本已经写入过 `com.yourname...` 域，README 需要加一句：
- 早期测试构建升级后会自动迁移支持的设置项

**Step 4: 验证占位符已清理**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
rg -n "com\\.yourname\\.claudedash" .
```

Expected:
- 无结果

**Step 5: Build**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

Expected:
- `** BUILD SUCCEEDED **`

**Step 6: Commit**

```bash
git add ClaudeDash/Sources/Models.swift ClaudeDashHelper/main.swift README.md
git commit -m "fix: replace placeholder shared defaults identifier"
```

### Task 3: 恢复测试绿灯，先修浮动面板布局回归

**Files:**
- Modify: `ClaudeDashTests/FloatingPanelLayoutTests.swift`
- Modify: `ClaudeDash/Sources/FloatingPanelLayout.swift` if needed

**Step 1: 先以当前实现为基准确认意图**

读取这些文件并对照项目记忆中的布局约束：
- `ClaudeDash/Sources/FloatingPanelLayout.swift`
- `ClaudeDashTests/FloatingPanelLayoutTests.swift`

当前实现事实：
- `maxVisibleSessions = 3`
- `rowHeight = 28`
- `rowSpacing = 4`
- `verticalPadding = 6`

由此推导：
- 空态和 1 行高度应为 `40`
- 3 行高度应为 `104`
- 总 session 数超过 3 时仍只显示 3 行

**Step 2: 先跑单测确认失败**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS" -only-testing:ClaudeDashTests/FloatingPanelLayoutTests
```

Expected:
- 当前失败，且失败点在可见行数和高度断言

**Step 3: 用最小改动修正测试或实现**

优先策略：
- 如果记忆和当前 UI 设计都确认“最多 3 行”，则更新测试
- 只有在 UI 真正想恢复到 4 行时，才修改 `FloatingPanelLayout.swift`

推荐断言值：
```swift
XCTAssertEqual(FloatingPanelLayout.visibleSessionCount(forTotalSessionCount: 4), 3)
XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 0), 40, accuracy: 0.1)
XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 1), 40, accuracy: 0.1)
XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 3), 104, accuracy: 0.1)
XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 10), 104, accuracy: 0.1)
```

**Step 4: 跑完整测试**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

Expected:
- 所有测试通过

**Step 5: Commit**

```bash
git add ClaudeDashTests/FloatingPanelLayoutTests.swift ClaudeDash/Sources/FloatingPanelLayout.swift
git commit -m "test: fix floating panel layout expectations"
```

### Task 4: 增加可重复的本地发布脚本

**Files:**
- Create: `scripts/build-release.sh`
- Modify: `README.md`

**Step 1: 确定 P0 发布产物格式**

P0 只做这两种：
- `ClaudeDash.app`
- `ClaudeDash.zip`

不要在 P0 做：
- Sparkle appcast
- notarization
- Developer ID signing
- 自动生成 DMG

原因：
- 对开发者用户，`.zip` 已足够
- unsigned `dmg` 不比 unsigned `zip` 更可信

**Step 2: 编写发布脚本**

脚本职责：
- 清理旧的 `dist/`
- 用 `xcodebuild` 构建 `Release`
- 复制 `ClaudeDash.app` 到 `dist/`
- 生成 `dist/ClaudeDash.zip`
- 输出 `shasum -a 256` 校验值

脚本最少应包含这些命令：
```bash
xcodebuild build \
  -project ClaudeDash.xcodeproj \
  -scheme ClaudeDash \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  -destination "platform=macOS"
ditto -c -k --sequesterRsrc --keepParent "dist/ClaudeDash.app" "dist/ClaudeDash.zip"
shasum -a 256 "dist/ClaudeDash.zip"
```

**Step 3: 在 README 写明发布和本地打包命令**

README 至少要有：
- 本地构建命令
- 本地打包命令
- Release 产物位置
- Gatekeeper 提示属于预期现象

**Step 4: 本地验证**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
chmod +x scripts/build-release.sh
./scripts/build-release.sh
ls -la dist
```

Expected:
- `dist/ClaudeDash.app`
- `dist/ClaudeDash.zip`

**Step 5: Commit**

```bash
git add scripts/build-release.sh README.md
git commit -m "build: add local unsigned release packaging script"
```

### Task 5: 加入最小 CI，保证公开仓库不是“红灯”

**Files:**
- Create: `.github/workflows/ci.yml`

**Step 1: 新建最小 CI workflow**

CI 只做两件事：
- Build
- Test

推荐触发：
- `push`
- `pull_request`

推荐运行环境：
```yaml
runs-on: macos-14
```

核心命令：
```yaml
- name: Build
  run: xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"

- name: Test
  run: xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

**Step 2: 本地做一次 workflow 内容自检**

检查点：
- 路径基于仓库根目录 `ClaudeDash/`
- 没有依赖本地证书
- 没有要求 notarization 或签名

**Step 3: 推送后观察 GitHub Actions**

Expected:
- PR 页面出现 CI 状态
- 默认分支保持绿色

**Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add macOS build and test workflow"
```

### Task 6: 增加开发者用户发布说明和人工发布清单

**Files:**
- Create: `docs/releasing.md`
- Modify: `README.md`

**Step 1: 写 `docs/releasing.md`**

内容至少包含：
- 发布前检查：工作区干净、测试通过、README/CHANGELOG 已更新
- 如何运行 `./scripts/build-release.sh`
- 如何上传 `dist/ClaudeDash.zip` 到 GitHub Release
- Release notes 最少应写什么
- 如何验证 zip 校验值

**Step 2: 在 README 增加“Release Status”说明**

直接告诉用户：
- 当前提供的是 unsigned build
- 面向熟悉 macOS 安全提示的开发者用户
- 暂未提供自动更新
- 暂未 notarize

**Step 3: 增加“首次打开”排障文案**

至少覆盖：
- Finder 双击被拦时怎么办
- 右键 Open 或去系统设置放行
- 如果 Hook 没生效，要检查 `~/.claude/settings.json`

**Step 4: 文档串联验证**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
rg -n "unsigned|notarize|Gatekeeper|Open Anyway|settings.json|Application Support" README.md docs/releasing.md
```

Expected:
- 关键信息都能在文档中直接搜到

**Step 5: Commit**

```bash
git add README.md docs/releasing.md
git commit -m "docs: add developer-focused release and install guidance"
```

### Task 7: 首次公开发布前的最终验收

**Files:**
- Verify only

**Step 1: 全量验证**

Run:
```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
./scripts/build-release.sh
```

Expected:
- 测试全绿
- `dist/ClaudeDash.zip` 生成成功

**Step 2: 进行一次“陌生机器视角”检查**

人工检查清单：
- README 前 60 秒内能理解产品是什么
- 用户知道 app 会读哪些目录、改哪些配置
- 用户知道如何卸载和恢复 Hook
- 用户知道为什么会看到 Gatekeeper 提示

**Step 3: 创建 GitHub Release**

Release body 最少包括：
- 当前版本功能范围
- 已知限制：unsigned、not notarized、无自动更新
- 安装说明链接
- 校验值

**Step 4: 发布后观察首批反馈**

优先收集的问题类型：
- 打不开 app
- Hook 安装失败
- 未收到通知
- 浮动面板或 Popover 布局问题
- 大目录扫描性能

**Step 5: 发布后立即整理 P1 backlog**

P1 候选项：
- Developer ID + notarization
- DMG 分发
- Sparkle 自动更新
- 更完整的权限/诊断 UI
- 发布截图和演示视频

