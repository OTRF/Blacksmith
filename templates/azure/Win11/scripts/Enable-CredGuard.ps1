<#
.SYNOPSIS
    Enable virtualization and enable Credential Guard in Windows 10 / Windows 11
.DESCRIPTION
    Virtualization will be enabled in the process of enabling CredentialGuard.
    Also appends actions to logfile: EnableCredentialGuard.log
    Enforcement of required reboot
 
.NOTES
    FileName:    Enable-CredGuard.ps1
    Author:      Martin Bengtsson
    Created:     19-07-2017
    Modified:    12-08-2022
    By:          notonlybytes
#>

$Logfile = "C:\Windows\EnableCredentialGuard.log"

#Create LogWrite function
Function LogWrite
{
   Param ([string]$Logstring)

   Add-Content $Logfile -Value $Logstring
}

#Add required registry key for Credential Guard
$RegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
If (-not(Test-Path -Path $RegistryKeyPath)) {
    Write-Host -ForegroundColor Yellow "Creating HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard registry key" ; LogWrite "Creating HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard registry key"
    New-Item -Path $RegistryKeyPath -ItemType Directory -Force
}
#Add registry key: RequirePlatformSecurityFeatures - 1 for Secure Boot only, 3 for Secure Boot and DMA Protection
New-ItemProperty -Path $RegistryKeyPath -Name RequirePlatformSecurityFeatures -PropertyType DWORD -Value 1
Write-Host -ForegroundColor Yellow "Successfully added RequirePlatformSecurityFeatures regkey" ; LogWrite "Successfully added RequirePlatformSecurityFeatures regkey"

#Add registry key: EnableVirtualizationBasedSecurity - 1 for Enabled, 0 for Disabled
New-ItemProperty -Path $RegistryKeyPath -Name EnableVirtualizationBasedSecurity -PropertyType DWORD -Value 1
Write-Host -ForegroundColor Yellow "Successfully added EnableVirtualizationBasedSecurity regkey" ; LogWrite "Successfully added EnableVirtualizationBasedSecurity regkey"

#Add registry key: LsaCfgFlags - 1 enables Credential Guard with UEFI lock, 2 enables Credential Guard without lock, 0 for Disabled
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name LsaCfgFlags -PropertyType DWORD -Value 2
Write-Host -ForegroundColor Yellow "Successfully added LsaCfgFlags regkey" ; LogWrite "Successfully added LsaCfgFlags regkey"

Write-Host -ForegroundColor Yellow "Successfully enabled Credential Guard - automatic reboot will take place" ; LogWrite "Successfully enabled Credential Guard - automatic reboot will take place"

# Reboot system to enable VBS & Credential Guard
Start-Sleep -Seconds 5
Restart-Computer -Force
