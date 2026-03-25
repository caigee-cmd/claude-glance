# Claude Glance

A native macOS menu bar app for quickly viewing Claude Code activity, sessions, and local usage stats.

一个原生 macOS 菜单栏应用，用来快速查看 Claude Code 的本地活动、会话状态和使用统计。

[Download Latest Release](#installation) · [Why Claude Glance](#why-claude-glance) · [Privacy And Data Access](#privacy-and-data-access)

---

Claude Glance gives you a quick, local-first view of what Claude Code has been doing on your machine, without adding a cloud service, account login, or heavyweight dashboard workflow.

它默认以被动模式工作：扫描本机 `~/.claude/projects/` 下的 transcript 数据，不依赖云端服务，不要求登录，也不默认修改 Claude 配置。

- Menu bar quick glance
- Active session floating panel
- Local transcript scanning
- CSV / JSON export
- No cloud dependency

## Why Claude Glance

Claude Code 的 transcript 很有价值，但原始文件并不适合日常回看。Claude Glance 想解决的是几个更直接的问题：

- 今天到底做了多少有效工作
- 最近哪些 session 花时最多、成本最高
- 当前有没有活跃会话正在运行
- 一段时间内 token、工具调用和项目分布是什么样

如果你是长期使用 Claude Code 的开发者，Claude Glance 提供的是一个本地、轻量、随手可见的观察面板，而不是新的代理层、云服务或 IDE 插件。

## Current Features

- 菜单栏常驻图标与今日完成数徽章
- Quick-glance popover，显示今日会话、成本、时长和最近完成记录
- 详细统计窗口，包含 `Overview / Tokens / Tools / Projects / Insights`
- 浮动面板，实时显示活跃 session
- 历史 transcript 扫描与本地缓存
- CSV / JSON 导出
- 纯本地存储

## Screenshots

当前仓库还没有正式截图资源。公开发布前建议补：

- 菜单栏 popover 截图
- 详细统计窗口截图
- 浮动面板截图

如果你准备做首个公开 Release，建议把截图放到 `docs/screenshots/`，并在这里直接展示。截图组织方式可参考 [docs/screenshots/README.md](docs/screenshots/README.md)。

## Who It's For

适合：

- 已经在本机使用 Claude Code 的开发者
- 希望回看本地工作量、会话轨迹和使用统计的人
- 能接受当前开发者向分发方式的人

不适合：

- 希望一键安装、无系统安全提示的普通终端用户
- 需要云端同步、团队协作或托管分析的人
- 期待它替代 Claude Code 本体的人

## Installation

### 从 Release 安装

1. 下载 `ClaudeGlance.zip`
2. 解压得到 `ClaudeGlance.app`
3. 将 `ClaudeGlance.app` 拖到 `/Applications`
4. 按下文 “First Launch on macOS” 处理首次打开

### 从源码构建

要求：

- Xcode 16 或更高版本
- macOS 14 SDK
- 可选：`xcodegen`，仅在需要重新生成工程文件时使用

```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

如果你修改了 `project.yml`，先重新生成工程：

```bash
xcodegen generate
```

## First Launch on macOS

当前公开发布物不是 Developer ID 签名，也没有 notarize。下载到另一台 Mac 时，首次打开可能会被 Gatekeeper 拦截。

如果被阻止：

1. 在 Finder 中右键 `ClaudeGlance.app`
2. 选择 `Open`
3. 如果仍被阻止，前往 `System Settings -> Privacy & Security`
4. 在安全提示区域点击 `Open Anyway`

如果你希望“下载后直接双击即可打开”，后续版本需要接入 Apple Developer Program、Developer ID 和 notarization。

参考：

- [Safely open apps on your Mac](https://support.apple.com/en-us/102445)

## Privacy And Data Access

Claude Glance 默认只做本地读取和本地写入。

| 项目 | 当前行为 |
| --- | --- |
| 读取 | `~/.claude/projects/` 下的 transcript / session 数据 |
| 写入 | `~/Library/Application Support/ClaudeDash/`（为兼容现有版本，目录名暂未重命名） |
| 联网 | 默认不需要 |
| 账号登录 | 不需要 |
| 遥测 / Analytics | 当前不上传使用数据 |
| 修改 Claude 配置 | 默认不会自动修改 `~/.claude/settings.json` |

默认运行时，Claude Glance 只会在本地创建和更新这些文件：

- `~/Library/Application Support/ClaudeDash/sessions.json`
- `~/Library/Application Support/ClaudeDash/history-scan-cache.json`

如果你在本地自行启用或实验仓库中的增强 Hook 流程，相关代码会在写入 `~/.claude/settings.json` 之前创建时间戳备份：

- `~/.claude/settings.json.backup.<timestamp>`

更完整的安全与披露流程见 [SECURITY.md](SECURITY.md)。

## Known Limitations

当前公开版本的定位是开发者向分发，已知限制包括：

- 仅支持 macOS 14+
- 非 Developer ID 分发
- 未 notarize
- 暂无自动更新
- 依赖本机已有 Claude Code transcript 数据
- 当前没有云同步或多设备聚合能力

## Roadmap

适合公开路线图里优先列出的方向：

- Developer ID 签名与 notarization
- 更顺滑的安装与升级体验
- 更完整的截图和演示素材
- 更稳定的发布自动化流程
- 更清晰的设置与权限说明

## Project Structure

```text
claude-glance/
├── ClaudeDash/
│   ├── Sources/
│   ├── Resources/
│   └── ...
├── ClaudeDashHelper/
├── ClaudeDashTests/
├── Shared/
├── docs/
├── scripts/
└── project.yml
```

## Development

常用命令：

```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash

xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
```

本地打包 unsigned Release：

```bash
cd /Users/cj/Documents/personal/project/claudenotification/ClaudeDash
chmod +x scripts/build-release.sh
./scripts/build-release.sh
```

产物位置：

- `dist/ClaudeGlance.app`
- `dist/ClaudeGlance.zip`

脚本会同时输出 `ClaudeGlance.zip` 的 SHA-256 校验值。

维护者发布流程见 [docs/releasing.md](docs/releasing.md)。

如果你在做首次公开发布，建议再对照 [docs/open-source-release-checklist.md](docs/open-source-release-checklist.md) 逐项检查。

## Troubleshooting

### App 被 macOS 阻止启动

这是当前 unsigned build 的预期表现。按上文 “First Launch on macOS” 的步骤手动允许。

### 打开后看不到任何 session

先确认：

- 你本机确实在使用 Claude Code
- `~/.claude/projects/` 下已经有 transcript 文件
- Claude Glance 有权限读取相关目录

### 统计看起来不对或没有刷新

可以先尝试：

- 退出再重新打开 Claude Glance
- 重新运行一轮 Claude Code 任务，让新的 transcript 被扫描到
- 删除 `~/Library/Application Support/ClaudeDash/history-scan-cache.json` 后重启应用，让它重新建立缓存

### 你在本地实验过增强 Hook 流程

如果你手动启用了增强模式或修改了 `~/.claude/settings.json`，排障时请同时检查：

- `~/.claude/settings.json`
- `~/.claude/settings.json.backup.*`

## Contributing

欢迎 Issue、文档修正和 PR。开始之前建议先看：

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- [SUPPORT.md](SUPPORT.md)

## Uninstall

卸载当前公开版本：

1. 删除 `ClaudeGlance.app`
2. 删除本地数据目录

```bash
rm -rf ~/Library/Application\ Support/ClaudeDash
```

如果你曾手动启用过增强 Hook 路径，还应：

- 从 `~/.claude/settings.json` 删除对应 Hook 条目
- 或用 `settings.json.backup.*` 恢复原始配置

## License

[MIT](LICENSE)
