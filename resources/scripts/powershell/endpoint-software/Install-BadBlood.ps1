# Author: Roberto Rodriguez (@Cyb3rWard0g)

# Install Active Directory Module for Windows PowerShell
Write-Host "Installing Active Directory module for Windows PowerShell"

Import-Module ServerManager
Add-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

# Installing Chocolatey
write-host "Installing Chocolatey.."

Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

write-host "Installing choco packages.."
choco install git

[string]$PathToGit = "C:\Program Files\Git\bin\git.exe"
[Array]$Arguments = "clone", "https://github.com/davidprowe/badblood.git", "C:\ProgramData\badblood"
& $PathToGit $Arguments