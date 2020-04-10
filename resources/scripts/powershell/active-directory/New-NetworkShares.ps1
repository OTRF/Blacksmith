# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://ilovepowershell.com/2012/09/19/create-network-share-with-powershell-3/
# https://lotr.fandom.com/wiki/Ring-inscription

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$domainFQDN
)

$ErrorActionPreference = "Stop"

$DomainName1,$DomainName2 = $domainFQDN.split('.')

$folders = @("secrets", "gates")

foreach($folder in $folders)
{
    New-Item C:\$folder -type directory
    if($folder -Like "secrets")
    {
        New-SMBShare -Name "secrets" -Path "C:\secrets" `
            -FullAccess "$DomainName1\Domain Admins"
    }
    else
    {
        New-SMBShare -Name "gates" -Path "C:\gates" `
            -FullAccess "$DomainName1\Domain Admins" `
            -ReadAccess "$DomainName1\Domain Users"
    }
}

# Create secret file
Write-Output "One Ring to rule them all, One ring to find them; One ring to bring them all and in the darkness bind them" > C:\secrets\ring.txt