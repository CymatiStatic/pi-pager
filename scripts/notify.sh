#!/usr/bin/env bash
# notify.sh — pi-pager for macOS & Linux
# Usage: notify.sh --type input --message "Need approval"
# Types: input | done | error | warn
# https://github.com/CymatiStatic/pi-pager

set -u

TYPE="input"
MESSAGE="Agent needs your attention"
TITLE="Agent"
WAIT=false
WAIT_TIMEOUT=120

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--type)    TYPE="$2"; shift 2 ;;
    -m|--message) MESSAGE="$2"; shift 2 ;;
    -T|--title)   TITLE="$2"; shift 2 ;;
    --wait)       WAIT=true; shift ;;
    --timeout)    WAIT_TIMEOUT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "$TYPE" in input|done|error|warn) ;; *) echo "bad --type: $TYPE" >&2; exit 2 ;; esac

# --- Locate config ---
DATA_DIR="${HOME}/.pi-pager"
CFG="${DATA_DIR}/notify.config.json"
if [[ ! -f "$CFG" ]]; then
  echo "config not found: $CFG  (run install.sh)" >&2
  exit 1
fi

# Parse JSON with jq if present, otherwise python fallback
jget() {
  if command -v jq >/dev/null 2>&1; then
    jq -r "$1 // empty" "$CFG" 2>/dev/null
  else
    python3 -c "
import json,sys
d=json.load(open('${CFG}'))
def g(p,o=d):
    for k in p.strip('.').split('.'):
        if k.startswith('\"') and k.endswith('\"'): k=k[1:-1]
        if isinstance(o,dict) and k in o: o=o[k]
        else: return ''
    return '' if o is None else o
print(g('$1'))
" 2>/dev/null
  fi
}

NTFY_ENABLED=$(jget '.ntfy.enabled')
NTFY_SERVER=$(jget '.ntfy.server')
NTFY_TOPIC=$(jget '.ntfy.topic')
DISCORD_ENABLED=$(jget '.discord.enabled')
DISCORD_URL=$(jget '.discord.webhook_url')
SLACK_ENABLED=$(jget '.slack.enabled')
SLACK_URL=$(jget '.slack.webhook_url')
TELEGRAM_ENABLED=$(jget '.telegram.enabled')
TELEGRAM_TOKEN=$(jget '.telegram.bot_token')
TELEGRAM_CHAT=$(jget '.telegram.chat_id')
PUSHOVER_ENABLED=$(jget '.pushover.enabled')
PUSHOVER_TOKEN=$(jget '.pushover.app_token')
PUSHOVER_USER=$(jget '.pushover.user_key')

# --- Priority + tag per type ---
case "$TYPE" in
  input) PRIO=4; TAG="question" ;;
  done)  PRIO=3; TAG="white_check_mark" ;;
  warn)  PRIO=3; TAG="warning" ;;
  error) PRIO=5; TAG="rotating_light" ;;
esac

# --- Auto-tag title with project ---
detect_project() {
  local d="$PWD"
  while [[ "$d" != "/" && -n "$d" ]]; do
    [[ -d "$d/.git" ]] && { basename "$d"; return; }
    d="$(dirname "$d")"
  done
  basename "$PWD"
}
if [[ "$TITLE" == "Agent" ]]; then
  TITLE="Agent [$(detect_project)]"
fi

# --- 1. Local sound ---
play_sound() {
  if [[ "$(uname)" == "Darwin" ]]; then
    case "$TYPE" in
      input) afplay /System/Library/Sounds/Tink.aiff  2>/dev/null ;;
      done)  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null ;;
      warn)  afplay /System/Library/Sounds/Pop.aiff   2>/dev/null ;;
      error) afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null ;;
    esac
  else
    # Linux — try paplay, aplay, then fall back
    for p in paplay aplay; do
      if command -v $p >/dev/null 2>&1; then
        $p /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null && return
        $p /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null && return
      fi
    done
    # Terminal bell as last resort
    printf '\a'
  fi
}
play_sound

# --- 2. Desktop notification ---
if [[ "$(uname)" == "Darwin" ]]; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
fi

# --- 3. ntfy push ---
if [[ "$NTFY_ENABLED" == "true" || "$NTFY_ENABLED" == "True" ]]; then
  curl -s --max-time 4 \
    -H "Title: $TITLE" \
    -H "Priority: $PRIO" \
    -H "Tags: $TAG" \
    -d "$MESSAGE" \
    "$NTFY_SERVER/$NTFY_TOPIC" >/dev/null 2>&1 || true
fi

# --- 4. Discord ---
if [[ ("$DISCORD_ENABLED" == "true" || "$DISCORD_ENABLED" == "True") && -n "$DISCORD_URL" && "$DISCORD_URL" != PASTE* ]]; then
  case "$TYPE" in input) E='❓';; done) E='✅';; warn) E='⚠️';; error) E='🚨';; esac
  curl -s --max-time 4 -H 'Content-Type: application/json' \
    -d "{\"username\":\"$TITLE\",\"content\":\"$E **$TYPE**: $MESSAGE\"}" \
    "$DISCORD_URL" >/dev/null 2>&1 || true
fi

# --- 5. Slack ---
if [[ ("$SLACK_ENABLED" == "true" || "$SLACK_ENABLED" == "True") && -n "$SLACK_URL" && "$SLACK_URL" != PASTE* ]]; then
  curl -s --max-time 4 -H 'Content-Type: application/json' \
    -d "{\"text\":\"*$TITLE* — ${TYPE}: $MESSAGE\"}" \
    "$SLACK_URL" >/dev/null 2>&1 || true
fi

# --- 6. Telegram ---
if [[ ("$TELEGRAM_ENABLED" == "true" || "$TELEGRAM_ENABLED" == "True") && -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_CHAT" ]]; then
  curl -s --max-time 4 \
    -d "chat_id=$TELEGRAM_CHAT" \
    --data-urlencode "text=$TITLE — ${TYPE}: $MESSAGE" \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" >/dev/null 2>&1 || true
fi

# --- 7. Pushover ---
if [[ ("$PUSHOVER_ENABLED" == "true" || "$PUSHOVER_ENABLED" == "True") && -n "$PUSHOVER_TOKEN" && -n "$PUSHOVER_USER" ]]; then
  PO_PRIO=0
  [[ "$TYPE" == "error" ]] && PO_PRIO=1
  curl -s --max-time 4 \
    --form-string "token=$PUSHOVER_TOKEN" \
    --form-string "user=$PUSHOVER_USER" \
    --form-string "title=$TITLE" \
    --form-string "message=$MESSAGE" \
    --form-string "priority=$PO_PRIO" \
    https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
fi

# --- 8. --wait: block until reply arrives on ntfy ---
if [[ "$WAIT" == "true" ]]; then
  start_ts=$(date +%s)
  deadline=$(( start_ts + WAIT_TIMEOUT ))
  while (( $(date +%s) < deadline )); do
    # Poll ntfy for messages since start_ts (only phone-origin, not our own)
    # ntfy: no suffix = absolute Unix timestamp; suffix 's' would mean 'X seconds ago'
    body=$(curl -s --max-time 4 "$NTFY_SERVER/$NTFY_TOPIC/json?poll=1&since=${start_ts}" 2>/dev/null || true)
    if [[ -n "$body" ]]; then
      # Find first message that is NOT from us (title starts with "Agent")
      project="$(detect_project)"
      reply=$(echo "$body" | python3 -c "
import sys,json,re
proj='${project}'.lower() if False else '${project}'
proj=proj.lower()
for line in sys.stdin:
    line=line.strip()
    if not line: continue
    try: m=json.loads(line)
    except: continue
    t=m.get('title','')
    msg=m.get('message','')
    if t.startswith('Agent'): continue
    # Parse routing prefix: '[project] body' or 'project: body'
    mt=re.match(r'^\s*\[([\w\.-]+)\]\s*(.*)$', msg) or re.match(r'^\s*([\w\.-]+)\s*:\s*(.+)$', msg)
    if mt:
        target=mt.group(1).lower(); body_=mt.group(2)
        if target != proj: continue   # not for me
        print(body_); break
    else:
        print(msg); break   # broadcast
" 2>/dev/null)
      if [[ -n "$reply" ]]; then
        echo "$reply"
        low="$(echo "$reply" | tr '[:upper:]' '[:lower:]')"
        case "$low" in
          y|yes|ok|approve|approved|go|accept) exit 0 ;;
          n|no|cancel|stop|reject|rejected)    exit 1 ;;
          *) exit 0 ;;  # any other text = approval-ish, return 0
        esac
      fi
    fi
    sleep 2
  done
  echo "(timeout)"
  exit 2
fi
