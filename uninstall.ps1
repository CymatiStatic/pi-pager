# uninstall.ps1 — remove pi-pager startup + data (keeps BurntToast and cloned repo)
# https://github.com/CymatiStatic/pi-pager

param(
    [switch]$KeepData = $false
)

$ErrorActionPreference = 'Continue'
Write-Host ""
Write-Host "=== pi-pager uninstaller ===" -ForegroundColor Cyan

$repoRoot   = Split-Path -Parent $PSCommandPath
$scriptsDir = Join-Path $repoRoot 'scripts'
$dataDir    = Join-Path $env:USERPROFILE '.pi-pager'

# 1. Stop daemon
$daemonScript = Join-Path $scriptsDir 'inbox-daemon.ps1'
if (Test-Path $daemonScript) {
    & powershell.exe -ExecutionPolicy Bypass -File $daemonScript -Stop
}

# 2. Remove startup shortcut
$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'pi-pager daemon.lnk'
if (Test-Path $shortcutPath) {
    Remove-Item $shortcutPath -Force
    Write-Host "[-] Removed startup shortcut"
}

# 3. Remove data dir
if (-not $KeepData -and (Test-Path $dataDir)) {
    Remove-Item $dataDir -Recurse -Force
    Write-Host "[-] Removed $dataDir"
} else {
    Write-Host "[=] Kept data dir: $dataDir"
}

Write-Host ""
Write-Host "Done. To fully remove, also:"
Write-Host "  Uninstall-Module BurntToast  (optional)"
Write-Host "  rm -r $repoRoot              (remove cloned repo)"
Write-Host ""
