# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

$ErrorActionPreference = "Stop"

# Network Changes
Write-host 'Setting network connection type to Private..'
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Stop Windows Update
Write-Host "Disabling Windows Updates.."
Set-Service wuauserv -StartupType Disabled
Stop-Service wuauserv

# Power Settings
Write-Host "Setting Power Performance"
$HPGuid = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "ElementName='High performance'").InstanceID.tostring()
$regex = [regex]"{(.*?)}$"
$PowerConfig = $regex.Match($HPGuid).groups[1].value 
& powercfg -S $PowerConfig
# Idle timeouts
powercfg.exe -x -monitor-timeout-ac 0
powercfg.exe -x -monitor-timeout-dc 0
powercfg.exe -x -disk-timeout-ac 0
powercfg.exe -x -disk-timeout-dc 0
powercfg.exe -x -standby-timeout-ac 0
powercfg.exe -x -standby-timeout-dc 0
powercfg.exe -x -hibernate-timeout-ac 0
powercfg.exe -x -hibernate-timeout-dc 0

# Disable Hibernation
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power\ -name HiberFileSizePercent -value 0
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power\ -name HibernateEnabled -value 0

# Set TimeZone
Write-host "Setting Time Zone to Eastern Standard Time"
Set-TimeZone -Name "Eastern Standard Time"

# Removing OneDrive
Write-Host "Removing OneDrive..."
$onedrive = Get-Process onedrive -ErrorAction SilentlyContinue
if ($onedrive) {
  taskkill /f /im OneDrive.exe
}
if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    & $env:systemroot\SysWOW64\OneDriveSetup.exe /uninstall /q
     if (!(Test-Path HKCR:))
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }
    if (Test-Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}") {
        Remove-Item -Force -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    }
    if (Test-Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}") {
        Remove-Item -Force -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    }
}

# Disabling A few Windows 10 Settings:
# Reference:
# https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services

$regConfig = @"
regKey,name,value,type
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE","DisablePrivacyExperience",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search","AllowCortana",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search","AllowSearchToUseLocation",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search","DisableWebSearch",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search","ConnectedSearchUseWeb",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata","PreventDeviceMetadataFromNetwork",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice","AllowFindMyDevice",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds","AllowBuildPreview",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Suggested Sites","Enabled",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer","AllowServicePoweredQSA",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete","AutoSuggest","no","String"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Geolocation","PolicyDisableGeolocation",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\PhishingFilter","EnabledV9",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\BrowserEmulation","DisableSiteListEditing",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\FlipAhead","Enabled",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Feeds","BackgroundSyncStatus",0,"DWord"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer","AllowOnlineTips",0,"DWord"
"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main","Start Page","about:blank","String"
"HKCU:\SOFTWARE\Microsoft\Internet Explorer\Control Panel","HomePage",1,"DWord"
"HKCU:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main","DisableFirstRunCustomize",1,"DWord"
"HKLM:\SYSTEM\CurrentControlSet\Services\LicenseManager","Start",4,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main","PreventFirstRunPage",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main","AllowPrelaunch", 0, "Dword"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications","NoCloudApplicationNotification",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive","DisableFileSyncNGSC",1,"DWord"
"HKLM:\SOFTWARE\Microsoft\OneDrive","PreventNetworkTrafficPreUserSignIn",1,"DWord"
"HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy","HasAccepted",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Speech","AllowSpeechModelUpdate",0,"DWord"
"HKCU:\SOFTWARE\Microsoft\InputPersonalization","RestrictImplicitTextCollection",1,"DWord"
"HKCU:\SOFTWARE\Microsoft\InputPersonalization","RestrictImplicitInkCollection",1,"DWord"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo","Enabled",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo","DisabledByGroupPolicy",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy","LetAppsAccessLocation",2,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors","DisableLocation",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection","DoNotShowFeedbackNotifications",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection","AllowTelemetry",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent","DisableWindowsConsumerFeatures",1,"DWord"
"HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent","DisableTailoredExperiencesWithDiagnosticData",1,"DWord"
"HKLM:\SOFTWARE\Policies\Policies\Microsoft\Windows\System","EnableSmartScreen",0,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen","ConfigureAppInstallControlEnabled",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen","ConfigureAppInstallControl","Anywhere","String"
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

# RDP enabled for all Windows hosts
# Adding Authenticated Users to Remote Desktop Users
write-Host "Adding Authenticated Users to Remote Desktop Users.."
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "Authenticated Users" -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"