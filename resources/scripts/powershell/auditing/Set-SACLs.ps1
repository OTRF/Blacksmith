# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# REGISTRY
Import-Module .\Set-AuditRule.ps1

$AuditRules = @"
regKey;identityReference;rights;inheritanceFlags;propagationFlags;auditFlags
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunService";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceService";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunService";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceService";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\Software\Policies\Microsoft Services\AdmPwd";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa";"Everyone";"QueryValues";"None";"None";"Success"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Services\SysmonDrv\Parameters";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\Software\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\Software\Microsoft\.NETFramework";"Everyone";"WriteKey";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam";"Everyone";"SetValue,WriteKey";"ContainerInherit";"InheritOnly";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone";"Everyone";"SetValue,WriteKey";"ContainerInherit";"InheritOnly";"Success"
"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController";"Everyone";"SetValue,WriteKey";"ContainerInherit";"InheritOnly";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest";"Everyone";"QueryValues,SetValue,WriteKey";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\JD";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Skew1";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\GBG";"Everyone";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Data";"Everyone";"QueryValues";"None";"None";"Success"
"@

write-host "Enabling audit rules.."
$AuditRules | ConvertFrom-Csv -Delimiter ';' | ForEach-Object {
    if(!(Test-Path $_.regKey)){
        Write-Host $_.regKey " does not exist.."
    }
    else {
        Write-Host "Updating SACL of " $_.regKey
        Set-AuditRule -RegistryPath $_.regKey -IdentityReference $_.identityReference  -Rights $_.rights.split(",") -InheritanceFlags $_.inheritanceFlags -PropagationFlags $_.propagationFlags -AuditFlags $_.auditFlags -ErrorAction SilentlyContinue
    }
}

# SERVICES

# Update SDDL of a service and add (AU;SAFA;RPWPDTCCLC;;;WD)
<#
Ace Type:
"AU": SYSTEM_AUDIT_ACE_TYPE
Ace Flags:
"SA"    : SUCCESSFUL_ACCESS_ACE_FLAG
"FA"    : FAILED_ACCESS_ACE_FLAG
Rights:
RP : SERVICE_START – start the service
WP: SERVICE_STOP – stop the service
DT: SERVICE_PAUSE_CONTINUE – pause / continue the service
CC – SERVICE_QUERY_CONFIG – ask the SCM for the service's current configuration
LC – SERVICE_QUERY_STATUS – ask the SCM for the service's current status
Object Guid: NA
Inherit Object Guid: NA
Account SIDs:
  * WD: SDDL_EVERYONE
  * NU: SDDL_NETWORK
#>
$ServiceRules = @"
service;addition
"IKEEXT";"(AU;SAFA;RPWPDTCCLC;;;WD)"
"SessionEnv";"S:(AU;SAFA;RPWPDTCCLC;;;WD)"
"scmanager";"(AU;SAFA;GA;;;NU)"
"@

$ServiceRules | ConvertFrom-Csv -Delimiter ';' | ForEach-Object {
    if(Get-Service $service){
        Write-Host "[+] Processing " $_.service
        # Get Sddl
        $sddl = (& $env:SystemRoot\System32\sc.exe sdshow $_.service | Out-String).Trim()
        # Define new Sddl
        $newSddl = ('{0}{1}' -f $sddl, $_.addition).Trim()
        # Update Sddl
        write-host "  [>] Updating SDDL.."
        & $env:SystemRoot\System32\sc.exe sdset $_.service "$newSddl"
    }
} 