# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Set up PSRemoting
# https://docs.microsoft.com/windows/win32/winrm/installation-and-configuration-for-windows-remote-management.
$ServiceName = 'WinRM'
$arrService = Get-Service -Name $ServiceName

if ($arrService.Status -eq 'Running')
{
    Write-Host "$ServiceName Service is now Running"
}
else
{
    Write-host 'Enabling WinRM..'
    winrm quickconfig -q
    <#The winrm quickconfig command (or the abbreviated version winrm qc) performs these operations.
    - Starts the WinRM service, and sets the service startup type to auto-start.
    - Configures a listener for the ports that send and receive WS-Management protocol messages using either HTTP or HTTPS on any IP address.
    - Defines ICF exceptions for the WinRM service, and opens the ports for HTTP and HTTPS.#>
}
# Enable PowerShell remoting.
Enable-PSRemoting -Force
# Create firewall rule for WinRM. The default HTTPS port is 5986.
New-NetFirewallRule -Name "WinRM HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Profile "Any" -Action "Allow" -Direction "Inbound" -LocalPort 5986 -Protocol "TCP"
# Create new self-signed-certificate to be used by WinRM.
$Thumbprint = (New-SelfSignedCertificate -DnsName $env:COMPUTERNAME  -CertStoreLocation Cert:\LocalMachine\My).Thumbprint
# Create WinRM HTTPS listener.
$Cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=""$env:COMPUTERNAME ""; CertificateThumbprint=""$Thumbprint""}"
& cmd.exe /C $Cmd