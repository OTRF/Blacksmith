# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download BgInfo
(New-Object Net.WebClient).DownloadFile('http://live.sysinternals.com/bginfo.exe', 'C:\ProgramData\bginfo.exe')

# Copy Wallpaper
(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/resources/configs/bginfo/otr.jpg', 'C:\ProgramData\otr.jpg')

# Copy BGInfo config
(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/resources/configs/bginfo/OTRWallPaper.bgi', 'C:\ProgramData\OTRWallPaper.bgi')

# Set Run Key
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "BgInfo" -Value "C:\ProgramData\bginfo.exe C:\ProgramData\OTRWallPaper.bgi /silent /timer:0 /nolicprompt" -PropertyType "String" -force

& C:\ProgramData\bginfo.exe C:\ProgramData\OTRWallPaper.bgi /silent /timer:0 /nolicprompt

