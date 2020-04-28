# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://www.elastic.co/downloads/beats/winlogbeat
# https://github.com/fireeye/SilkETW
# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#version_table
# https://medium.com/@cosmin.ciobanu/enhanced-endpoint-detection-using-sysmon-and-wef-3b65d491ff95

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Sysmon","SilkETW")]
    [string]$EndpointAgent
)

write-host "Installing $EndpointAgent .."

if($EndpointAgent -eq "Sysmon")
{
    $URL = "https://live.sysinternals.com/Sysmon.exe"
    Resolve-DnsName live.sysinternals.com
}
else
{
    $Url = "https://github.com/fireeye/SilkETW/releases/download/v0.8/SilkETW_SilkService_v8.zip"
}

Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

$OutputFile = Split-Path $Url -leaf
$File = "C:\ProgramData\$OutputFile"

# Download File
write-Host "Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($Url, $File)
if (!(Test-Path $File)){ Write-Error "File $File does not exist" -ErrorAction Stop }

if($EndpointAgent -eq "Sysmon")
{
    # Downloading Sysmon Configuration
    write-Host "Downloading Sysmon config.."
    $SysmonFile = "C:\ProgramData\sysmon.xml"
    $SysmonConfigUrl = "https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/resources/configs/sysmon/sysmonv11.0.xml"
    $wc.DownloadFile($SysmonConfigUrl, $SysmonFile)
    if (!(Test-Path $SysmonFile)){ Write-Error "File $SysmonFile does not exist" -ErrorAction Stop }

    # Installing Sysmon
    write-Host "Installing Sysmon.."
    & $File -i C:\ProgramData\sysmon.xml -accepteula
    
    write-Host "Setting Sysmon to start automatically.."
    & sc.exe config Sysmon start= auto

    # Setting Sysmon Channel Access permissions
    write-Host "Setting up Channel Access permissions for Microsoft-Windows-Sysmon/Operational "
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Sysmon/Operational" -Name "ChannelAccess" -PropertyType String -Value "O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)" -Force
    
    write-Host "Restarting Log Services .."
    $LogServices = @("Sysmon", "Windows Event Log")

    # Restarting Log Services
    foreach($LogService in $LogServices)
    {
        write-Host "Restarting $LogService .."
        Restart-Service -Name $LogService -Force

        write-Host "Verifying if $LogService is running.."
        $s = Get-Service -Name $LogService
        while ($s.Status -ne 'Running'){Start-Service $LogService; Start-Sleep 3}
        Start-Sleep 5
        write-Host "$LogService is running.."
    }
}
else
{
    # Unzip file
    write-Host "Decompressing $OutputFile .."
    $FileName = (Get-Item $File).Basename
    expand-archive -path $File -DestinationPath "C:\ProgramData\$FileName"
    if (!(Test-Path "C:\ProgramData\$FileName")){ Write-Error "$File was not decompressed successfully" -ErrorAction Stop }

    #Installing Dependencies
    #.NET Framework 4.5	All Windows operating systems: 378389
    $DotNetDWORD = 378388
    $DotNet_Check = Get-ChildItem "hklm:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release | % { $_ -ge $DotNetDWORD }
    if(!$DotNet_Check)
    {
        write-Host "NET Framework 4.5 or higher not installed.."
        & C:\ProgramData\$FileName\v8\Dependencies\dotNetFx45_Full_setup.exe /q /passive /norestart
        start-sleep -s 5
    }
    $MVC_Check = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "Microsoft Visual C++*"} | Select-Object DisplayName, DisplayVersion
    if (!$MVC_Check)
    {
        write-Host "Microsoft Visual C++ not installed.."
        & C:\ProgramData\$FileName\v8\Dependencies\vc2015_redist.x86.exe /q /passive /norestart
        start-sleep -s 5
    }

    # Download SilkServiceConfig.xml
    $SilkServiceConfigUrl = "https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/configs/SilkETW/SilkServiceConfig.xml"

    $OutputFile = Split-Path $SilkServiceConfigUrl -leaf
    $SilkServiceConfigPath = "C:\ProgramData\$FileName\v8\SilkService\SilkServiceConfig.xml"

    # Download Config File
    write-Host "Downloading $OutputFile .."
    $wc = new-object System.Net.WebClient
    $wc.DownloadFile($SilkServiceConfigUrl, $SilkServiceConfigPath)
    if (!(Test-Path $SilkServiceConfigPath)){ Write-Error "SilkServiceConfig does not exist" -ErrorAction Stop }

    # Installing Service
    write-host "Creating the new SilkETW service.."
    New-Service -name SilkETW `
    -displayName SilkETW `
    -binaryPathName "C:\ProgramData\$FileName\v8\SilkService\SilkService.exe" `
    -StartupType Automatic `
    -Description "This is the SilkETW service to consume ETW events."

    Start-Sleep -s 10

    # Starting SilkETW Service
    write-host "Starting SilkETW service.."
    $ServiceName = 'SilkETW'
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
}