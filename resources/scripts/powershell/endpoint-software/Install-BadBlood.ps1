# Author: Roberto Rodriguez (@Cyb3rWard0g)

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