# PiPager.psm1 — PowerShell module wrapper around pi-pager scripts.
# Publish: Publish-Module -Path .\module -NuGetApiKey <key>

$script:ScriptDir = Join-Path $PSScriptRoot '..' 'scripts' | Resolve-Path -ErrorAction SilentlyContinue
if (-not $script:ScriptDir) { $script:ScriptDir = Join-Path $PSScriptRoot 'scripts' }

function Send-PiPage {
    <#
    .SYNOPSIS
    Fire a pi-pager alert on all enabled channels.
    .PARAMETER Type
    Alert type: input | done | warn | error
    .PARAMETER Message
    Body text shown to user.
    .PARAMETER Title
    Optional title override (default auto-derived from git repo).
    .PARAMETER Wait
    Block until a reply arrives on ntfy (max -TimeoutSec).
    .EXAMPLE
    Send-PiPage -Type done -Message 'Build passed'
    .EXAMPLE
    $reply = Send-PiPage -Type input -Message 'Deploy to prod?' -Wait -TimeoutSec 60
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('input','done','warn','error')]
        [string]$Type = 'input',
        [Parameter(Mandatory)][string]$Message,
        [string]$Title = 'Agent',
        [switch]$Wait,
        [int]$TimeoutSec = 120
    )
    $scriptPath = Join-Path $script:ScriptDir 'notify.ps1'
    $args = @('-Type', $Type, '-Message', $Message, '-Title', $Title)
    if ($Wait) { $args += '-Wait'; $args += @('-TimeoutSec', $TimeoutSec) }
    & $scriptPath @args
}

function Get-PiPagerInbox {
    <#
    .SYNOPSIS
    Read messages sent to the agent from your phone.
    .PARAMETER Since
    Duration like '10m', '1h', '30s'. Default 10m.
    .EXAMPLE
    Get-PiPagerInbox -Since 1h
    #>
    [CmdletBinding()]
    param(
        [string]$Since = '10m',
        [switch]$IncludePi,
        [switch]$Network
    )
    $scriptPath = Join-Path $script:ScriptDir 'inbox.ps1'
    $args = @('-Since', $Since)
    if ($IncludePi) { $args += '-IncludePi' }
    if ($Network)   { $args += '-Network' }
    & $scriptPath @args
}

function Get-PiPagerDaemonStatus {
    <#
    .SYNOPSIS
    Check if the pi-pager inbox daemon is running.
    #>
    [CmdletBinding()]
    param()
    $scriptPath = Join-Path $script:ScriptDir 'inbox-daemon.ps1'
    & $scriptPath -Status
}

function Stop-PiPagerDaemon {
    [CmdletBinding()]
    param()
    $scriptPath = Join-Path $script:ScriptDir 'inbox-daemon.ps1'
    & $scriptPath -Stop
}

Export-ModuleMember -Function Send-PiPage, Get-PiPagerInbox, Get-PiPagerDaemonStatus, Stop-PiPagerDaemon
