# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet("DC","ADFS")]
    [string]$SetupType,

    [Parameter(Mandatory)]
    [ValidateSet('TrustedSigned','SelfSigned')]
    [string]$CertificateType,

    [Parameter(Mandatory=$false)]
    [string]$PfxCertName
)

# Install DSC Modules
& .\Install-DSC-Modules.ps1 -SetupType $SetupType

if ($CertificateType -eq 'TrustedSigned')
{
    # Move trusted CA signed SSL certificate
    Move-Item $PfxCertName C:\ProgramData\
}

# Custom Settings applied
& .\Prepare-Box.ps1

# Additional configs
& .\Disarm-Box.ps1

# Additional Firewall rules
& .\Disarm-Firewall.ps1

# Enable PSRemoting
& .\Configure-PSRemoting.ps1

# Windows Security Audit Categories
if ($SetupType -eq 'DC')
{
    & .\Enable-WinAuditCategories.ps1 -SetDC
}
else
{
    & .\Enable-WinAuditCategories.ps1
}

# PowerShell Logging
& .\Enable-PowerShell-Logging.ps1

# Set SACLs
& .\Set-SACLs.ps1

# Set Wallpaper
& .\Set-WallPaper.ps1

# Add custom domain to intranet
<#
$IntranetDomainSite = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\blacksmith.local'
if (-not (Test-Path -Path $IntranetDomainSite))
{
    $null = New-Item -Path $IntranetDomainSite -Force
}

Set-ItemProperty -Path $IntranetDomainSite -Name http -Value 1 -Type DWord
Set-ItemProperty -Path $IntranetDomainSite -Name https -Value 1 -Type DWord
#>