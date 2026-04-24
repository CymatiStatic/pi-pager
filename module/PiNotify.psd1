@{
    RootModule        = 'PiNotify.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'b7c9e3f4-1a2d-4b6e-9f3c-8a7d6e5b4c3d'
    Author            = 'CymatiStatic'
    CompanyName       = 'CymatiStatic'
    Copyright         = '(c) 2026 CymatiStatic. MIT License.'
    Description       = 'Cross-channel alerts for agentic AI workflows: sound, Windows toast, phone/watch (ntfy), Discord, Slack, Telegram, Pushover. Auto-tags by git repo.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @('Send-PiNotify', 'Get-PiInbox', 'Get-PiDaemonStatus', 'Stop-PiDaemon')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('notification','ntfy','agent','ai','claude','cursor','pi','toast','webhook','windows')
            LicenseUri   = 'https://github.com/CymatiStatic/pi-notify/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/CymatiStatic/pi-notify'
            ReleaseNotes = 'https://github.com/CymatiStatic/pi-notify/releases'
        }
    }
}
