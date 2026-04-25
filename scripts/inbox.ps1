# inbox.ps1 — read messages sent to the agent from your phone (via ntfy)
# Uses local daemon log (fast, offline-capable) with ntfy network poll as fallback.
# https://github.com/CymatiStatic/pi-pager

param(
    [string]$Since     = '10m',
    [switch]$IncludePi = $false,
    [switch]$Network   = $false,
    [switch]$Mark      = $false,
    [switch]$All       = $false,    # show messages for all projects (override auto-filter)
    [string]$Project   = $null      # explicitly filter to this project (instead of auto-detect)
)

$dataDir = Join-Path $env:USERPROFILE '.pi-pager'
$cfgPath = Join-Path $dataDir 'notify.config.json'
if (-not (Test-Path $cfgPath)) { Write-Error "Config not found. Run install.ps1."; exit 1 }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$logPath = Join-Path $dataDir 'inbox.log'

# --- Detect current project (for routing filter) ---
function Get-CurrentProject {
    $dir = (Get-Location).Path
    while ($dir -and (Test-Path $dir)) {
        if (Test-Path (Join-Path $dir '.git')) { return Split-Path $dir -Leaf }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    return Split-Path (Get-Location).Path -Leaf
}
$currentProject = if ($Project) { $Project } else { Get-CurrentProject }

# --- Parse phone message routing prefix ---
# Returns @{ Target = '<project-or-empty>'; Body = '<rest>' }
function Parse-RoutePrefix($text) {
    if (-not $text) { return @{ Target = ''; Body = '' } }
    # [project] body
    if ($text -match '^\s*\[([\w\.-]+)\]\s*(.*)$') {
        return @{ Target = $Matches[1].ToLower(); Body = $Matches[2] }
    }
    # project: body  (project = letters/digits/dash/underscore/dot, no spaces)
    if ($text -match '^\s*([\w\.-]+)\s*:\s*(.+)$') {
        return @{ Target = $Matches[1].ToLower(); Body = $Matches[2] }
    }
    return @{ Target = ''; Body = $text }
}

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

function Filter-Message($m) {
    if ((-not $IncludePi) -and ($m.title -match '^Agent')) { return $false }
    return $true
}

function Route-Match($m, $currentProject, $showAll) {
    if ($showAll) { return $true }
    # Phone messages: parse prefix; if untagged -> broadcast (visible to all)
    if ($m.title -match '^Agent') { return $true }   # outbound, ignore routing
    $route = Parse-RoutePrefix $m.message
    if ([string]::IsNullOrEmpty($route.Target)) { return $true }   # broadcast
    return ($route.Target -eq $currentProject.ToLower())
}

if ((Test-Path $logPath) -and -not $Network) {
    $source = 'local daemon log'
    $lines = Get-Content $logPath -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $m = $line | ConvertFrom-Json -ErrorAction Stop
            if ($m.time -lt $cutoff) { continue }
            if (-not (Filter-Message $m)) { continue }
            if (-not (Route-Match $m $currentProject $All)) { continue }
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
                if (-not (Filter-Message $m)) { continue }
                if (-not (Route-Match $m $currentProject $All)) { continue }
                $messages += $m
            } catch { }
        }
    }
}

$scopeLabel = if ($All) { 'all projects' } else { "project: $currentProject" }

if ($messages.Count -eq 0) {
    Write-Output "[inbox] (no messages in last ${Since}) [scope: $scopeLabel] [source: $source]"
    exit 0
}

Write-Output "[inbox] $($messages.Count) message(s) in last ${Since} [scope: $scopeLabel] [source: $source]:"
Write-Output ''
foreach ($m in $messages) {
    $ts = try {
        [DateTimeOffset]::FromUnixTimeSeconds([long]$m.time).LocalDateTime.ToString('HH:mm:ss')
    } catch { '--:--:--' }
    $who = if ($m.title) { $m.title } else { 'phone' }
    # Strip routing prefix from displayed body for clarity
    $displayMsg = $m.message
    if (-not ($m.title -match '^Agent')) {
        $route = Parse-RoutePrefix $m.message
        if ($route.Target) {
            $displayMsg = "-> $($route.Target): $($route.Body)"
        } else {
            $displayMsg = "(broadcast) $($m.message)"
        }
    }
    Write-Output "  ($ts) [$who] $displayMsg"
}
