# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Install DSC Modules
& .\Install-DSC-Modules.ps1

# Custom Settings applied
& .\Prepare-Box.ps1

# Additional configs
& .\Disarm-Box.ps1

# Additional Firewall rules
& .\Disarm-Firewall.ps1

# Enable PSRemoting
& .\Configure-PSRemoting.ps1

# Set Windows Audit Policies
& .\Enable-WinAuditCategories.ps1

# PowerShell Logging
& .\Enable-PowerShell-Logging.ps1

# Set Audit Rules from Set-AuditRule project
& .\Set-SACLs.ps1

# Set Wallpaper
& .\Set-WallPaper.ps1