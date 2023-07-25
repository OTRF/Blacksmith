# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://learn.microsoft.com/en-us/power-automate/desktop-flows/machines-silent-registration
# https://github.com/Azure/azure-powershell/blob/main/src/Alb/utils/Unprotect-SecureString.ps1

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [System.Security.SecureString]$clientSecret,

    [Parameter(Mandatory=$true)]
    [String]$appClientId,

    [Parameter(Mandatory=$true)]
    [String]$tenantId,

    [Parameter(Mandatory=$true)]
    [String]$environmentId
)

$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)

try {
    Write-Host "[*] Registering $env:COMPUTERNAME to Power Automate platform .."
    Write-output [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr) | C:\'Program Files (x86)'\'Power Automate Desktop'\PAD.MachineRegistration.Silent.exe -register -applicationid $appClientId -clientsecret -tenantid $tenantId -environmentid $environmentId
}
catch {
    Write-Warning "Failed registering to Power Platform Error: $($Error[0])" 
}
finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}