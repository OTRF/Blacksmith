# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# REGISTRY
Import-Module .\Set-AuditRule.ps1

$AuditRules = @"
regKey;identityReference;rights;inheritanceFlags;propagationFlags;auditFlags
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunService";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceService";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunService";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceService";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Services\SysmonDrv\Parameters";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\.NETFramework";"Authenticated Users";"WriteKey";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam";"Authenticated Users";"SetValue,WriteKey";"ContainerInherit";"InheritOnly";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone";"Authenticated Users";"SetValue,WriteKey";"ContainerInherit";"InheritOnly";"Success"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController";"Authenticated Users";"SetValue,WriteKey";"ContainerInherit";"InheritOnly";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest";"Authenticated Users";"QueryValues,SetValue,WriteKey";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\JD";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Skew1";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\GBG";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Data";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SOFTWARE\Microsoft\Internet Explorer";"Authenticated Users";"QueryValues";"None";"None";"Success"
"HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment";"Authenticated Users";"QueryValues,SetValue,WriteKey";"None";"None";"Success"
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