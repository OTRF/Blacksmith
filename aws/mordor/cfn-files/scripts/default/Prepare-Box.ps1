# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]$LocalAdminPassword
)

Write-Host "Updating Local Administrator Password.."
([adsi]"WinNT://$env:computername/Administrator").SetPassword("$LocalAdminPassword")

# Stop Windows Update
Write-Host "Disabling Windows Updates.."
Set-Service wuauserv -StartupType Disabled
Stop-Service wuauserv

# Firewall Changes
Write-Host "Allow ICMP Traffic through firewall"
& netsh advfirewall firewall add rule name="ALL ICMP V4" protocol=icmpv4:any,any dir=in action=allow

Write-Host "Enable File and Printer Sharing"
& netsh firewall set service type = fileandprint mode = enable

Write-Host "Enable WMI traffic through the firewall"
& netsh advfirewall firewall set rule group="windows management instrumentation (wmi)" new enable=yes

# Power Settings
Write-Host "Setting Power Performance"
$HPGuid = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "ElementName='High performance'").InstanceID.tostring()
$regex = [regex]"{(.*?)}$"
$PowerConfig = $regex.Match($HPGuid).groups[1].value 
& powercfg -S $PowerConfig

# Set TimeZone
Write-host "Setting Time Zone to Eastern Standard Time"
Set-TimeZone -Name "Eastern Standard Time"

# Adding Authenticated Users to Remote Desktop Users
write-Host "Adding Authenticated Users to Remote Desktop Users.."
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "Authenticated Users"

# Removing OneDrive
Write-Host "Removing OneDrive..."
$onedrive = Get-Process onedrive -ErrorAction SilentlyContinue
if ($onedrive) {
  taskkill /f /im OneDrive.exe
}
if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    & $env:systemroot\SysWOW64\OneDriveSetup.exe /uninstall /q
    & REG Delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
    & REG Delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
}

# Disabling Cortana
Write-Host "Disabling Cortana.."
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0

# Disabling Notification Center
Write-Host "Disabling Notification Center.."
If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0

#Setting UAC level to Never Notify
Write-Host "Setting UAC level to Never Notify.."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0