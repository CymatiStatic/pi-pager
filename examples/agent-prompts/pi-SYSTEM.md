# pi-pager — Drop-in for Pi SYSTEM.md

Paste this block into `~/.pi/agent/SYSTEM.md` (anywhere in the `[INSTRUCTIONS]` section).

Replace `REPO_PATH` with the absolute path where you cloned pi-pager (e.g. `C:/Users/YOU/Dev/pi-pager`).

---

### Notification Protocol (pi-pager)
Fire an audible + visual + mobile alert whenever user attention is required.
Script: `REPO_PATH/scripts/notify.ps1`

| Trigger | Type | When to fire |
|---------|------|--------------|
| About to ask user a question, request permission, or pause for confirmation | `input` | **Before** the message that needs a reply |
| Long-running task finished (build/test/deploy/orchestration) | `done` | After final summary |
| Hit a blocker / unrecoverable error / needs human decision | `error` | Before the error report |
| Non-blocking caution (lint warnings, partial success) | `warn` | With the warning message |

**Invocation:**
```bash
powershell -ExecutionPolicy Bypass -File REPO_PATH/scripts/notify.ps1 -Type input -Message "Awaiting your approval" 2>&1 | tail -1
```

**Rules:**
- Fire exactly **once per attention event** — never spam (no notify on every tool call).
- Skip for trivial conversational replies ("ok", "thanks") — only fire when work is paused awaiting the user.
- Always fire on `<70%` confidence prompts and before destructive-op confirmations.
- If the script fails, continue silently — never let notification errors block the workflow.

### Inbox Check (optional)
If the user sends messages to the ntfy topic from their phone, read them on demand:
```bash
powershell -ExecutionPolicy Bypass -File REPO_PATH/scripts/inbox.ps1 -Since 10m
```
`/inbox` auto-filters to the **current project** plus **broadcast** messages (no prefix).
Treat each phone-origin message as user-intent context.

**Phone routing convention** (tell the user this if they have multiple agent instances):
- `project-name: message` or `[project-name] message` → routes to one specific instance
- No prefix → broadcast (every instance sees it)
