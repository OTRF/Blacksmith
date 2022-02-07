# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

$ErrorActionPreference = "Stop"

# Registry configurations
# References:
# https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-lan-manager-authentication-level
# https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-restrict-ntlm-outgoing-ntlm-traffic-to-remote-servers
# https://github.com/eladshamir/Internal-Monologue/blob/85134e4ebe5ea9e7f6b39d4b4ad467e40a0c9eca/InternalMonologue/InternalMonologue.cs

$regConfig = @"
regKey,name,value,type
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","LmCompatibilityLevel",2,"DWord"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0","NTLMMinClientSec",536870912,"DWord"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0","RestrictSendingNTLMTraffic",0,"DWord"
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

# Enable Remote Registry Service 
$ServiceName = 'remoteregistry'
$arrService = Get-Service -Name $ServiceName

if ($arrService.Status -eq 'Running')
{
    Write-Host "$ServiceName Service is now Running"
}
else
{
    Write-host 'Enabling Remote Registry..'
    & sc.exe start remoteregistry
    write-Host "Setting Remote Registry to start automatically.."
    & sc.exe config remoteregistry start= auto
}

# Setting UAC level to Never Notify
Write-Host "Setting UAC level to Never Notify.."
Set-ItemProperty -Force -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0

# *** Registry modified to allow storage of wdigest credentials ***
Write-Host "Setting WDigest to use logoncredential.."
Set-ItemProperty -Force -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Value "1"