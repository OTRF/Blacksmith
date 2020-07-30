# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Custom Settings applied
& .\Prepare-Box.ps1

# Set Windows Audit Policies
& .\Enable-WinAuditCategories.ps1

# Set Audit Rules from Set-AuditRule project
& .\Set-SACLs.ps1

# Set Wallpaper
& .\Set-WallPaper.ps1