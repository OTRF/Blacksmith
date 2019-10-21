# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://github.com/zulu8/Blue/blob/master/Deploy-Blue.ps1
# https://support.microsoft.com/en-us/help/921468/security-auditing-settings-are-not-applied-to-windows-vista-based-and

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$DomainDNSName,
    
    [Parameter(Mandatory=$true)]
    [string]$WECNetBIOSName,

    [Parameter(Mandatory=$false)]
    [switch]$SetDC
)

Write-host 'Enabling WinRM..'
winrm quickconfig -q

write-Host "Setting WinRM to start automatically.."
& sc.exe config WinRM start= auto

# Grant the Network Service account READ access to the event log by appending (A;;0x1;;;NS)
write-Host "Granting the Network Service account READ access to the Security event log.."
wevtutil set-log security /ca:'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)'

# Enabling Audit Policies
write-Host "Enabling Sub-categories .."

Write-host "Enabling Audit System Sub-Categories"
# Not auditing: IPsec Driver 
& auditpol.exe /set /subcategory:"Security System Extension","System Integrity","Other System Events","Security State Change" /success:enable /failure:enable

Write-host "Enabling Audit Logon/Logoff Sub-Categories"
# Not auditing: IPsec Main Mode, IPsec Quick Mode, IPsec Extended Mode, Network Policy Server, "User / Device Claims"
& auditpol.exe /set /subcategory:"Logon","Logoff","Account Lockout","Special Logon","Other Logon/Logoff Events","Group Membership" /success:enable /failure:enable

Write-host "Enabling Audit Object Access Sub-Categories"
# Not auditing: Application Generated, Filtering Platform Packet Drop 
& auditpol.exe /set /subcategory:"File System","Registry","Kernel Object","SAM","Certification Services","Handle Manipulation","File Share","Filtering Platform Connection","Other Object Access Events","Detailed File Share","Removable Storage","Central Policy Staging" /success:enable /failure:enable

Write-host "Enabling Audit Privilege Use Sub-Categories"
# Not auditing:  
& auditpol.exe /set /subcategory:"Non Sensitive Privilege Use","Other Privilege Use Events","Sensitive Privilege Use" /success:enable /failure:enable

Write-host "Enabling Audit Detailed Tracking Sub-Categories"
# Not auditing:  
& auditpol.exe /set /subcategory:"Process Creation","Process Termination","DPAPI Activity","RPC Events","Plug and Play Events","Token Right Adjusted Events" /success:enable /failure:enable

Write-host "Enabling Audit Policy Change Sub-Categories"
# Not auditing:  
& auditpol.exe /set /subcategory:"Audit Policy Change","Authentication Policy Change","Authorization Policy Change","MPSSVC Rule-Level Policy Change","Filtering Platform Policy Change","Other Policy Change Events" /success:enable /failure:enable

Write-host "Enabling Audit Account Management Sub-Categories"
# Not auditing: 
& auditpol.exe /set /subcategory:"Computer Account Management","Security Group Management","Distribution Group Management","Application Group Management","Other Account Management Events","User Account Management" /success:enable /failure:enable

Write-host "Enabling Audit Account Logon Sub-Categories"
# Not auditing: Kerberos Service Ticket Operations, Kerberos Authentication Service
& auditpol.exe /set /subcategory:"Other Account Logon Events","Credential Validation" /success:enable /failure:enable

if ($SetDC)
{
    Write-host "Enabling Audit DS Access Sub-Categories"
    # Not auditing:  
    & auditpol.exe /set /subcategory:"Directory Service Access","Directory Service Changes","Directory Service Replication","Detailed Directory Service Replication" /success:enable /failure:enable

    Write-host "Enabling Audit Account Logon Sub-Categories"
    # Not auditing:  
    & auditpol.exe /set /subcategory:"Kerberos Service Ticket Operations","Other Account Logon Events","Kerberos Authentication Service","Credential Validation" /success:enable /failure:enable
}

# WEC Server
$WECFQDN = $WECNetBIOSName+"."+$DomainDNSName

# Define Desired State for Registry Entries
$regConfig = @"
regKey,name,value,type
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","scenoapplylegacyauditpolicy",1,"DWord"
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit","ProcessCreationIncludeCmdLine_Enabled",1,"DWord"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager",1,"Server=http://$WECFQDN`:5985/wsman/SubscriptionManager/WEC,Refresh=60","String"
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