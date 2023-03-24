# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://copdips.com/2019/12/Using-Powershell-to-retrieve-latest-package-url-from-github-releases.html
# https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
# https://stackoverflow.com/a/25127597
# https://github.com/zeronetworks/ldapfw


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

write-host "[*] Getting latest versions from LDAP Firewall GitHub project.."
$releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/zeronetworks/ldapfw/releases'
$latest = $releases[0]
$assets = $latest.assets

write-host "[+] LDAP Firewall Release Name: $($latest.name)"

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
        $LDAPFWFolder = "C:\ProgramData\$UnpackName"
        expand-archive -path $File -DestinationPath $LDAPFWFolder
        if (!(Test-Path $LDAPFWFolder)) { Write-Error "$File was not decompressed successfully" -ErrorAction Stop }
    }
}

# Installing Dependency
$MVC_Check = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.displayname -like "Microsoft Visual C++*" } | Select-Object DisplayName, DisplayVersion
if (!$MVC_Check)
{
    # Microsoft Visual C++ Redistributable latest supported downloads
    # https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170
    $msVisualDownloadUrl = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
    write-Host "[+] Downloading Microsoft Visual C++ Redistributable from" $msVisualDownloadUrl
    $request = [System.Net.WebRequest]::Create($msVisualDownloadUrl)
    $response = $request.GetResponse()
    if ($response.Server -eq 'AmazonS3'){
        $OutputFile = Split-Path $msVisualDownloadUrl -leaf
    }
    else{
        $OutputFile = [System.IO.Path]::GetFileName($response.ResponseUri)
    }
    $response.Close()
    $File = "C:\ProgramData\$OutputFile"
    # Check to see if file already exists
    if (Test-Path $File) { Write-host "  [!] $File already exist"; return }
    # Download if it does not exists
    $wc.DownloadFile($msVisualDownloadUrl, $File)
    # If for some reason, a file does not exists, STOP
    if (!(Test-Path $File)) { Write-Error "$File does not exist" -ErrorAction Stop }

    write-Host "[+] Installing Microsoft Visual C++ Redistributable.."
    & $File /q /passive /norestart
    start-sleep -s 5
}

# Installing LDAP Firewall
write-Host "[+] Installing LDAP Firewall.."
Set-Location $LDAPFWFolder
& $LDAPFWFolder\ldapFwManager.exe /status /vv
& $LDAPFWFolder\ldapFwManager.exe /install
