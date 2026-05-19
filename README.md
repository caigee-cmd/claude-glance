# Claude Petty

[English](README.md) | [简体中文](README.zh-CN.md)

A native macOS menu bar app for viewing Claude Code activity and lightweight stats.

---

## 🛠️ Supported Tools

Claude Petty monitors activity from multiple Claude interfaces:

| | | |
|:-:|:-:|:-:|
| **Claude Code** | **Codex** | **kimi-cli** |
| IDE Integration | Code Intelligence | CLI Tool |

All activity is passively read from local `~/.claude/projects/` — no modifications required.

---

## 🎯 Overview

**Claude Petty** passively monitors your local Claude development activity in the menu bar.

- 🪟 **Menu Bar Stats** — Quick glance at today's sessions, completions, and time spent
- 📊 **Activity Dashboard** — Lightweight stats dashboard for your Claude usage patterns  
- 🎭 **Animated Mascots** — 25+ adorable mascot animations to keep you company
- ⚙️ **Zero Setup** — Reads from `~/.claude/projects/` with no hooks or configuration required
- 🔒 **Privacy-First** — Runs entirely locally, zero telemetry, zero cloud uploads

---

## ✨ Features

### Real-time Activity Monitoring

Monitor active Claude Code sessions directly from the menu bar. See which projects you're actively working on and how long each session has been running.

### Rich Mascot Customization

Choose from 25+ animated mascots with fine-grained size controls:
- **Appearances**: Cat, bunny, dog, anime characters, and more
- **Sizes**: 8 size levels from micro to jumbo for any workspace preference

### Session Filtering & Export

- Filter activity by source (Claude Code, Codex, kimi-cli)
- Export activity data as CSV or JSON for further analysis
- View timeline grouped by project for better organization

---

## 🎬 Demo

![Claude Petty demo](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/claude-glance-demo.gif)

A quick walkthrough of the menu bar overview, stats dashboard, and mascot settings.

[🎥 Watch HD MP4 Demo](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/claude-glance-demo.mp4)

---

## 📸 Screenshots

### Menu Bar & Popover

Real-time overview of today's activity, active sessions, and recent completions.

![Menu bar popover](https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/menupannel.png)

### Mascot Customization

Configure your floating mascot style and size without leaving the app.

<table>
  <tr>
    <td width="50%"><img src="https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/settingpannel-cat-floting.png" alt="Floating mascot settings" /></td>
    <td width="50%"><img src="https://claude-glance-1390058464.cos.ap-singapore.myqcloud.com/settingpannel-cat-play-guitart.png" alt="Guitar mascot settings" /></td>
  </tr>
  <tr>
    <td align="center"><sub>Floating Mascot</sub></td>
    <td align="center"><sub>Compact Mascot</sub></td>
  </tr>
</table>

---

## 📥 Installation

### From Release

1. Download the latest `.dmg` or `ClaudeGlance.zip` from [GitHub Releases](https://github.com/caigee-cmd/claude-petty/releases)
2. Open the DMG or unzip `ClaudeGlance.app`
3. Move it to `/Applications`
4. Launch from Applications or Spotlight

⚠️ **First Launch**: macOS may block the app as it's unsigned. Click **"Open Anyway"** in `System Settings > Privacy & Security`.

### From Source

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

---

## 🔒 Privacy & Security

Claude Petty is **100% local-first** and completely transparent about what it accesses:

| Item | Behavior |
|------|----------|
| **Reads** | `~/.claude/projects/` transcript and session data only |
| **Writes** | `~/Library/Application Support/ClaudeDash/` (app state) |
| **Network** | ❌ Never connects to the internet |
| **Account** | ❌ No login, no authentication required |
| **Telemetry** | ❌ Zero telemetry, zero analytics |
| **Claude Config** | ❌ Never modifies `~/.claude/settings.json` |

---

## ⚠️ Limitations

- ✅ macOS 14+
- ❌ Unsigned build (manual allow on first launch)
- ❌ Not notarized
- ❌ No auto-update yet
- ✅ Read-only, passive monitoring

---

## 🔧 Development

Build and test locally:

```bash
cd claude-petty
xcodebuild build -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
xcodebuild test -project ClaudeDash.xcodeproj -scheme ClaudeDash -destination "platform=macOS"
./scripts/build-release.sh
./scripts/build-dmg.sh
```

### Documentation

- [Release Guide](docs/releasing.md) — How to publish a new version
- [Open Source Checklist](docs/open-source-release-checklist.md) — Release checklist
- [Contributing](CONTRIBUTING.md) — How to contribute
- [Security](SECURITY.md) — Security policy
- [Support](SUPPORT.md) — Getting help

---

## 📄 License

[MIT](LICENSE) — Free to use and modify.

---

## 🙋 Support

- 📧 Email: [522caiji@gmail.com](mailto:522caiji@gmail.com)
- 🐛 Issues: [GitHub Issues](https://github.com/caigee-cmd/claude-petty/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/caigee-cmd/claude-petty/discussions)

---

Made with ❤️ for Claude Code users.
