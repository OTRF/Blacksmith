# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://copdips.com/2019/12/Using-Powershell-to-retrieve-latest-package-url-from-github-releases.html
# https://stackoverflow.com/a/25127597
# https://github.com/jsecurity101/JonMon/wiki#installation

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

write-host "[+] Getting latest versions from JonMon GitHub project..."
$releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/jsecurity101/JonMon/releases'
$latest = $releases[0]
$assets = $latest.assets

write-host "[+] JonMon Release Name: $($latest.name)"

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
        $JonMonFolder = "C:\ProgramData\$UnpackName"
        expand-archive -path $File -DestinationPath $JonMonFolder
        if (!(Test-Path $JonMonFolder)) { Write-Error "$File was not decompressed successfully" -ErrorAction Stop }
    }
}

# Installing JonMon
$JonMonLocation = Join-Path $JonMonFolder "JonMon"

write-Host "[+] Setting location to $JonMonLocation..."
Set-Location $JonMonLocation

write-Host "[+] Installing JonMon..."
& $JonMonLocation\JonMon-Service.exe -i