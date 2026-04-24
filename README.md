# pi-notify

**Cross-channel alerts for agentic AI workflows.** When your AI coding agent (Pi, Claude Code, Cursor, Aider, etc.) needs your approval or finishes a long task, it pings your speakers, your desktop, and your phone / watch — automatically tagged by git repo so you know which project needs attention.

> Built for Pi, works with anything that can run a PowerShell one-liner.

## Features

- 🔊 **Synchronous WAV sound** — reliable, no async cutoff
- 🪟 **Windows toast** (BurntToast) — registered AppId so clicks don't spawn stray PowerShell windows
- 📱 **Phone / watch push** via [ntfy.sh](https://ntfy.sh) — free, open-source, no account needed
- 📬 **Two-way inbox** — text the agent from your phone, checked via `/inbox` (streaming daemon caches locally)
- 🏷️ **Auto project tagging** — walks up to find `.git`, prefixes alerts with repo name
- ⚙️ **Per-project overrides** — drop `.pi-notify.json` in any repo root to change topic/channels just for that project
- 💬 **Discord + Slack webhooks** — optional redundant channels
- 🚀 **Auto-start on login** — daemon runs silently, 0 user interaction

## Install (Windows)

```powershell
git clone https://github.com/CymatiStatic/pi-notify.git
cd pi-notify
powershell -ExecutionPolicy Bypass -File install.ps1
```

The installer:
1. Generates a random private ntfy topic
2. Creates `~/.pi-notify/` data dir with config
3. Installs BurntToast (if missing) and registers the `PiAgent` AppId
4. Adds a Startup shortcut so the daemon auto-launches on login
5. Prints your topic name + ntfy app install links

## Usage

```powershell
# Fire alerts manually (your agent should do this automatically — see Agent Integration below)
powershell -File scripts/notify.ps1 -Type input -Message "Need your approval"
powershell -File scripts/notify.ps1 -Type done  -Message "Build passed"
powershell -File scripts/notify.ps1 -Type warn  -Message "Tests flaky"
powershell -File scripts/notify.ps1 -Type error -Message "Deploy failed"

# Read messages you sent from your phone
powershell -File scripts/inbox.ps1                 # last 10 min
powershell -File scripts/inbox.ps1 -Since 1h       # last hour
powershell -File scripts/inbox.ps1 -IncludePi      # also show agent's outbound alerts

# Daemon control
powershell -File scripts/inbox-daemon.ps1 -Status
powershell -File scripts/inbox-daemon.ps1 -Stop
```

## Agent Integration

Drop-in prompt snippets for each agent are in `examples/agent-prompts/`:

| Agent | File | Where to paste |
|-------|------|----------------|
| **Pi** | `pi-SYSTEM.md` | `~/.pi/agent/SYSTEM.md` |
| **Claude Code** | `claude-code-CLAUDE.md` | `~/CLAUDE.md` or project `CLAUDE.md` |
| **Cursor** | `cursor-rules.md` | `.cursorrules` at repo root |

The snippet teaches the agent to fire `notify.ps1` before asking for input, after long tasks, on errors, and on warnings.

## Alert Types

| Type | Sound | ntfy priority | When the agent should fire it |
|------|-------|---------------|-------------------------------|
| `input` | Windows Notify Messaging | 4 | Before asking user for approval/input |
| `done`  | tada.wav | 3 | Long task finished |
| `warn`  | Windows Notify | 3 | Non-blocking issue |
| `error` | Windows Critical Stop | 5 (bypass DND) | Blocker / needs human |

## Multi-Project — No Separate Channels Needed

One topic handles every repo. Alerts are auto-prefixed with the project name:

```
Agent [full-stack-harness] Sprint 3 QA passed
Agent [spec-tator]          Needs your approval on spec
Agent [pomofocus-webhook]   Server crashed
```

One phone subscription, one Discord channel, clear per-project identification. If you *want* a specific project on its own channel (e.g. client work on a separate Discord), drop this in that repo root:

```json
// .pi-notify.json
{
  "project_name": "client-acme",
  "ntfy_topic": "pi-acme-abc123def456",
  "discord_webhook_url": "https://discord.com/api/webhooks/...",
  "discord_enabled": true
}
```

See `examples/.pi-notify.json`.

## Two-Way Messaging

Pi → phone is one-way by default (outbound alerts only). To text the agent **from** your phone:

1. Open the ntfy app → your topic → send a message
2. The background daemon catches it and appends to `~/.pi-notify/inbox.log`
3. Ask the agent to run `/inbox` (or `powershell -File scripts/inbox.ps1`)
4. Agent reads your message and acts on it

## Portability to Another Machine

1. `git clone https://github.com/CymatiStatic/pi-notify.git`
2. `powershell -File install.ps1 -Topic "your-existing-topic"`  ← preserves phone subscription
3. Done. Second machine now streams the same topic; phone gets alerts from both.

## Channels

| Channel | Enabled by default | Config |
|---------|-------------------|--------|
| Local WAV sound | ✅ | `sounds.*.wav` in config |
| Windows toast (BurntToast) | ✅ | `toast.enabled` |
| ntfy push (phone/watch) | ✅ | `ntfy.enabled`, `ntfy.topic` |
| Discord webhook | ❌ (opt-in) | `discord.enabled`, `discord.webhook_url` |
| Slack webhook | ❌ (opt-in) | `slack.enabled`, `slack.webhook_url` |

Edit `~/.pi-notify/notify.config.json` to toggle.

## Self-Hosted ntfy (Optional)

For full privacy, replace `ntfy.server` in config with your self-hosted URL:

```json
"ntfy": { "enabled": true, "server": "https://ntfy.mydomain.com", "topic": "..." }
```

See [ntfy self-hosting docs](https://docs.ntfy.sh/install/).

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
# Optionally also: Uninstall-Module BurntToast
```

## Architecture

```
┌──────────────────┐      ┌──────────────────────────┐
│   AI Agent       │─────>│ scripts/notify.ps1        │
│  (Pi, Claude     │      │                           │
│   Code, Cursor)  │      │  ┌──────────────────────┐ │
└──────────────────┘      │  │ 1. WAV (sync)        │ │
                          │  │ 2. Toast (BurntToast)│ │
                          │  │ 3. ntfy POST         │─┼──> phone/watch
                          │  │ 4. Discord webhook   │─┼──> Discord
                          │  │ 5. Slack webhook     │─┼──> Slack
                          │  └──────────────────────┘ │
                          └──────────────────────────┘

┌──────────────────┐      ┌──────────────────────────┐
│  Your phone      │─────>│ ntfy.sh (topic stream)   │
│  (ntfy app)      │      └────────────┬─────────────┘
└──────────────────┘                   │
                                       ▼
                          ┌──────────────────────────┐
                          │ inbox-daemon.ps1         │
                          │  (streams, appends NDJSON)│
                          └────────────┬─────────────┘
                                       │
                                       ▼
                          ┌──────────────────────────┐
                          │ ~/.pi-notify/inbox.log   │
                          │  (read via /inbox)       │
                          └──────────────────────────┘
```

## Requirements

- Windows 10 / 11 (macOS & Linux support: PRs welcome)
- PowerShell 5.1+ (ships with Windows)
- `curl.exe` (ships with Windows 10 1803+)

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome. Particularly interested in:
- macOS / Linux parity scripts (`notify.sh`)
- More agent prompt templates (Aider, Continue, Zed, etc.)
- Alternate push channels (Telegram, Pushover, Matrix, Apprise)
