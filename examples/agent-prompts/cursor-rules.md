# pi-pager — Drop-in for Cursor

Paste this block into `.cursorrules` at your repo root (or add to Cursor's user-level rules).

Replace `REPO_PATH` with your clone path.

---

## Notification Protocol (pi-pager)

Before requesting user input, after completing long tasks, or on blockers, fire a pi-pager alert so the user hears a sound, sees a toast, and gets a phone ping.

Use the terminal tool:
```
powershell -ExecutionPolicy Bypass -File REPO_PATH/scripts/notify.ps1 -Type <TYPE> -Message "<SHORT_MESSAGE>" 2>&1 | tail -1
```

Types:
- `input` — before asking user a question
- `done`  — task complete
- `warn`  — non-blocking caution
- `error` — blocker

Rules:
- One fire per attention event, never spam
- Skip for trivial chat
- Continue silently if the script fails
