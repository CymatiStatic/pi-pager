@{
    RootModule        = 'PiPager.psm1'
    ModuleVersion     = '0.3.0'
    GUID              = 'b7c9e3f4-1a2d-4b6e-9f3c-8a7d6e5b4c3d'
    Author            = 'CymatiStatic'
    CompanyName       = 'CymatiStatic'
    Copyright         = '(c) 2026 CymatiStatic. MIT License.'
    Description       = 'Cross-channel alerts for agentic AI workflows: sound, Windows toast, phone/watch (ntfy), Discord, Slack, Telegram, Pushover. Auto-tags by git repo.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @('Send-PiPage', 'Get-PiPagerInbox', 'Get-PiPagerDaemonStatus', 'Stop-PiPagerDaemon')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @('pipage', 'pipager')

    PrivateData = @{
        PSData = @{
            Tags         = @('notification','ntfy','agent','ai','claude','cursor','pi','toast','webhook','windows')
            LicenseUri   = 'https://github.com/CymatiStatic/pi-pager/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/CymatiStatic/pi-pager'
            ReleaseNotes = 'https://github.com/CymatiStatic/pi-pager/releases'
        }
    }
}
