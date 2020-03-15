# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ServerAddresses,

    [Parameter(Mandatory=$false)]
    [switch]$SetDC
)

& .\Prepare-Box.ps1

if ($SetDC){
    & .\Set-SecurityAuditing.ps1 -SetDC
}
else{
    & .\Set-SecurityAuditing.ps1
}

# Installing Endpoint Agent
& .\Install-Endpoint-Agent.ps1 -EndpointAgent Sysmon

# Set Audit Rules (SACL)
Import-Module .\Set-AuditRule.ps1

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

# Setting static IP and DNS server IP
if ($ServerAddresses)
{
    & .\Set-StaticIP.ps1 -ServerAddresses $ServerAddresses
}