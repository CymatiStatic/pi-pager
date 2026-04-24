# install.ps1 — pi-notify setup: config, BurntToast, AppId, auto-start
# https://github.com/CymatiStatic/pi-notify
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Topic "existing-topic-to-preserve"
#   powershell -ExecutionPolicy Bypass -File install.ps1 -NoStartup
#   powershell -ExecutionPolicy Bypass -File install.ps1 -NoDaemon

param(
    [string]$Topic      = $null,
    [switch]$NoStartup  = $false,
    [switch]$NoDaemon   = $false,
    [switch]$Force      = $false
)

$ErrorActionPreference = 'Stop'
Write-Host ""
Write-Host "=== pi-notify installer ===" -ForegroundColor Cyan
Write-Host ""

$repoRoot   = Split-Path -Parent $PSCommandPath
$scriptsDir = Join-Path $repoRoot 'scripts'
$dataDir    = Join-Path $env:USERPROFILE '.pi-notify'
$cfgPath    = Join-Path $dataDir 'notify.config.json'
$examplePath = Join-Path $scriptsDir 'notify.config.example.json'

# --- 1. Create data dir ---
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
    Write-Host "[+] Created $dataDir"
} else {
    Write-Host "[=] Data dir exists: $dataDir"
}

# --- 2. Generate or preserve ntfy topic ---
if (-not $Topic) {
    if ((Test-Path $cfgPath) -and -not $Force) {
        $existingCfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        $Topic = $existingCfg.ntfy.topic
        Write-Host "[=] Preserving existing topic: $Topic"
    } else {
        $hex = [guid]::NewGuid().ToString('N').Substring(0, 16)
        $Topic = "pi-notify-$hex"
        Write-Host "[+] Generated random topic: $Topic"
    }
} else {
    Write-Host "[+] Using supplied topic: $Topic"
}

# --- 3. Write config from template ---
if ((Test-Path $cfgPath) -and -not $Force) {
    Write-Host "[=] Config exists, updating topic only"
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    $cfg.ntfy.topic = $Topic
    $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $cfgPath -Encoding UTF8
} else {
    $template = Get-Content $examplePath -Raw | ConvertFrom-Json
    $template.ntfy.topic = $Topic
    $template | ConvertTo-Json -Depth 10 | Set-Content -Path $cfgPath -Encoding UTF8
    Write-Host "[+] Wrote config: $cfgPath"
}

# --- 4. Verify curl.exe ---
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if (-not $curl) {
    Write-Host "[!] curl.exe not found. Windows 10+ ships curl.exe; check your PATH." -ForegroundColor Yellow
} else {
    Write-Host "[=] curl.exe: $($curl.Source)"
}

# --- 5. Install BurntToast ---
if (-not (Get-Module -ListAvailable -Name BurntToast)) {
    Write-Host "[+] Installing BurntToast (PowerShell Gallery)..."
    try {
        Install-Module -Name BurntToast -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
        Write-Host "[+] BurntToast installed"
    } catch {
        Write-Host "[!] BurntToast install failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "    Toasts will fall back to balloon tips. Everything else works."
    }
} else {
    Write-Host "[=] BurntToast already installed"
}

# --- 6. Register AppId so toast clicks don't launch a stray PowerShell window ---
try {
    Import-Module BurntToast -ErrorAction Stop
    New-BTShortcut -AppId 'PiAgent' -DisplayName 'Pi Agent' -ExecutablePath 'C:\Windows\explorer.exe' -ErrorAction Stop | Out-Null
    Write-Host "[+] Registered AppId 'PiAgent'"
} catch {
    Write-Host "[!] AppId registration skipped: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- 7. Startup auto-launch ---
if (-not $NoStartup) {
    $startup = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startup 'pi-notify daemon.lnk'
    $launcherVbs  = Join-Path $scriptsDir 'inbox-daemon-launcher.vbs'
    $WshShell = New-Object -ComObject WScript.Shell
    $sc = $WshShell.CreateShortcut($shortcutPath)
    $sc.TargetPath = $launcherVbs
    $sc.Description = 'pi-notify inbox streaming daemon'
    $sc.Save()
    Write-Host "[+] Startup shortcut: $shortcutPath"
} else {
    Write-Host "[-] Skipped startup shortcut (-NoStartup)"
}

# --- 8. Launch daemon now ---
if (-not $NoDaemon) {
    $launcherVbs = Join-Path $scriptsDir 'inbox-daemon-launcher.vbs'
    Start-Process -FilePath 'wscript.exe' -ArgumentList "`"$launcherVbs`"" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    $statusScript = Join-Path $scriptsDir 'inbox-daemon.ps1'
    & powershell.exe -ExecutionPolicy Bypass -File $statusScript -Status
} else {
    Write-Host "[-] Skipped daemon launch (-NoDaemon)"
}

# --- 9. Next steps ---
Write-Host ""
Write-Host "=== Installation complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your ntfy topic: " -NoNewline; Write-Host $Topic -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Install ntfy app on your phone:"
Write-Host "     - iOS:     https://apps.apple.com/us/app/ntfy/id1625396347"
Write-Host "     - Android: https://play.google.com/store/apps/details?id=io.heckel.ntfy"
Write-Host "  2. Open the app -> Subscribe to topic -> enter: $Topic"
Write-Host "  3. Test it:"
Write-Host "     powershell -File $scriptsDir\notify.ps1 -Type done -Message 'Hello from pi-notify'"
Write-Host ""
Write-Host "Optional:"
Write-Host "  - Edit $cfgPath to enable Discord/Slack webhooks"
Write-Host "  - Copy examples/.pi-notify.json to any repo root for per-project overrides"
Write-Host "  - See examples/agent-prompts/ for drop-in rules for Pi, Claude Code, Cursor"
Write-Host ""
