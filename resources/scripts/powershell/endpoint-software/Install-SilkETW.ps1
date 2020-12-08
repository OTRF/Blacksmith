# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://github.com/fireeye/SilkETW
# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#version_table

write-host "[+] Processing SilkETW Installation.."

$Url = "https://github.com/fireeye/SilkETW/releases/download/v0.8/SilkETW_SilkService_v8.zip"
Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

$OutputFile = Split-Path $Url -leaf
$File = "C:\ProgramData\$OutputFile"

# Download File
write-Host "[+] Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($Url, $File)
if (!(Test-Path $File)) { Write-Error "File $File does not exist" -ErrorAction Stop }

# Unzip file
write-Host "[+] Decompressing $OutputFile .."
$FileName = (Get-Item $File).Basename
expand-archive -path $File -DestinationPath "C:\ProgramData\$FileName"
if (!(Test-Path "C:\ProgramData\$FileName")) { Write-Error "$File was not decompressed successfully" -ErrorAction Stop }

#Installing Dependencies
#.NET Framework 4.5	All Windows operating systems: 378389
$DotNetDWORD = 378388
$DotNet_Check = Get-ChildItem "hklm:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release | % { $_ -ge $DotNetDWORD }
if (!$DotNet_Check)
{
    write-Host "[!] NET Framework 4.5 or higher not installed.."
    & C:\ProgramData\$FileName\v8\Dependencies\dotNetFx45_Full_setup.exe /q /passive /norestart
    start-sleep -s 5
}
$MVC_Check = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.displayname -like "Microsoft Visual C++*" } | Select-Object DisplayName, DisplayVersion
if (!$MVC_Check)
{
    write-Host "[!] Microsoft Visual C++ not installed.."
    & C:\ProgramData\$FileName\v8\Dependencies\vc2015_redist.x86.exe /q /passive /norestart
    start-sleep -s 5
}

# Download SilkServiceConfig.xml
$SilkServiceConfigUrl = "https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/configs/SilkETW/SilkServiceConfig.xml"

$OutputFile = Split-Path $SilkServiceConfigUrl -leaf
$SilkServiceConfigPath = "C:\ProgramData\$FileName\v8\SilkService\SilkServiceConfig.xml"

# Download Config File
write-Host "[+] Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($SilkServiceConfigUrl, $SilkServiceConfigPath)
if (!(Test-Path $SilkServiceConfigPath)) { Write-Error "SilkServiceConfig does not exist" -ErrorAction Stop }

# Installing Service
write-host "[+] Creating the new SilkETW service.."
New-Service -name SilkETW `
    -displayName SilkETW `
    -binaryPathName "C:\ProgramData\$FileName\v8\SilkService\SilkService.exe" `
    -StartupType Automatic `
    -Description "This is the SilkETW service to consume ETW events."

Start-Sleep -s 10

# Starting SilkETW Service
write-host "[+] Starting SilkETW service.."
$ServiceName = 'SilkETW'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host '  [*] Service starting'
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host '  [*] Service is now Running'
    }
}
