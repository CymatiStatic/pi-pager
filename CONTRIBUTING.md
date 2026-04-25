# Contributing to pi-pager

Thanks for your interest! This project lives or dies by community contributions — screenshots, agent-prompt templates, cross-platform parity, new channels. Small PRs welcome.

## Ground Rules

- **Open an issue first** for substantial changes so we can align on design.
- **Keep the install path boring.** A user running `install.ps1` should succeed without prompts, SKUs, or paid dependencies.
- **Fail silently.** Notification errors must never block the agent's workflow. If a channel can't reach its server, log-and-continue.
- **Windows 10+, PowerShell 5.1, curl.exe.** No modern dependencies that break older systems.
- **No telemetry.** Ever.

## Dev Setup

```powershell
git clone https://github.com/CymatiStatic/pi-pager.git
cd pi-pager
# Lint
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning,Error
# Parse-check
Get-ChildItem -Recurse -Filter *.ps1 | % {
  $e = $null
  [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e) | Out-Null
  if ($e) { "$($_.Name): PARSE ERROR"; $e } else { "$($_.Name): OK" }
}
```

CI runs both on every push/PR (see `.github/workflows/lint.yml`).

## High-Value Contributions

### Agent Prompt Templates
Drop a new file in `examples/agent-prompts/` following the existing format. Target agents include: Aider, Continue.dev, Zed AI, Codex CLI, OpenCode, Goose.

### New Notification Channels
Add a section to `scripts/notify.ps1` (and `scripts/notify.sh`) + a config stub in `scripts/notify.config.example.json`. Remember to `try/catch` and fail silent. Keep the curl/Invoke-WebRequest style consistent.

### Cross-Platform Daemon
The current streaming daemon is PowerShell-only. A Bash equivalent (`scripts/inbox-daemon.sh`) that streams ntfy via `curl -N` and writes NDJSON to `~/.pi-pager/inbox.log` would unlock full Mac/Linux parity.

### Screenshots / Demo GIF
Record:
- Windows toast firing
- Phone notification arriving
- `/inbox` showing phone-sent messages
- `-Wait` flow (agent asks, phone replies, agent continues)

Drop PNGs/GIFs in `assets/` and update README references.

## Commit Style

Conventional commits preferred (`feat:`, `fix:`, `docs:`, `chore:`, etc.) but not required. Single-purpose commits are easier to review than combo PRs.

## Release Process

1. Bump version in:
   - `module/PiPager.psd1` → `ModuleVersion`
   - `packaging/scoop/pi-pager.json` → `version` + `url`
   - `packaging/homebrew/pi-pager.rb` → `url` + `sha256`
2. Update `CHANGELOG.md`
3. Tag: `git tag -a v0.x.0 -m "pi-pager v0.x.0"`
4. Push: `git push origin main --tags`
5. Create GitHub release: `gh release create v0.x.0 --generate-notes`
6. (Optional) Publish to PSGallery: `Publish-Module -Path .\module -NuGetApiKey <key>`

## Code of Conduct

Be kind. Assume good faith. Criticize code, not people. Disagreement is welcome; hostility isn't.
