# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]$LocalAdminPassword
)

Write-Host "Updating Local Administrator Password.."
([adsi]"WinNT://$env:computername/Administrator").SetPassword("$LocalAdminPassword")