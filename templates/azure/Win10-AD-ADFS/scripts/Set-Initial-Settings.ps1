# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ServerAddresses,

    [Parameter(Mandatory=$false)]
    [switch]$SetDC,

    [Parameter(Mandatory=$false)]
    [switch]$SetADFS
)

# Install DSC Modules
if ($SetDC){
    & .\Install-AD-DSC-Modules.ps1
}

if ($SetADFS){
    & .\Install-ADFS-DSC-Modules.ps1
}

# Custom Settings applied
& .\Prepare-Box.ps1

# Windows Security Audit Categories
if ($SetDC){
    & .\Enable-WinAuditCategories.ps1 -SetDC
}
else{
    & .\Enable-WinAuditCategories.ps1
}

# PowerShell Logging
& .\Enable-PowerShell-Logging.ps1

# Set SACLs
& .\Set-SACLs.ps1

# Set Wallpaper
& .\Set-WallPaper.ps1

# Setting static IP and DNS server IP
if ($ServerAddresses)
{
    & .\Set-StaticIP.ps1 -ServerAddresses $ServerAddresses
}