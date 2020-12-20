# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://www.itprotoday.com/windows-78/create-large-number-ous-set-structure-and-delegation

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$domainFQDN
)

# Verifying ADWS service is running
$ServiceName = 'ADWS'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }
}

$DomainName1,$DomainName2 = $domainFQDN.split('.')

$ParentPath = "DC=$DomainName1,DC=$DomainName2"
$OUS = @(("Workstations","Workstations in the domain"),("Servers","Servers in the domain"),("LogCollectors","Servers collecting event logs"),("DomainUsers","Users in the domain"))

foreach($OU in $OUS)
{
    #Check if exists, if it does skip
    [string] $Path = "OU=$($OU[0]),$ParentPath"
    write-host "Checking to see if $Path exists or not"
    if(![adsi]::Exists("LDAP://$Path"))
    {
        write-host "Creating OU $OU .." 
        New-ADOrganizationalUnit -Name $OU[0] -Path $ParentPath `
            -Description $OU[1] `
            -ProtectedFromAccidentalDeletion $false -PassThru
    }
}