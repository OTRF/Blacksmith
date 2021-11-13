# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://copdips.com/2019/12/Using-Powershell-to-retrieve-latest-package-url-from-github-releases.html
# https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
# https://stackoverflow.com/a/25127597
# https://github.com/zeronetworks/rpcfirewall

[CmdletBinding()]
param (
    [string]$RPCFWConfigUrl = "https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/configs/rpcfirewall/RpcFw.conf"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

write-host "[*] Getting latest versions from RPC Firewall GitHub projects.."
# Get Latest Version of rpcfirewall
$url = 'https://github.com/zeronetworks/rpcfirewall/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')
$rpcFwFiles = @("rpcFireWall.dll", "rpcFwManager.exe", "rpcMessages.dll")
$rpcReleaseDownloadUrl = $realTagUrl.Replace('tag', 'download') + '/'
$response.Close()
write-host "[+] RPC Firewall version: $version"

# Initializing Web Client
$wc = new-object System.Net.WebClient

# Downloading RPC Firewall service files
$rpcFwFiles | ForEach-Object {
    $downloadUrl = $rpcReleaseDownloadUrl + $_ 
    write-Host "[+] Downloading" $_ "From" $downloadUrl
    $request = [System.Net.WebRequest]::Create($downloadUrl)
    $response = $request.GetResponse()
    if ($response.Server -eq 'AmazonS3')
    {
        $OutputFile = Split-Path $downloadUrl -Leaf
    }
    else
    {
        $OutputFile = [System.IO.Path]::GetFileName($response.ResponseUri)
    }
    $response.Close()
    $File = "C:\ProgramData\$OutputFile"
    # Check to see if file already exists
    if (Test-Path $File) { Write-host "  [!] $File already exist"; return }
    # Download if it does not exists
    $wc.DownloadFile($downloadUrl, $File)
    # If for some reason, a file does not exists, STOP
    if (!(Test-Path $File)) { Write-Error "$File does not exist" -ErrorAction Stop }
}

# Downloading RPC Firewall config file
write-Host "[+] Downloading Rpc FW config file from" $RPCFWConfigUrl
$request = [System.Net.WebRequest]::Create($RPCFWConfigUrl)
$response = $request.GetResponse()
$OutputFile = [System.IO.Path]::GetFileName($response.ResponseUri)
$response.Close()
$File = "C:\ProgramData\$OutputFile"
# Check to see if file already exists
if (Test-Path $File) { Write-host "  [!] $File already exist"; return }
# Download if it does not exists
$wc.DownloadFile($RPCFWConfigUrl, $File)
# If for some reason, a file does not exists, STOP
if (!(Test-Path $File)) { Write-Error "$File does not exist" -ErrorAction Stop }

# Installing RPC Firewall
write-Host "[+] Installing RPC Firewall.."
Set-Location C:\ProgramData
& "C:\ProgramData\RpcFwManager.exe" /install
# Protecting lsass as prt of the POC
& "C:\ProgramData\RpcFwManager.exe" /process lsass