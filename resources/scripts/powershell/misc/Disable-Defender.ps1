# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# PowerShellGet requires NuGet provider version '2.8.5.201' or newer to interact with NuGet-based repositories. The NuGet
# provider must be available in 'C:\Program Files\PackageManagement\ProviderAssemblies' or
#'C:\Users\wardog\AppData\Local\PackageManagement\ProviderAssemblies'. You can also install the NuGet provider by
#running 'Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force'.

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module NTObjectManager -Scope CurrentUser -Force

Import-Module NTObjectManager

write-host "Starting TrustedInstaller service.."
$ServiceName = 'TrustedInstaller'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }
}

$p = Get-NTProcess -Name TrustedInstaller.exe

$proc = New-Win32Process powershell.exe -CreationFlags NewConsole -ParentProcess $p

$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows Defender\features",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership)
$regACL = $regKey.GetAccessControl()
$regACL.SetOwner([System.Security.Principal.NTAccount]"Administrators")
$regKey.SetAccessControl($regACL)
# Change Permissions for the local Administrators group
$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows Defender\features",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
$regACL = $regKey.GetAccessControl()
$regRule = New-Object System.Security.AccessControl.RegistryAccessRule ("Administrators","FullControl","ContainerInherit","None","Allow")
$regACL.SetAccessRule($regRule)
$regKey.SetAccessControl($regACL)

# Disable WIndows Defender
set-MpPreference -DisableRealtimeMonitoring $true

$regConfig = @"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection", "DisableBehaviorMonitoring",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection", "DisableOnAccessProtection",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection", "DisableRealtimeMonitoring",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection", "DisableScanOnRealtimeEnable",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection", "DisableScriptScanning",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet","SpyNetReporting",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet","SubmitSamplesConsent",2,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender","DisableAntiSpyware",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine","MpCloudBlockLevel",0,"DWord"
"@

Write-host "Setting up Registry keys for additional settings.."
$regConfig | ConvertFrom-Csv | ForEach-Object {
    if(!(Test-Path $_.regKey)){
        Write-Host $_.regKey " does not exist.."
        New-Item $_.regKey -Force
    }
    Write-Host "Setting " $_.regKey
    New-ItemProperty -Path $_.regKey -Name $_.name -Value $_.value -PropertyType $_.type -force
}