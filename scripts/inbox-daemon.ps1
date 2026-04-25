# inbox-daemon.ps1 — streams ntfy topic, appends incoming messages to local log
# Runs silently in background. Auto-reconnects on network errors.
# https://github.com/CymatiStatic/pi-pager

param(
    [switch]$Stop,
    [switch]$Status
)

$ErrorActionPreference = 'Continue'
$dataDir = Join-Path $env:USERPROFILE '.pi-pager'
$cfgPath = Join-Path $dataDir 'notify.config.json'
if (-not (Test-Path $cfgPath)) { Write-Error "Config not found at $cfgPath. Run install.ps1."; exit 1 }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json

$pidFile    = Join-Path $dataDir 'daemon.pid'
$logPath    = Join-Path $dataDir 'inbox.log'
$daemonLog  = Join-Path $dataDir 'daemon.log'
$topic      = $cfg.ntfy.topic
$server     = $cfg.ntfy.server

$null = New-Item -ItemType Directory -Force -Path $dataDir -ErrorAction SilentlyContinue

function Write-DaemonLog($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $daemonLog -Value $line
}

if ($Stop) {
    if (Test-Path $pidFile) {
        $oldPid = Get-Content $pidFile
        try {
            Stop-Process -Id $oldPid -Force -ErrorAction Stop
            Write-Output "Stopped daemon (PID $oldPid)"
        } catch {
            Write-Output "Process $oldPid not running"
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "No daemon running (no pid file)"
    }
    exit 0
}

if ($Status) {
    if (Test-Path $pidFile) {
        $checkPid = Get-Content $pidFile
        $proc = Get-Process -Id $checkPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Output "[OK] Daemon running (PID $checkPid, started $($proc.StartTime))"
            $logSize = if (Test-Path $logPath) { (Get-Item $logPath).Length } else { 0 }
            $lineCount = if (Test-Path $logPath) { (Get-Content $logPath).Count } else { 0 }
            Write-Output "     Inbox log: $logPath ($logSize bytes, $lineCount messages)"
        } else {
            Write-Output "[DEAD] PID file exists but process $checkPid is dead"
        }
    } else {
        Write-Output "[STOPPED] Daemon not running"
    }
    exit 0
}

if (Test-Path $pidFile) {
    $existingPid = Get-Content $pidFile
    if (Get-Process -Id $existingPid -ErrorAction SilentlyContinue) {
        Write-DaemonLog "Daemon already running (PID $existingPid), exiting"
        exit 0
    }
}

$PID | Out-File $pidFile -Encoding ASCII
Write-DaemonLog "Daemon started (PID $PID, topic=$topic)"

$url = "$server/$topic/json"
while ($true) {
    try {
        Write-DaemonLog "Connecting to $url"
        & curl.exe -sN --max-time 0 $url 2>$null | ForEach-Object {
            $line = $_
            if ([string]::IsNullOrWhiteSpace($line)) { return }
            try {
                $m = $line | ConvertFrom-Json -ErrorAction Stop
                if ($m.event -eq 'message') {
                    Add-Content -Path $logPath -Value $line
                    Write-DaemonLog "msg: [$($m.title)] $($m.message)"
                }
            } catch { }
        }
        Write-DaemonLog 'Stream ended, reconnecting in 5s'
    } catch {
        Write-DaemonLog ("Error: {0} -- retry in 5s" -f $_.Exception.Message)
    }
    Start-Sleep -Seconds 5
}
