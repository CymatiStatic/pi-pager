# Changelog

All notable changes to pi-pager are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] — 2026-04-24

### Changed (BREAKING)
- **Project renamed**: `pi-notify` → `pi-pager`. The "pager" mental model is
  clearer for async out-of-band notifications.
- **Repo URL**: `github.com/CymatiStatic/pi-notify` → `github.com/CymatiStatic/pi-pager`
  (GitHub auto-redirects the old URL).
- **Data dir**: `~/.pi-notify/` → `~/.pi-pager/` (preserves config + ntfy topic;
  install.ps1 auto-migrates if old dir exists).
- **PowerShell module**: `PiNotify` → `PiPager`. Cmdlets renamed:
  - `Send-PiNotify` → `Send-PiPage`
  - `Get-PiInbox` → `Get-PiPagerInbox`
  - `Get-PiDaemonStatus` → `Get-PiPagerDaemonStatus`
  - `Stop-PiDaemon` → `Stop-PiPagerDaemon`
- **Startup shortcut**: `pi-notify daemon.lnk` → `pi-pager daemon.lnk`
- **Config filename**: `notify.config.example.json` → `pi-pager.config.example.json`
- **Toast AppId** stays as `PiAgent` (already-registered Windows AppId; renaming
  would orphan existing user installs).

### Migration from 0.2.x
Run `install.ps1` again — it auto-detects `~/.pi-notify/` and migrates to
`~/.pi-pager/`, preserving your ntfy topic so phone subscriptions keep working.

## [0.2.1] — 2026-04-24

### Added
- **Multi-instance routing** — phone messages can be addressed to a specific agent
  instance via `project-name:` or `[project-name]` prefix; untagged messages broadcast
  to all instances
- **`inbox.ps1 -All`** — show messages across every project (overrides auto-filter)
- **`inbox.ps1 -Project <name>`** — peek at another instance's mailbox without `cd`
- **`-Wait` routing** — only replies addressed to the waiting project (or broadcasts)
  unblock that call, so you can run `-Wait` in multiple repos at once and reply
  selectively from your phone
- README: Routing-to-Specific-Instance section
- Pi SYSTEM.md prompt snippet: phone routing convention

## [0.2.0] — 2026-04-24

### Added
- **Cross-platform `notify.sh`** — macOS (afplay + osascript) and Linux (notify-send) parity with Windows version
- **Telegram bot channel** — post via Bot API with chat_id
- **Pushover channel** — priority 1 on errors (auto-bypass DND)
- **`-Wait` flag** — block until phone replies on ntfy; exit code maps yes/no/timeout
- **PowerShell module** (`module/PiPager.psm1`, `PiPager.psd1`) — `Send-PiPage`, `Get-PiPagerInbox`, `Get-PiPagerDaemonStatus`, `Stop-PiPagerDaemon`
- **Scoop manifest** (`packaging/scoop/pi-pager.json`)
- **Homebrew formula** (`packaging/homebrew/pi-pager.rb`)
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
- Per-project overrides via `.pi-pager.json`
- Optional Discord + Slack webhook channels
- `install.ps1` / `uninstall.ps1`
- Auto-start via Windows Startup folder
- Drop-in agent prompts for Pi, Claude Code, Cursor
- PSScriptAnalyzer + parse-check CI workflow

[0.3.0]: https://github.com/CymatiStatic/pi-pager/releases/tag/v0.3.0
[0.2.1]: https://github.com/CymatiStatic/pi-pager/releases/tag/v0.2.1
[0.2.0]: https://github.com/CymatiStatic/pi-pager/releases/tag/v0.2.0
[0.1.0]: https://github.com/CymatiStatic/pi-pager/releases/tag/v0.1.0
