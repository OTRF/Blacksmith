# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://github.com/zulu8/Blue/blob/master/Deploy-Blue.ps1
# https://support.microsoft.com/en-us/help/921468/security-auditing-settings-are-not-applied-to-windows-vista-based-and

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$domainFQDN,
    
    [Parameter(Mandatory=$true)]
    [string]$WECNetBIOSName,
)

# Network Changes
Write-host 'Setting network connection type to Public..'
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

Write-host 'Enabling WinRM..'
winrm quickconfig -q

write-Host "Setting WinRM to start automatically.."
& sc.exe config WinRM start= auto

# Grant the Network Service account READ access to the event log by appending (A;;0x1;;;NS)
write-Host "Granting the Network Service account READ access to the Security event log.."
wevtutil set-log security /ca:'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)'

# WEC Server
$WECFQDN = $WECNetBIOSName+"."+$domainFQDN

# Define Desired State for Registry Entries
# References:
# https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-lan-manager-authentication-level
# https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-restrict-ntlm-outgoing-ntlm-traffic-to-remote-servers
$regConfig = @"
regKey,name,value,type
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","scenoapplylegacyauditpolicy",1,"DWord"
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit","ProcessCreationIncludeCmdLine_Enabled",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager",1,"Server=http://$WECFQDN`:5985/wsman/SubscriptionManager/WEC,Refresh=60","String"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","LmCompatibilityLevel",3,"DWord"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0","NTLMMinClientSec",537395200,"DWord"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0","RestrictSendingNTLMTraffic",2,"DWord"
"@

Write-host "Setting up Registry keys for auditing settings.."
$regConfig | ConvertFrom-Csv | ForEach-Object {
    if(!(Test-Path $_.regKey)){
        Write-Host $_.regKey " does not exist.."
        New-Item $_.regKey -Force
    }
    Write-Host "Setting " $_.regKey
    New-ItemProperty -Path $_.regKey -Name $_.name -Value $_.value -PropertyType $_.type -force
}

# Adding the Network Service to the Event Log Readers group
write-Host "Adding Network Service to Event Log Readers restricted group.."
Add-LocalGroupMember -Group "Event Log Readers" -Member "Network Service"

# Push Initial GPO updates
Write-host "Getting initial GPO updates.."
& gpupdate /force

Write-host "Restarting Endpoint.."
Restart-Computer -Force