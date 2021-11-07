# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://www.ultimatewindowssecurity.com/webinars/watch_get.aspx?Attach=1&Type=SlidesPDF&ID=1426
# https://community.softwaregrp.com/dcvta86296/attachments/dcvta86296/arcsight-discussions/24729/1/Protect2015-WindowsEventForwarding.pdf
# https://docs.microsoft.com/en-us/biztalk/technical-guides/settings-that-can-be-modified-to-improve-network-performance

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionsUrl
)

# ********* Install Sysmon Manifest ***********
$URL = "https://live.sysinternals.com/Sysmon.exe"
Resolve-DnsName live.sysinternals.com
Resolve-DnsName raw.githubusercontent.com

$OutputFile = Split-Path $URL -leaf
$File = "C:\ProgramData\$OutputFile"

# Download File
write-Host "Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($URL, $File)
if (!(Test-Path $File)){ Write-Error "File $File does not exist" -ErrorAction Stop }

# Install Manifest
& $File -m

# ********* Setting WinRM Configs for WEC ***********
Write-host 'Enabling WinRM..'
winrm quickconfig -q
winrm quickconfig -transport:http

write-Host "Setting WinRM to start automatically.."
& sc.exe config WinRM start= auto

winrm set winrm/config '@{MaxEnvelopeSizekb="500"}'
winrm set winrm/config '@{MaxTimeoutms="60000"}'
winrm set winrm/config '@{MaxBatchItems="32000"}'
winrm set winrm/config/client '@{NetworkDelayms="5000"}'
winrm set winrm/config/service '@{MaxConcurrentOperations="4294967295"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="1500"}'
winrm set winrm/config/service '@{MaxConnections="500"}'
winrm set winrm/config/service '@{MaxPacketRetrievalTimeSeconds="120"}'
winrm set winrm/config/winrs '@{IdleTimeout="7200000"}'
winrm set winrm/config/winrs '@{MaxConcurrentUsers="10"}'
winrm set winrm/config/winrs '@{MaxShellRunTime="2147483647"}'
winrm set winrm/config/winrs '@{MaxProcessesPerShell="25"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config/winrs '@{MaxShellsPerUser="30"}'

winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/client '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'

Restart-Service WinRM

$ServiceName = 'WinRM'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host "$ServiceName Service starting"
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host "$ServiceName Service is now Running"
    }
}

# ********** Updating ForwardedEvents log size *******
wevtutil sl ForwardedEvents /ms:8589934592

# ********** Starting WEC Service *************
Stop-Service wecsvc
Set-Service wecsvc -StartupType "Automatic"

# Stand-alone service instead of shared
# Powershell version of : sc config wecsvc type=own
$s = (Get-WmiObject win32_service -filter "Name='wecsvc'")
$s.Change($null, $null, 16)
Start-Service wecsvc

$ServiceName = 'wecsvc'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host "$ServiceName Service starting"
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host "$ServiceName Service is now Running"
    }
}

# ******** Importing WEF subscriptions *******
$OutputFile = Split-Path $SubscriptionsUrl -leaf
$ZipFile = "C:\ProgramData\$outputFile"

# Download Zipped File
write-Host "Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($SubscriptionsUrl, $ZipFile)

if (!(Test-Path $ZipFile)){ Write-Error "File $ZipFile does not exist" -ErrorAction Stop }

# Unzip file
write-Host "Decompressing $ZipFile .."
$file = (Get-Item $ZipFile).Basename
expand-archive -path $Zipfile -DestinationPath "C:\ProgramData\"

# Importing Subscriptions
if (Test-Path "C:\ProgramData\$file")
{
    write-Host "Importing WEF Subscriptions.. "
    Get-ChildItem "C:\ProgramData\$file" | ForEach-Object { wecutil cs $_.FullName}
}
else {
    Write-Error "File $ZipFile was not decompressed successfully" -ErrorAction Stop
}

# ********** Additional Tunning ***************
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-ForwardedEvents" -Name "BufferSize" -Type "DWORD" -Value "2048"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-ForwardedEvents" -Name "FlushTimer" -Type "DWORD" -Value "0"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-ForwardedEvents" -Name "MaximumBuffers" -Type "DWORD" -Value "8192"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-ForwardedEvents" -Name "MinimumBuffers" -Type "DWORD" -Value "0"

# The TcpTimedWaitDelay value determines the length of time that a connection stays in the TIME_WAIT state when being closed
New-ItemProperty –Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" –Name "TcpTimedWaitDelay" –Type "Dword" –Value "30"

# Configure Event Collector
& wecutil qc -quiet

Restart-Service wecsvc

$ServiceName = 'wecsvc'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host "$ServiceName Service starting"
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host "$ServiceName Service is now Running"
    }
}