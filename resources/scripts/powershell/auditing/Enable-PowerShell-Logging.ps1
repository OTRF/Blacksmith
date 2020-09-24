# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Enable PowerShell Logging
$regConfig = @"
regKey,name,value,type
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging","EnableScriptBlockLogging",1,"DWORD"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging","EnableScriptBlockInvocationLogging",1,"DWORD"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging","EnableModuleLogging",1,"DWORD"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames",*,*,"String"
"@

Write-host "Setting up PowerShell registry settings.."
$regConfig | ConvertFrom-Csv | ForEach-Object {
    if(!(Test-Path $_.regKey)){
        Write-Host $_.regKey " does not exist.."
        New-Item $_.regKey -Force
    }
    Write-Host "Setting " $_.regKey
    New-ItemProperty -Path $_.regKey -Name $_.name -Value $_.value -PropertyType $_.type -force
}