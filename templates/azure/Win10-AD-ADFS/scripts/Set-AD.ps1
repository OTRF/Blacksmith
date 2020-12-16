# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [string]$domainFQDN,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$dcVMName
)

& .\Set-OUs.ps1 -domainFQDN $domainFQDN
& .\Add-DomainUsers.ps1 -domainFQDN $domainFQDN -dcVMName $dcVMName
& .\Set-AuditSAMRemoteCalls.ps1