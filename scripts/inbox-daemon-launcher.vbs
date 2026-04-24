' inbox-daemon-launcher.vbs — launches inbox-daemon.ps1 hidden (no console window)
' Shortcut to this file is placed in the Windows Startup folder for auto-start on login.
Set WshShell = CreateObject("WScript.Shell")
ScriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ScriptDir & "\inbox-daemon.ps1""", 0, False
