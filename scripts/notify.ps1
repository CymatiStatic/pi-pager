# notify.ps1 — pi-pager: cross-channel alert for agentic AI workflows
# Usage: powershell -ExecutionPolicy Bypass -File notify.ps1 -Type input -Message "Need approval"
# Types: input | done | error | warn
# https://github.com/CymatiStatic/pi-pager

param(
    [ValidateSet('input','done','error','warn')]
    [string]$Type = 'input',
    [string]$Message = 'Agent needs your attention',
    [string]$Title = 'Agent',
    [switch]$Wait = $false,
    [int]$TimeoutSec = 120
)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# --- Resolve config path ($env:USERPROFILE\.pi-pager\notify.config.json) ---
$dataDir = Join-Path $env:USERPROFILE '.pi-pager'
$cfgPath = Join-Path $dataDir 'notify.config.json'
if (-not (Test-Path $cfgPath)) {
    Write-Error "Config not found at $cfgPath. Run install.ps1 first."
    exit 1
}
try {
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse $cfgPath : $($_.Exception.Message)"
    exit 1
}
$sound = $cfg.sounds.$Type

# --- Detect current project (auto-tag alerts with git repo name) ---
function Get-ProjectInfo {
    $cwd = (Get-Location).Path
    $dir = $cwd
    $override = $null
    $repoRoot = $null
    while ($dir -and (Test-Path $dir)) {
        $ovPath = Join-Path $dir '.pi-pager.json'
        if ((-not $override) -and (Test-Path $ovPath)) { $override = $ovPath }
        if ((-not $repoRoot) -and (Test-Path (Join-Path $dir '.git'))) { $repoRoot = $dir }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    $name = if ($repoRoot) { Split-Path $repoRoot -Leaf } else { Split-Path $cwd -Leaf }
    return @{ Name = $name; OverridePath = $override }
}
$proj = Get-ProjectInfo
$projectName = $proj.Name

# --- Apply per-project override if .pi-pager.json exists in repo ---
if ($proj.OverridePath) {
    try {
        $ov = Get-Content $proj.OverridePath -Raw | ConvertFrom-Json
        if ($ov.project_name)                { $projectName = $ov.project_name }
        if ($ov.ntfy_topic)                  { $cfg.ntfy.topic = $ov.ntfy_topic }
        if ($ov.ntfy_enabled -ne $null)      { $cfg.ntfy.enabled = $ov.ntfy_enabled }
        if ($ov.discord_webhook_url)         { $cfg.discord.webhook_url = $ov.discord_webhook_url; $cfg.discord.enabled = $true }
        if ($ov.discord_enabled -ne $null)   { $cfg.discord.enabled = $ov.discord_enabled }
        if ($ov.slack_webhook_url)           { $cfg.slack.webhook_url = $ov.slack_webhook_url; $cfg.slack.enabled = $true }
        if ($ov.slack_enabled -ne $null)     { $cfg.slack.enabled = $ov.slack_enabled }
    } catch { }
}

# Tag title with project so multiple repos are distinguishable in one feed
if ($projectName -and $Title -eq 'Agent') {
    $Title = "Agent [$projectName]"
}

# ---------------------------------------------------------------------------
# 1. Local sound (synchronous WAV — always works)
# ---------------------------------------------------------------------------
try {
    $wav = $sound.wav
    if (-not (Test-Path $wav)) { $wav = 'C:\Windows\Media\Windows Notify.wav' }
    (New-Object Media.SoundPlayer $wav).PlaySync()
} catch {
    try { [System.Media.SystemSounds]::Asterisk.Play(); Start-Sleep -Milliseconds 500 } catch {}
}

# ---------------------------------------------------------------------------
# 2. Windows toast (BurntToast with registered AppId — no stray PS window on click)
# ---------------------------------------------------------------------------
if ($cfg.toast.enabled) {
    try {
        if (Get-Module -ListAvailable -Name BurntToast) {
            Import-Module BurntToast -ErrorAction Stop
            $text1 = New-BTText -Text $Title
            $text2 = New-BTText -Text $Message
            $binding = New-BTBinding -Children $text1, $text2
            $visual  = New-BTVisual -BindingGeneric $binding
            $content = New-BTContent -Visual $visual
            Submit-BTNotification -Content $content -AppId $cfg.toast.app_id -ErrorAction Stop
        } else {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            $balloon = New-Object System.Windows.Forms.NotifyIcon
            $balloon.Icon = [System.Drawing.SystemIcons]::Information
            $balloon.BalloonTipTitle = $Title
            $balloon.BalloonTipText  = $Message
            $balloon.Visible = $true
            $balloon.ShowBalloonTip(4000)
            Start-Sleep -Seconds 1
            $balloon.Dispose()
        }
    } catch { }
}

# ---------------------------------------------------------------------------
# 3. Phone / watch push via ntfy
# ---------------------------------------------------------------------------
if ($cfg.ntfy.enabled) {
    try {
        $url = "$($cfg.ntfy.server)/$($cfg.ntfy.topic)"
        $headerArgs = @(
            '-H', "Title: $Title",
            '-H', "Priority: $($sound.priority)",
            '-H', "Tags: $($sound.tag)"
        )
        & curl.exe -s --max-time 4 -X POST @headerArgs -d $Message $url *>$null
    } catch { }
}

# ---------------------------------------------------------------------------
# 4. Discord webhook
# ---------------------------------------------------------------------------
if ($cfg.discord.enabled -and $cfg.discord.webhook_url -and $cfg.discord.webhook_url -notmatch '^(PASTE_|$)') {
    try {
        $emoji = switch ($Type) {
            'input' { [char]0x2753 }  # ❓
            'done'  { [char]0x2705 }  # ✅
            'warn'  { [char]0x26A0 }  # ⚠
            'error' { [char]0x1F6A8 } # 🚨 (may be 2 code units)
        }
        $payload = @{
            username = $Title
            content  = "$emoji **${Type}**: $Message"
        } | ConvertTo-Json -Compress
        $tmpFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tmpFile -Value $payload -Encoding UTF8 -NoNewline
        $curlDataArg = '@' + $tmpFile
        & curl.exe -s --max-time 4 -H 'Content-Type: application/json' -X POST -d $curlDataArg $cfg.discord.webhook_url *>$null
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    } catch { }
}

# ---------------------------------------------------------------------------
# 5. Slack webhook
# ---------------------------------------------------------------------------
if ($cfg.slack.enabled -and $cfg.slack.webhook_url -and $cfg.slack.webhook_url -notmatch '^(PASTE_|$)') {
    try {
        $payload = @{
            text     = "*$Title* - ${Type}: $Message"
            username = $Title
        } | ConvertTo-Json -Compress
        $tmpFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tmpFile -Value $payload -Encoding UTF8 -NoNewline
        $curlDataArg = '@' + $tmpFile
        & curl.exe -s --max-time 4 -H 'Content-Type: application/json' -X POST -d $curlDataArg $cfg.slack.webhook_url *>$null
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    } catch { }
}

# ---------------------------------------------------------------------------
# 6. Telegram bot
# ---------------------------------------------------------------------------
if ($cfg.telegram.enabled -and $cfg.telegram.bot_token -and $cfg.telegram.chat_id) {
    try {
        $tgUrl = "https://api.telegram.org/bot$($cfg.telegram.bot_token)/sendMessage"
        $tgText = "$Title - ${Type}: $Message"
        & curl.exe -s --max-time 4 -d "chat_id=$($cfg.telegram.chat_id)" --data-urlencode "text=$tgText" $tgUrl *>$null
    } catch { }
}

# ---------------------------------------------------------------------------
# 7. Pushover
# ---------------------------------------------------------------------------
if ($cfg.pushover.enabled -and $cfg.pushover.app_token -and $cfg.pushover.user_key) {
    try {
        $poPrio = if ($Type -eq 'error') { 1 } else { 0 }
        & curl.exe -s --max-time 4 `
            --form-string "token=$($cfg.pushover.app_token)" `
            --form-string "user=$($cfg.pushover.user_key)" `
            --form-string "title=$Title" `
            --form-string "message=$Message" `
            --form-string "priority=$poPrio" `
            https://api.pushover.net/1/messages.json *>$null
    } catch { }
}

# ---------------------------------------------------------------------------
# 8. -Wait: block until a reply arrives on ntfy (phone responds)
# ---------------------------------------------------------------------------
if ($Wait) {
    $startTs = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $deadline = $startTs + $TimeoutSec
    while ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -lt $deadline) {
        # ntfy: no suffix -> absolute Unix timestamp; with 's' suffix it means 'X seconds ago'
        $pollUrl = "$($cfg.ntfy.server)/$($cfg.ntfy.topic)/json?poll=1&since=$startTs"
        $body = & curl.exe -s --max-time 4 $pollUrl 2>$null
        if ($body) {
            foreach ($line in ($body -split "`r?`n")) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                try {
                    $m = $line | ConvertFrom-Json -ErrorAction Stop
                    # Skip our own outbound messages
                    if ($m.title -and $m.title -match '^Agent') { continue }
                    # Routing: only accept replies addressed to this project (or broadcast/untagged)
                    $reply = $m.message
                    $proj = $projectName.ToLower()
                    if ($reply -match '^\s*\[([\w\.-]+)\]\s*(.*)$' -or $reply -match '^\s*([\w\.-]+)\s*:\s*(.+)$') {
                        $target = $Matches[1].ToLower()
                        $body2  = $Matches[2]
                        if ($target -ne $proj) { continue }   # not for me
                        $reply = $body2
                    }
                    Write-Output $reply
                    $low = $reply.ToLower().Trim()
                    switch -Regex ($low) {
                        '^(y|yes|ok|approve|approved|go|accept)$' { exit 0 }
                        '^(n|no|cancel|stop|reject|rejected)$'    { exit 1 }
                        default { exit 0 }
                    }
                } catch { }
            }
        }
        Start-Sleep -Seconds 2
    }
    Write-Output '(timeout)'
    exit 2
}
