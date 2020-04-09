# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$GPOUrl,

    [Parameter(Mandatory=$true)]
    [string]$domainFQDN
)

$DomainName1,$DomainName2 = $domainFQDN.split('.')

$OutputFile = Split-Path $GPOUrl -leaf
$ZipFile = "$($env:TEMP)\$outputFile"

# Download Zipped File
$wc = new-object System.Net.WebClient
$wc.DownloadFile($GPOUrl, $ZipFile)

if (!(Test-Path $ZipFile))
{
    write-Host "File $ZipFile does not exists.. "
    break
}

# Unzip file
$file = (Get-Item $ZipFile).Basename
expand-archive -path $Zipfile -DestinationPath "$($env:TEMP)\"
if (!(Test-Path "$($env:TEMP)\$file"))
{
    write-Host "$ZipFile could not be decompressed successfully.. "
    break
}

$GPOFolder = "$($env:TEMP)\$file"
$GPOLocations = Get-ChildItem $GPOFolder | ForEach-Object {$_.BaseName}
$DCOU = "OU=Domain Controllers,DC=$DomainName1,DC=$DomainName2"
$WorkstationOU = "OU=Workstations,DC=$DomainName1,DC=$DomainName2"
$ServerOU = "OU=Servers,DC=$DomainName1,DC=$DomainName2"

foreach($GPO in $GPOLocations)
{
    $GPOName = $GPO.Replace("_"," ")
    write-Host "Creating GPO named: $GPOName "
    Import-GPO -BackupGpoName $GPOName -Path "$GPOFolder\$GPO" -TargetName $GPOName -CreateIfNeeded

    if(($GPOName -like "*controllers*") -or ($GPOName -like "*sam*"))
    {
        $gpLinks = $null
        $gPLinks = Get-ADOrganizationalUnit -Identity $DCOU -Properties name,distinguishedName, gPLink, gPOptions
        $GPO = Get-GPO -Name $GPOName
        If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
        {
            write-Host "Linking GPO $GPOName to $DCOU "
            New-GPLink -Name $GPOName -Target $DCOU -Enforced yes
        }
        else
        {
            Write-Host "GpLink $GPOName already linked on $DCOU. Moving On."
        }

    }
    elseif($GPOName -like "*workstation*")
    {
        $gpLinks = $null
        $gPLinks = Get-ADOrganizationalUnit -Identity $WorkstationOU -Properties name,distinguishedName, gPLink, gPOptions
        $GPO = Get-GPO -Name $GPOName
        If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
        {
            write-Host "Linking GPO $GPOName to $WorkstationOU "
            New-GPLink -Name $GPOName -Target $WorkstationOU -Enforced yes
        }
        else
        {
            Write-Host "GpLink $GPOName already linked on $WorkstationOU. Moving On."
        }

    }
    else{
        $OUS = @($DCOU, $WorkstationOU, $ServerOU)
        foreach($OU in $OUS)
        {
            $gpLinks = $null
            $gPLinks = Get-ADOrganizationalUnit -Identity $OU -Properties name,distinguishedName, gPLink, gPOptions
            $GPO = Get-GPO -Name $GPOName
            If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
            {
                write-Host "Linking GPO $GPOName to $OU "
                New-GPLink -Name $GPOName -Target $OU -Enforced yes
            }
            else
            {
                Write-Host "GpLink $GPOName already linked on $OU. Moving On."
            }
        }

    }
}