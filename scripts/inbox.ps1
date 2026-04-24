# inbox.ps1 — read messages sent to the agent from your phone (via ntfy)
# Uses local daemon log (fast, offline-capable) with ntfy network poll as fallback.
# https://github.com/CymatiStatic/pi-notify

param(
    [string]$Since     = '10m',
    [switch]$IncludePi = $false,
    [switch]$Network   = $false,
    [switch]$Mark      = $false
)

$dataDir = Join-Path $env:USERPROFILE '.pi-notify'
$cfgPath = Join-Path $dataDir 'notify.config.json'
if (-not (Test-Path $cfgPath)) { Write-Error "Config not found. Run install.ps1."; exit 1 }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$logPath = Join-Path $dataDir 'inbox.log'

if ($Mark) {
    if (Test-Path $logPath) {
        Clear-Content $logPath
        Write-Output "[inbox] cleared $logPath"
    } else {
        Write-Output "[inbox] no log to clear"
    }
    exit 0
}

function Parse-Duration($s) {
    if ($s -match '^(\d+)([smhd])$') {
        $n = [int]$Matches[1]
        switch ($Matches[2]) {
            's' { return $n }
            'm' { return $n * 60 }
            'h' { return $n * 3600 }
            'd' { return $n * 86400 }
        }
    }
    return 600
}
$windowSec = Parse-Duration $Since
$cutoff = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $windowSec

$messages = @()
$source = ''

if ((Test-Path $logPath) -and -not $Network) {
    $source = 'local daemon log'
    $lines = Get-Content $logPath -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $m = $line | ConvertFrom-Json -ErrorAction Stop
            if ($m.time -lt $cutoff) { continue }
            if ((-not $IncludePi) -and ($m.title -match '^Agent')) { continue }
            $messages += $m
        } catch { }
    }
} else {
    $source = 'ntfy network poll'
    $url = "$($cfg.ntfy.server)/$($cfg.ntfy.topic)/json?poll=1&since=$Since"
    $body = & curl.exe -s --max-time 6 $url 2>$null
    if ($body) {
        foreach ($line in ($body -split "`r?`n")) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            try {
                $m = $line | ConvertFrom-Json -ErrorAction Stop
                if ((-not $IncludePi) -and ($m.title -match '^Agent')) { continue }
                $messages += $m
            } catch { }
        }
    }
}

if ($messages.Count -eq 0) {
    Write-Output "[inbox] (no messages in last ${Since}) [source: $source]"
    exit 0
}

Write-Output "[inbox] $($messages.Count) message(s) in last ${Since} [source: $source]:"
Write-Output ''
foreach ($m in $messages) {
    $ts = try {
        [DateTimeOffset]::FromUnixTimeSeconds([long]$m.time).LocalDateTime.ToString('HH:mm:ss')
    } catch { '--:--:--' }
    $who = if ($m.title) { $m.title } else { 'phone' }
    Write-Output "  ($ts) [$who] $($m.message)"
}
