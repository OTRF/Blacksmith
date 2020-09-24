# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Reference:
# https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-access-restrict-clients-allowed-to-make-remote-sam-calls

$regConfig = @"
regKey,name,value,type
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","restrictremotesam","O:BAG:BAD:(A;;RC;;;BA)","String"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","RestrictRemoteSamAuditOnlyMode",1,"DWord"
"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","RestrictRemoteSamEventThrottlingWindow",0,"DWord"
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