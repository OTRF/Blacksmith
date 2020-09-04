# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Winlogbeat","Nxlog")]
    [string]$ShipperAgent,

    [Parameter(Mandatory=$true)]
    [string]$ConfigUrl,

    [Parameter(Mandatory=$false)]
    [string]$DestinationIP

)

if($ShipperAgent -eq "Winlogbeat")
{
    $URL = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.4.0-windows-x86_64.zip"
    Resolve-DnsName artifacts.elastic.co
}
else
{
    $Url = "https://nxlog.co/system/files/products/files/348/nxlog-ce-2.10.2150.msi"
    Resolve-DnsName nxlog.co
}

$OutputFile = Split-Path $URL -leaf
$NewFile = "C:\ProgramData\$outputFile"

# Download Installer
write-Host "Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($Url, $NewFile)
if (!(Test-Path $NewFile)){ Write-Error "File $NewFile does not exist" -ErrorAction Stop}

if($ShipperAgent -eq "Winlogbeat")
{
    # Unzip file
    write-Host "Decompressing $OutputFile .."
    $file = (Get-Item $NewFile).Basename
    expand-archive -path $NewFile -DestinationPath "C:\Program Files\"
    if (!(Test-Path "C:\Program Files\$file")){ Write-Error "$NewFile was not decompressed successfully" -ErrorAction Stop }

    # Renaming Folder & File
    write-Host "Renaming folder from C:\Program Files\$file to C:\Program Files\Winlogbeat .."
    Rename-Item "C:\Program Files\$file" "C:\Program Files\Winlogbeat" -Force

    # Backing up default Winlogbeat configuration
    write-Host "Renaming file from C:\Program Files\Winlogbeat\winlogbeat.yml to C:\Program Files\Winlogbeat\winlogbeat.backup .."
    Rename-Item "C:\Program Files\Winlogbeat\winlogbeat.yml" "C:\Program Files\Winlogbeat\winlogbeat.backup" -Force

    # Installing Winlogbeat Service
    write-Host "Installing Winlogbeat Service.."
    & "C:\Program Files\Winlogbeat\install-service-winlogbeat.ps1"

    $shipperConfig = "C:\Program Files\Winlogbeat\winlogbeat.yml"
    $ServiceName = 'winlogbeat'
}
else
{
    # Installing nxlog
    write-Host "Installing nxlog .."
    & c:\Windows\system32\msiexec /passive /qn /i $NewFile

    # Download nxlog Config
    write-Host "waiting for nxlog folder to exist .."
    while (!(Test-Path "C:\Program Files (x86)\nxlog")) { Start-Sleep 5 }

    # Renaming File
    write-Host "Renaming original nxlog config .."
    while (!(Test-Path "C:\Program Files (x86)\nxlog\conf\nxlog.conf")) { Start-Sleep 5 }
    Rename-Item "C:\Program Files (x86)\nxlog\conf\nxlog.conf" "C:\Program Files (x86)\nxlog\conf\nxlog.backup.conf" -Force

    $shipperConfig = "C:\Program Files (x86)\nxlog\conf\nxlog.conf"
    $ServiceName = 'nxlog'
}

# Download shipper config
write-Host "Downloading shipper config.."
$wc.DownloadFile($ConfigUrl, $shipperConfig)
if (!(Test-Path $shipperConfig)){ Write-Error "File $shipperConfig does not exist" -ErrorAction Stop }

# Updating Config IP
((Get-Content -path $shipperConfig -Raw) -replace 'IPADDRESS',$DestinationIP) | Set-Content -Path $shipperConfig

# Installing Service
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host "Service $ServiceName starting"
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host "Service $ServiceName is now Running"
    }
}
write-Host "$ServiceName is running.."