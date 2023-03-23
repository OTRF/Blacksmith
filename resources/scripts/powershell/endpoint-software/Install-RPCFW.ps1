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

write-host "[*] Getting latest versions from RPC Firewall GitHub project.."
$releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/zeronetworks/rpcfirewall/releases'
$latest = $releases[0]
$assets = $latest.assets

write-host "[+]RPC Firewall Release Name: $($latest.name)"

# Initializing Web Client
$wc = new-object System.Net.WebClient

# Downloading Assets
foreach ($asset in $assets){
    $downloadUrl = $asset.browser_download_url
    write-Host "[+] Downloading" $asset.name "From" $downloadUrl
    $OutputFile = Split-Path $downloadUrl -Leaf
    $File = "C:\ProgramData\$OutputFile"
    # Check to see if file already exists
    if (Test-Path $File) { Write-host "  [!] $File already exist"; return }
    # Download if it does not exists
    $wc.DownloadFile($downloadUrl, $File)
    # If for some reason, a file does not exists, STOP
    if (!(Test-Path $File)) { Write-Error "$File does not exist" -ErrorAction Stop }
    # Decompress if it is zip file
    if ($File.ToLower().EndsWith(".zip"))
    {
        # Unzip file
        write-Host "  [+] Decompressing $OutputFile .."
        $UnpackName = (Get-Item $File).Basename
        $RPCFWFolder = "C:\ProgramData\$UnpackName"
        expand-archive -path $File -DestinationPath $RPCFWFolder
        if (!(Test-Path $RPCFWFolder)) { Write-Error "$File was not decompressed successfully" -ErrorAction Stop }
    }
}

# Rename RPC Firewall Config file
Rename-Item -Path $RPCFWFolder\RpcFw.conf -NewName $RPCFWFolder\RpcFw.Backup

# Downloading RPC Firewall config file
write-Host "[+] Downloading Rpc FW config file from" $RPCFWConfigUrl
$request = [System.Net.WebRequest]::Create($RPCFWConfigUrl)
$response = $request.GetResponse()
$OutputFile = [System.IO.Path]::GetFileName($response.ResponseUri)
$response.Close()
$File = "$RPCFWFolder\$OutputFile"
# Check to see if file already exists
if (Test-Path $File) { Write-host "  [!] $File already exist"; return }
# Download if it does not exists
$wc.DownloadFile($RPCFWConfigUrl, $File)
# If for some reason, a file does not exists, STOP
if (!(Test-Path $File)) { Write-Error "$File does not exist" -ErrorAction Stop }

# Installing RPC Firewall
write-Host "[+] Installing RPC Firewall.."
Set-Location $RPCFWFolder
& $RPCFWFolder\rpcFwManager.exe /install
# Protecting lsass as prt of the POC
& $RPCFWFolder\rpcFwManager.exe /start process lsass