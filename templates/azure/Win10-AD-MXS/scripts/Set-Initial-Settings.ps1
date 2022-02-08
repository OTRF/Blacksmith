# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet("DC","MXS")]
    [string]$SetupType
)

# Install DSC Modules
& .\Install-DSC-Modules.ps1 -SetupType $SetupType

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