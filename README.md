# Claude Petty

A native macOS menu bar app for viewing Claude Code activity and lightweight stats.  
一个原生 macOS 菜单栏应用，用来实时查看 Claude Code 活动和轻量统计。

---

## 🛠️ Supported Tools | 支持的工具

Claude Petty monitors activity from multiple Claude interfaces:  
Claude Petty 监控来自多个 Claude 接口的活动：

| | | |
|:-:|:-:|:-:|
| **Claude Code** | **Codex** | **kimi-cli** |
| IDE Integration | Code Intelligence | CLI Tool |
| 原生 IDE 集成 | 扩展代码智能 | CLI 工具 |

All activity is passively read from local `~/.claude/projects/` — no modifications required.  
所有活动都通过被动读取本地 `~/.claude/projects/` 实现，无需任何修改。

---

## 🎯 Overview | 概览

**Claude Petty** passively monitors your local Claude development activity in the menu bar.

- 🪟 **Menu Bar Stats** — Quick glance at today's sessions, completions, and time spent
- 📊 **Activity Dashboard** — Lightweight stats dashboard for your Claude usage patterns  
- 🎭 **Animated Mascots** — 25+ adorable mascot animations to keep you company
- ⚙️ **Zero Setup** — Reads from `~/.claude/projects/` with no hooks or configuration required
- 🔒 **Privacy-First** — Runs entirely locally, zero telemetry, zero cloud uploads

**Claude Petty** 被动监控你本地的 Claude 开发活动，显示在菜单栏中。

- 🪟 **菜单栏快览** — 实时查看今日会话、完成任务和总耗时
- 📊 **活动面板** — 轻量本地统计，了解你的 Claude 使用模式
- 🎭 **动画挂件** — 25+ 种可爱的动画挂件，陪伴你的编码旅程
- ⚙️ **零配置** — 从 `~/.claude/projects/` 被动读取，无需安装任何 Hook
- 🔒 **隐私优先** — 完全本地运行，零遥测，零云端上传

---

## ✨ Features | 功能特性

### Real-time Activity Monitoring | 实时活动监控

Monitor active Claude Code sessions directly from the menu bar. See which projects you're actively working on and how long each session has been running.

直接从菜单栏监控活跃的 Claude Code 会话。查看当前正在处理的项目和每个会话的运行时长。

### Rich Mascot Customization | 丰富的挂件自定义

Choose from 25+ animated mascots with fine-grained size controls:
- **Appearances**: Cat, bunny, dog, anime characters, and more
- **Sizes**: 8 size levels from micro to jumbo for any workspace preference

从 25+ 种动画挂件中选择，配合 8 级尺寸调节：
- **样式**: 猫、兔子、狗、动画人物等多种选择
- **尺寸**: 从极小到巨大，满足各种工作空间需求

### Session Filtering & Export | 会话过滤和导出

- Filter activity by source (Claude Code, Codex, kimi-cli)
- Export activity data as CSV or JSON for further analysis
- View timeline grouped by project for better organization

- 按来源过滤活动（Claude Code、Codex、kimi-cli）
- 将活动数据导出为 CSV 或 JSON 进行进一步分析
- 按项目分组的时间轴，更清晰的视图

---

## 🎬 Demo | 演示

![Claude Petty demo](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/claude-glance-demo.gif)

A quick walkthrough of the menu bar overview, stats dashboard, and mascot settings.  
快速浏览菜单栏概览、统计面板和挂件设置。

[🎥 Watch HD MP4 Demo](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/claude-glance-demo.mp4)

---

## 📸 Screenshots | 界面预览

### Menu Bar & Popover | 菜单栏面板

Real-time overview of today's activity, active sessions, and recent completions.  
实时查看今日统计、活跃任务和最近完成的任务。

![Menu bar popover](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/menupannel.png)

### Mascot Customization | 挂件设置

Configure your floating mascot style and size without leaving the app.  
在应用内配置浮动挂件的样式和大小。

<table>
  <tr>
    <td width="50%"><img src="https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/settingpannel-cat-floting.png" alt="Floating mascot settings" /></td>
    <td width="50%"><img src="https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/settingpannel-cat-play-guitart.png" alt="Guitar mascot settings" /></td>
  </tr>
  <tr>
    <td align="center"><sub>Floating Mascot | 浮动挂件</sub></td>
    <td align="center"><sub>Compact Mascot | 紧凑挂件</sub></td>
  </tr>
</table>

---

## 📥 Installation | 安装

### From Release | 从发布版本

1. Download the latest `.dmg` or `ClaudeGlance.zip` from [GitHub Releases](https://github.com/caigee-cmd/claude-petty/releases)
2. Open the DMG or unzip `ClaudeGlance.app`
3. Move it to `/Applications`
4. Launch from Applications or Spotlight

⚠️ **First Launch**: macOS may block the app as it's unsigned. Click **"Open Anyway"** in `System Settings > Privacy & Security`.

从 [GitHub Releases](https://github.com/caigee-cmd/claude-petty/releases) 下载最新版本：

1. 下载 `.dmg` 或 `ClaudeGlance.zip`
2. 打开 DMG 或解压得到 `ClaudeGlance.app`
3. 拖到 `/Applications` 文件夹
4. 从应用程序或 Spotlight 启动

⚠️ **首次启动**: macOS 会拦截，点击 `系统设置 > 隐私和安全` 中的 **"仍要打开"**。

### From Source | 从源码构建

**Requirements**: Xcode 16+, macOS 14 SDK

```bash
git clone git@github.com:caigee-cmd/claude-petty.git
cd claude-petty
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

If you modify `project.yml`:
```bash
xcodegen generate
```

**需求**: Xcode 16+, macOS 14 SDK

```bash
git clone git@github.com:caigee-cmd/claude-petty.git
cd claude-petty
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

修改 `project.yml` 后：
```bash
xcodegen generate
```

---

## 🔒 Privacy & Security | 隐私和安全

Claude Petty is **100% local-first** and completely transparent about what it accesses:

Claude Petty **完全本地运行**，对所有访问完全透明：

| Item | Behavior |
|------|----------|
| **Reads** | `~/.claude/projects/` transcript and session data only |
| **Writes** | `~/Library/Application Support/ClaudeDash/` (app state) |
| **Network** | ❌ Never connects to the internet |
| **Account** | ❌ No login, no authentication required |
| **Telemetry** | ❌ Zero telemetry, zero analytics |
| **Claude Config** | ❌ Never modifies `~/.claude/settings.json` |

| 项目 | 行为 |
|------|------|
| **读取** | 仅 `~/.claude/projects/` 下的 transcript 和 session 数据 |
| **写入** | `~/Library/Application Support/ClaudeDash/`（应用状态） |
| **网络** | ❌ 永不连接互联网 |
| **账号** | ❌ 无需登录，无需认证 |
| **遥测** | ❌ 零遥测，零分析 |
| **Claude 配置** | ❌ 不修改 `~/.claude/settings.json` |

---

## ⚠️ Limitations | 当前限制

- ✅ macOS 14+
- ❌ Unsigned build (manual allow on first launch)
- ❌ Not notarized
- ❌ No auto-update yet
- ✅ Read-only, passive monitoring

- ✅ macOS 14+
- ❌ 未签名（首次启动需手动放行）
- ❌ 未 notarize
- ❌ 暂无自动更新
- ✅ 只读，被动监控

---

## 🔧 Development | 开发

Build and test locally:

本地构建和测试：

```bash
cd claude-petty
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
./scripts/build-release.sh
./scripts/build-dmg.sh
```

### Documentation | 文档

- [Release Guide](docs/releasing.md) — How to publish a new version
- [Open Source Checklist](docs/open-source-release-checklist.md) — Release checklist
- [Contributing](CONTRIBUTING.md) — How to contribute
- [Security](SECURITY.md) — Security policy
- [Support](SUPPORT.md) — Getting help

---

## 📄 License | 许可

[MIT](LICENSE) — Free to use and modify.

---

## 🙋 Support | 获取帮助

- 📧 Email: [522caiji@gmail.com](mailto:522caiji@gmail.com)
- 🐛 Issues: [GitHub Issues](https://github.com/caigee-cmd/claude-petty/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/caigee-cmd/claude-petty/discussions)

---

Made with ❤️ for Claude Code users.
