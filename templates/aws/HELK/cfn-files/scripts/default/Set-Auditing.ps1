# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://github.com/zulu8/Blue/blob/master/Deploy-Blue.ps1
# https://support.microsoft.com/en-us/help/921468/security-auditing-settings-are-not-applied-to-windows-vista-based-and

# Network Changes
Write-host 'Setting network connection type to Public..'
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

Write-host 'Enabling WinRM..'
winrm quickconfig -q

write-Host "Setting WinRM to start automatically.."
& sc.exe config WinRM start= auto

# Set Audit Rules (SACL)
$AuditRuleModule = "https://raw.githubusercontent.com/hunters-forge/Set-AuditRule/master/Set-AuditRule.ps1"
$AuditRuleFile = Split-Path $AuditRuleModule -leaf
$NewFile = "c:\cfn\scripts\$AuditRuleFile"

write-Host "Downloading $AuditRuleFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($AuditRuleModule, $NewFile)
if (!(Test-Path $NewFile)){ write-Host "File $NewFile does not exists.. "; break }

write-host "Importing Set-AuditRule module.."
Import-Module $NewFile

$AuditRules = @"
regKey,identityReference,rights,inheritanceFlags,propagationFlags,auditFlags
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunService","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceService","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunService","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceService","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","Everyone","QueryValues","None","None","Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment","Everyone","QueryValues","None","None","Success"
"HKLM:\Software\Policies\Microsoft Services\AdmPwd","Everyone","QueryValues","None","None","Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Microsoft\PowerShell\1","Everyone","QueryValues","ContainerInherit","InheritOnly","Success"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging","Everyone","QueryValues","None","None","Success"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription","Everyone","QueryValues","None","None","Success"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU","Everyone","QueryValues","None","None","Success"
"HKLM:\SYSTEM\CurrentControlSet\Services\SysmonDrv\Parameters","Everyone","QueryValues","None","None","Success"
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit","Everyone","QueryValues","None","None","Success"
"HKLM:\Software\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager","Everyone","QueryValues","None","None","Success"
"@

write-host "Enabling audit rules.."
$AuditRules | ConvertFrom-Csv | ForEach-Object {
    if(!(Test-Path $_.regKey)){
        Write-Host $_.regKey " does not exist.."
    }
    else {
        Write-Host "Updating SACL of " $_.regKey
        Set-AuditRule -RegistryPath $_.regKey -IdentityReference $_.identityReference -Rights $_.rights -InheritanceFlags $_.inheritanceFlags -PropagationFlags $_.propagationFlags -AuditFlags $_.auditFlags -ErrorAction SilentlyContinue
    }
}

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

# Define Desired State for Registry Entries
$regConfig = @"
regKey,name,value,type
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","scenoapplylegacyauditpolicy",1,"DWord"
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit","ProcessCreationIncludeCmdLine_Enabled",1,"DWord"
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

Write-host "Restarting Endpoint.."
Restart-Computer -Force