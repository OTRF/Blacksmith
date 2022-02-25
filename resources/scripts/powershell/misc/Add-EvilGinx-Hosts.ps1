# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ServerAddresses,

    [Parameter(Mandatory=$true)]
    [string]$ServerDNSFQDN
)

$ErrorActionPreference = "Stop"

$hostsFilePath = "$($Env:WinDir)\system32\Drivers\etc\hosts"
$prefixStrings = @("www","login","example","subdomainhere","api","github","fls-na","images-na","outlook","account")

Foreach ($string in $prefixStrings){
    $hostname = $string, $ServerDNSFQDN -join "."
    $hostEntry = "$ServerAddresses $hostname"

    Write-Host "[+] Adding $hostEntry to $hostsFilePath.."
    Add-Content -Value $hostEntry -Path $hostsFilePath
}