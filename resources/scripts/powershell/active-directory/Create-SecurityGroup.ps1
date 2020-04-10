# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$SecurityGroup,

    [Parameter(Mandatory=$true)]
    [string]$domainFQDN
)

$ErrorActionPreference = "Stop"

$DomainName1,$DomainName2 = $domainFQDN.split('.')

$ParentPath = "DC=$DomainName1,DC=$DomainName2"

write-host "Creating Security Group $SecurityGroup on $ParentPath .." 
New-ADGroup -Name $SecurityGroup -GroupCategory Security -GroupScope Global `
    -DisplayName "$SecurityGroup" -Path "CN=Users,$ParentPath" `
    -Description "Security group $SecurityGroup" -PassThru