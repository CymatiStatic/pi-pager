# Changelog

All notable changes to pi-notify are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-04-24

### Added
- **Cross-platform `notify.sh`** — macOS (afplay + osascript) and Linux (notify-send) parity with Windows version
- **Telegram bot channel** — post via Bot API with chat_id
- **Pushover channel** — priority 1 on errors (auto-bypass DND)
- **`-Wait` flag** — block until phone replies on ntfy; exit code maps yes/no/timeout
- **PowerShell module** (`module/PiNotify.psm1`, `PiNotify.psd1`) — `Send-PiNotify`, `Get-PiInbox`, `Get-PiDaemonStatus`, `Stop-PiDaemon`
- **Scoop manifest** (`packaging/scoop/pi-notify.json`)
- **Homebrew formula** (`packaging/homebrew/pi-notify.rb`)
- **Logo + social banner** (`assets/logo-*.png`, `social-1280x640.png`) — generated via Pillow
- **CHANGELOG.md** + **CONTRIBUTING.md**
- **Known Issues** and **Troubleshooting** sections in README

### Changed
- `notify.config.example.json` now includes `telegram` and `pushover` stubs
- README completely rewritten with badges, install tracks per platform, channel setup guides

### Fixed
- `$Type:` PowerShell parser ambiguity → use `${Type}`
- `@$tmpFile` splatting conflict with curl file-upload syntax → build string explicitly

## [0.1.0] — 2026-04-24

### Added
- Initial release
- Synchronous WAV playback via `Media.SoundPlayer.PlaySync()`
- Windows toast via BurntToast with registered `PiAgent` AppId
- ntfy.sh push (phone / watch) with priority + tags
- Background streaming daemon (`inbox-daemon.ps1`) with auto-reconnect
- `inbox.ps1` reader (local log or network fallback)
- Auto project tagging (walks to `.git` root)
- Per-project overrides via `.pi-notify.json`
- Optional Discord + Slack webhook channels
- `install.ps1` / `uninstall.ps1`
- Auto-start via Windows Startup folder
- Drop-in agent prompts for Pi, Claude Code, Cursor
- PSScriptAnalyzer + parse-check CI workflow

[0.2.0]: https://github.com/CymatiStatic/pi-notify/releases/tag/v0.2.0
[0.1.0]: https://github.com/CymatiStatic/pi-notify/releases/tag/v0.1.0
