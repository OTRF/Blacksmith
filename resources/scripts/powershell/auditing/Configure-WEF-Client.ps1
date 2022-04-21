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
    [string]$WECNetBIOSName
)

# Enable WinRM if it is not enabled
$ServiceName = 'WinRM'
$arrService = Get-Service -Name $ServiceName

if ($arrService.Status -eq 'Running')
{
    Write-Host "$ServiceName Service is now Running"
}
else
{
    Write-host 'Enabling WinRM..'
    winrm quickconfig -q
    write-Host "Setting WinRM to start automatically.."
    & sc.exe config WinRM start= auto
}

# Grant the Network Service account READ access to the event log by appending (A;;0x1;;;NS)
write-Host "Granting the Network Service account READ access to the Security event log.."
wevtutil set-log security /ca:'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)'

# WEC Server
$WECFQDN = $WECNetBIOSName+"."+$domainFQDN

# WEF/WEC Registry Entry
$regKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager"
if(!(Test-Path $regKey)){Write-Host $regKey " does not exist.."
    New-Item $regKey -Force
}
Write-Host "Setting " $regKey
New-ItemProperty -Path $regKey -Name 1 -Value "Server=http://$WECFQDN`:5985/wsman/SubscriptionManager/WEC,Refresh=60" -PropertyType "String" -force

# Adding the Network Service to the Event Log Readers group
write-Host "Adding Network Service to Event Log Readers restricted group.."
Add-LocalGroupMember -Group "Event Log Readers" -Member "Network Service"
# net.exe localgroup "Event Log Readers" "Network Service" /add

Restart-Service WinRM

$ServiceName = 'WinRM'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host "$ServiceName Service starting"
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host "$ServiceName Service is now Running"
    }
}