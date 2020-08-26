# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://copdips.com/2019/12/Using-Powershell-to-retrieve-latest-package-url-from-github-releases.html
# https://github.com/corelan/CorelanTraining/blob/master/CorelanVMInstall.ps1
# https://www.hex-rays.com/products/ida/support/download_freeware/
# https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/

[CmdletBinding()]
param (
    [Parameter()]
    [bool]$DebuggingHost = $true
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

# Setting up target
switch ($DebuggingHost)
{
    $false 
    { 
        write-Host "Enabling Kernell debugging"
        & bcdedit /debug on
    }
}

# Setting WinDbg Symbols Env Variable
[Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", "srv*c:\symbols*http://msdl.microsoft.com/download/symbols", "Machine")

# Get Latest Version from dnSpy
$url = 'https://github.com/0xd4d/dnSpy/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')
$dnSpyName = "dnSpy-net472.zip"
$dnSpyUrl = $realTagUrl.Replace('tag', 'download') + '/' + $dnSpyName

# Get Latest Version from PEBear
$url = 'https://github.com/hasherezade/pe-bear-releases/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')
$peBearName = "PE-bear_" + $version + "_x64_win.zip"
$peBearUrl = $realTagUrl.Replace('tag', 'download') + '/' + $peBearName

# Get Latest Version from FRIDA
$url = 'https://github.com/FuzzySecurity/Fermion/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')
$fermionVersion = $version -replace '\.', ''
$fermionName = "fermion-v" + $fermionVersion + "-win32-x64.zip"
$fermionUrl = $realTagUrl.Replace('tag', 'download') + '/' + $fermionName

write-host "Downloading RE Tools.."
# "IDA Freeware", "https://out7.hex-rays.com/files/idafree70_windows.exe"
$downloadAll = @"
name,url
"WinDbg","https://go.microsoft.com/fwlink/p/?linkid=2083338&clcid=0x409"
"DotPeek","https://download.jetbrains.com/resharper/ReSharperUltimate.2020.1.3/dotPeek64.2020.1.3.exe"
"API Monitor", "http://www.rohitab.com/download/api-monitor-v2r13-x86-x64.zip"
"dnSpy","$dnSpyUrl"
"PE Bear","$peBearUrl"
"Fermion","$fermionUrl"
"PowerShell Arsenal", "https://github.com/mattifestation/PowerShellArsenal/archive/master.zip"
"7z","https://www.7-zip.org/a/7z1900-x64.msi"
"Wireshark","https://2.na.dl.wireshark.org/win64/Wireshark-win64-3.2.4.exe"
"Sysinternals", "https://download.sysinternals.com/files/SysinternalsSuite.zip"
"Sysmon","https://live.sysinternals.com/Sysmon.exe"
"SilkETW", "https://github.com/fireeye/SilkETW/releases/download/v0.8/SilkETW_SilkService_v8.zip"
"@

# Initializing Web Client
$wc = new-object System.Net.WebClient

# Downloading Debugging Tools
$downloadAll | ConvertFrom-Csv | ForEach-Object {
    write-Host "Downloading " $_.name
    $OutputFile = Split-Path $_.url -leaf
    $File = "C:\ProgramData\$OutputFile"
    $wc.DownloadFile($_.url, $File)
    if (!(Test-Path $file)){ Write-Error "$File does not exist" -ErrorAction Stop }

    # Decompress if it is zip
    if ($File.ToLower().EndsWith(".zip"))
    {
        # Unzip file
        write-Host "Decompressing $OutputFile .."
        $UnpackName = (Get-Item $File).Basename
        expand-archive -path $File -DestinationPath "C:\ProgramData\$UnpackName"
        if (!(Test-Path "C:\ProgramData\$UnpackName")){ Write-Error "$File was not decompressed successfully" -ErrorAction Stop }
    }
}

# Custom Installs
write-host "Installing Windows Desktop Debuggers.."
Start-Process "C:\ProgramData\winsdksetup.exe" -Wait -ArgumentList '/features OptionId.WindowsDesktopDebuggers /ceip off /q'

write-host "Installing 7zip.."
msiexec.exe /i "C:\ProgramData\7z1900-x64.msi" /qn

write-host "Installing Wireshark.."
& "C:\ProgramData\Wireshark-win64-3.2.4.exe" /S /q /passive /norestart

# Installing Sysmon
# Downloading Sysmon Configuration
write-Host "Installing Sysmon.."
write-Host "Downloading Sysmon config.."
$SysmonFile = "C:\ProgramData\sysmon.xml"
$SysmonConfigUrl = "https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/configs/sysmon/sysmon.xml"
$wc.DownloadFile($SysmonConfigUrl, $SysmonFile)
if (!(Test-Path $SysmonFile)){ Write-Error "File $SysmonFile does not exist" -ErrorAction Stop }

write-Host "Setting up Sysmon.."
& "C:\ProgramData\Sysmon.exe" -i C:\ProgramData\sysmon.xml -accepteula

write-Host "Setting Sysmon to start automatically.."
& sc.exe config Sysmon start= auto

# Installing SilkETW
# Installing Dependencies
# .NET Framework 4.5	All Windows operating systems: 378389
$DotNetDWORD = 378388
$DotNet_Check = Get-ChildItem "hklm:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release | % { $_ -ge $DotNetDWORD }
if(!$DotNet_Check)
{
    write-Host "NET Framework 4.5 or higher not installed.."
    & C:\ProgramData\SilkETW_SilkService_v8\v8\Dependencies\dotNetFx45_Full_setup.exe /q /passive /norestart
    start-sleep -s 5
}
$MVC_Check = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "Microsoft Visual C++*"} | Select-Object DisplayName, DisplayVersion
if (!$MVC_Check)
{
    write-Host "Microsoft Visual C++ not installed.."
    & C:\ProgramData\SilkETW_SilkService_v8\v8\Dependencies\vc2015_redist.x86.exe /q /passive /norestart
    start-sleep -s 5
}

# Installing Chocolatey
write-host "Installing Chocolatey.."
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

# Installing Apps via Choco
choco install ghidra
choco install ida-free