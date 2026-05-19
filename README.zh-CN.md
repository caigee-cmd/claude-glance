# Claude Petty

[English](README.md) | [简体中文](README.zh-CN.md)

一个原生 macOS 菜单栏应用，用来实时查看 Claude Code 活动和轻量统计。

---

## 🛠️ 支持的工具

Claude Petty 监控来自多个 Claude 接口的活动：

| | | |
|:-:|:-:|:-:|
| **Claude Code** | **Codex** | **kimi-cli** |
| 原生 IDE 集成 | 扩展代码智能 | CLI 工具 |

所有活动都通过被动读取本地 `~/.claude/projects/` 实现，无需任何修改。

---

## 🎯 概览

**Claude Petty** 被动监控你本地的 Claude 开发活动，显示在菜单栏中。

- 🪟 **菜单栏快览** — 实时查看今日会话、完成任务和总耗时
- 📊 **活动面板** — 轻量本地统计，了解你的 Claude 使用模式
- 🎭 **动画挂件** — 25+ 种可爱的动画挂件，陪伴你的编码旅程
- ⚙️ **零配置** — 从 `~/.claude/projects/` 被动读取，无需安装任何 Hook
- 🔒 **隐私优先** — 完全本地运行，零遥测，零云端上传

---

## ✨ 功能特性

### 实时活动监控

直接从菜单栏监控活跃的 Claude Code 会话。查看当前正在处理的项目和每个会话的运行时长。

### 丰富的挂件自定义

从 25+ 种动画挂件中选择，配合 8 级尺寸调节：
- **样式**: 猫、兔子、狗、动画人物等多种选择
- **尺寸**: 从极小到巨大，满足各种工作空间需求

### 会话过滤和导出

- 按来源过滤活动（Claude Code、Codex、kimi-cli）
- 将活动数据导出为 CSV 或 JSON 进行进一步分析
- 按项目分组的时间轴，更清晰的视图

---

## 🎬 演示

![Claude Petty 演示](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/claude-glance-demo.gif)

快速浏览菜单栏概览、统计面板和挂件设置。

[🎥 观看高清 MP4 演示](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/claude-glance-demo.mp4)

---

## 📸 界面预览

### 菜单栏面板

实时查看今日统计、活跃任务和最近完成的任务。

![菜单栏面板](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/menupannel.png)

### 挂件设置

在应用内配置浮动挂件的样式和大小。

<table>
  <tr>
    <td width="50%"><img src="https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/settingpannel-cat-floting.png" alt="浮动挂件设置" /></td>
    <td width="50%"><img src="https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/settingpannel-cat-play-guitart.png" alt="紧凑挂件设置" /></td>
  </tr>
  <tr>
    <td align="center"><sub>浮动挂件</sub></td>
    <td align="center"><sub>紧凑挂件</sub></td>
  </tr>
</table>

---

## 📥 安装

### 从发布版本安装

1. 从 [GitHub Releases](https://github.com/caigee-cmd/claude-petty/releases) 下载最新版本
2. 打开 DMG 或解压得到 `ClaudeGlance.app`
3. 拖到 `/Applications` 文件夹
4. 从应用程序或 Spotlight 启动

⚠️ **首次启动**: macOS 会拦截，点击 `系统设置 > 隐私和安全` 中的 **"仍要打开"**。

### 从源码构建

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

## 🔒 隐私和安全

Claude Petty **完全本地运行**，对所有访问完全透明：

| 项目 | 行为 |
|------|------|
| **读取** | 仅 `~/.claude/projects/` 下的 transcript 和 session 数据 |
| **写入** | `~/Library/Application Support/ClaudeDash/`（应用状态） |
| **网络** | ❌ 永不连接互联网 |
| **账号** | ❌ 无需登录，无需认证 |
| **遥测** | ❌ 零遥测，零分析 |
| **Claude 配置** | ❌ 不修改 `~/.claude/settings.json` |

---

## ⚠️ 当前限制

- ✅ macOS 14+
- ❌ 未签名（首次启动需手动放行）
- ❌ 未 notarize
- ❌ 暂无自动更新
- ✅ 只读，被动监控

---

## 🔧 开发

本地构建和测试：

```bash
cd claude-petty
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
./scripts/build-release.sh
./scripts/build-dmg.sh
```

### 文档

- [发布指南](docs/releasing.md) — 如何发布新版本
- [开源发布检查清单](docs/open-source-release-checklist.md) — 发布检查清单
- [贡献指南](CONTRIBUTING.md) — 如何贡献
- [安全说明](SECURITY.md) — 安全政策
- [支持说明](SUPPORT.md) — 获取帮助

---

## 📄 许可

[MIT](LICENSE) — 自由使用和修改。

---

## 🙋 获取帮助

- 📧 邮箱: [522caiji@gmail.com](mailto:522caiji@gmail.com)
- 🐛 问题: [GitHub Issues](https://github.com/caigee-cmd/claude-petty/issues)
- 💬 讨论: [GitHub Discussions](https://github.com/caigee-cmd/claude-petty/discussions)

---

为 Claude Code 用户制作 ❤️
