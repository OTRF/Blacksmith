# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [switch]$SetDC
)

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

$regConfig = @"
regKey,name,value,type
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","scenoapplylegacyauditpolicy",1,"DWord"
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit","ProcessCreationIncludeCmdLine_Enabled",1,"DWord"
"@

Write-host "Setting up Registry keys for additional auditing settings.."
$regConfig | ConvertFrom-Csv | ForEach-Object {
    if(!(Test-Path $_.regKey)){
        Write-Host $_.regKey " does not exist.."
        New-Item $_.regKey -Force
    }
    Write-Host "Setting " $_.regKey
    New-ItemProperty -Path $_.regKey -Name $_.name -Value $_.value -PropertyType $_.type -force
}