# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://learn.microsoft.com/en-us/power-automate/desktop-flows/install-silently
# https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options#use-the-windows-registry-windows-only
# https://learn.microsoft.com/en-us/power-automate/desktop-flows/machines-silent-registration
# https://learn.microsoft.com/en-us/power-platform/admin/manage-application-users#create-an-application-user

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

write-host "[+] Downloading Power Automate for desktop.."
$Url = "https://go.microsoft.com/fwlink/?linkid=2102613"

# Initializing Web Client
$wc = new-object System.Net.WebClient

$request = [System.Net.WebRequest]::Create($Url)
$response = $request.GetResponse()
$OutputFile = [System.IO.Path]::GetFileName($response.ResponseUri)
$response.Close()
$File = "C:\ProgramData\$OutputFile"

# Check to see if file already exists
if (Test-Path $File) { Write-host "  [!] $File already exist"; return }
# Download if it does not exists
write-host "[+] Downloading installer from $($response.ResponseUri).."
$wc.DownloadFile($Url, $File)
# If for some reason, a file does not exists, STOP
if (!(Test-Path $File)) { Write-Error "$File does not exist" -ErrorAction Stop }

write-host "[*] Installing Power Automate for Desktop.."
& $File -Silent -Install -ACCEPTEULA

# Set up MS Edge extensions registry
$RegistryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
if(!(Test-Path $RegistryKey)){
    Write-Host "[+] Creating $RegistryKey .."
    New-Item $RegistryKey -Force
}
Write-Host "[+] Setting up property to install and enable Mirosoft Power Automate extension.."
New-ItemProperty -Path $RegistryKey -Name "1" -Value "kagpabjoboikccfdghpdlaaopmgpgfdc;https://edge.microsoft.com/extensionwebstorebase/v1/crx" -PropertyType "String" -force