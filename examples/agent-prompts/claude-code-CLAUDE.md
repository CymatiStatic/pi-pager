# pi-notify — Drop-in for Claude Code CLAUDE.md

Paste this block into your user-level `~/CLAUDE.md` or a project `CLAUDE.md`.

Replace `REPO_PATH` with your clone path (e.g. `C:/Users/YOU/Dev/pi-notify`).

---

## Notification Protocol (pi-notify)

Before asking the user for input, after finishing a long task, or when hitting a blocker, fire `pi-notify` to alert them via desktop + phone.

Script: `REPO_PATH/scripts/notify.ps1`

**Invocation (use Bash tool):**
```bash
powershell -ExecutionPolicy Bypass -File REPO_PATH/scripts/notify.ps1 -Type <TYPE> -Message "<SHORT_MESSAGE>" 2>&1 | tail -1
```

**Types:**
- `input` — before asking user a question or requesting confirmation
- `done`  — when a build/test/deploy/long-running task completes
- `warn`  — non-blocking caution
- `error` — blocker requiring human intervention

**When to fire:**
- ✅ Before the final question in a `<70%` confidence check
- ✅ Before any destructive operation confirmation
- ✅ After a long build/test/orchestration cycle finishes
- ❌ Not on every tool call — one fire per attention event
- ❌ Not for trivial chat ("ok", "thanks")

If the script is unavailable or fails, continue silently — notification failure must never block the workflow.

### Check Phone-Sent Messages (optional)
```bash
powershell -ExecutionPolicy Bypass -File REPO_PATH/scripts/inbox.ps1 -Since 10m
```
Treat phone-origin messages as user-intent.
