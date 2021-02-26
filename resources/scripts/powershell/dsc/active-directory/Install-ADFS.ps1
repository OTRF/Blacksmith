# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
configuration Install-ADFS 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdfsAdminCreds,

        [Parameter(Mandatory)]
        [ValidateSet('TrustedSigned','SelfSigned')]
        [string]$CertificateType,

        [Parameter(Mandatory)]
        [String]$CertificateName,
        
        [Parameter(Mandatory)]
        [String]$DCName
    ) 
    
    Import-DscResource -ModuleName ComputerManagementDsc, xPSDesiredStateConfiguration

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    # Domain Admin Creds
    [System.Management.Automation.PSCredential]$DomainAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Adminbstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DomainAdminCreds.Password)
    $AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($Adminbstr)
    # Domain ADFS Admin Creds
    [System.Management.Automation.PSCredential]$DomainAdfsAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdfsAdminCreds.UserName)", $AdfsAdminCreds.Password)

    $ADFSSiteName = "ADFS"

    Node localhost
    {
        LocalConfigurationManager 
        {
            ActionAfterReboot   = 'ContinueConfiguration'
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

	    WindowsFeature installADFS
        {
            Ensure = "Present"
            Name   = "ADFS-Federation"
        }

        if ($CertificateType -eq 'TrustedSigned')
        {
            xScript ImportPFX
            {
                SetScript = 
                {
                    # ***** Import .PFX File *****
                    Import-PfxCertificate -Exportable -CertStoreLocation "cert:\LocalMachine\My" -FilePath "C:\ProgramData\$using:CertificateName" -Password (ConvertTo-SecureString "$using:AdminPassword" -AsPlainText -Force)
                }
                GetScript =  
                {
                    # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                    return @{ "Result" = "false" }
                }
                TestScript = 
                {
                    # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                    return $false
                }
                DependsOn = "[WindowsFeature]installADFS"
            }
        }
        elseif ($CertificateType -eq 'SelfSigned')
        {
            xScript ImportPFX
            {
                SetScript = 
                {
                    $pathtocert = "\\$using:DCName\Setup\$using:CertificateName"
                    $certfile = Get-ChildItem -Path $pathtocert
                    Import-PfxCertificate -Exportable -CertStoreLocation "cert:\LocalMachine\My" -FilePath $certfile.FullName -Password (ConvertTo-SecureString "$using:AdminPassword" -AsPlainText -Force)
                }
                GetScript =  
                {
                    # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                    return @{ "Result" = "false" }
                }
                TestScript = 
                {
                    # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                    return $false
                }
                DependsOn = "[WindowsFeature]installADFS"
            }
        }

        # ***** Create ADFS Farm *****
        xScript CreateADFSFarm
        {
            SetScript = {
                $cert = Get-ChildItem -Path "cert:\LocalMachine\My\" -DnsName "$using:ADFSSiteName.$using:DomainFQDN"

                Import-Module ADFS
                Install-AdfsFarm -CertificateThumbprint $cert.Thumbprint -FederationServiceName "$using:ADFSSiteName.$using:DomainFQDN" -FederationServiceDisplayName "Active Directory Federation Service" -ServiceAccountCredential $using:DomainAdfsAdminCreds -OverwriteConfiguration -Credential $using:DomainAdminCreds
            }

            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn = "[xScript]ImportPFX"
        }

        # ***** Configure ADFS *****
        xScript ConfigureADFS
        {
            SetScript = {
                # ***** Idp-Initiated Sign On page (Disabled by default)*****
                set-AdfsProperties -EnableIdPInitiatedSignonPage $true

                # ***** Customize Landing Page *****
                Set-AdfsGlobalWebContent -CompanyName "Open Threat Research"
                Set-AdfsWebTheme -TargetName default -Illustration @{path="C:\ProgramData\otr.jpg"}
                Set-AdfsGlobalWebContent -SignInPageDescriptionText "<p>Sign-in to the Open Threat Research Community and collaborate!</p>"

                # ***** Enabling ADFS Verbose Auditing *****
                <#
                Get-AdfsProperties | Select Auditlevel

                AuditLevel
                ----------
                {Basic}
                #>
                Set-AdfsProperties -Auditlevel verbose
                Restart-Service -Name adfssrv

                & auditpol.exe /set /subcategory:"Application Generated" /failure:enable /success:enable

                # ***** Enable AD FS Logging *****
                <#
                PS C:\Users\wardog.ADFS01> (Get-AdfsProperties).Loglevel
                Errors
                FailureAudits
                Information
                Verbose
                SuccessAudits
                Warnings
                #>
                Set-AdfsProperties -LogLevel ((Get-AdfsProperties).LogLevel+'SuccessAudits','FailureAudits')

                #***** READY *****
                # Browse to: https://adfs.blacksmith.local/adfs/ls/idpinitiatedsignon.aspx
            }

            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn = "[xScript]CreateADFSFarm"
        }

        # ***** Download AADConnect *****
        xRemoteFile DownloadAADConnect {
            DestinationPath = "C:\ProgramData\AzureADConnect.msi"
            Uri = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
            DependsOn = "[xScript]CreateADFSFarm"
        }

        # ***** Install AADConnect *****
        xScript InstallAADConnect
        {
            # reference: https://github.com/pthoor/AzureARMTemplates/blob/ddd09734a3817e459d3dbfb41fc96c9b011e0205/ADFS%20Lab/DSC/adDSC/adDSCConfiguration.ps1
            SetScript = {
                $exe="$env:SystemRoot\system32\msiexec.exe"
                $MSIPath = "C:\ProgramData\AzureADConnect.msi"

                Invoke-Expression "& `"$exe`" /i $MSIPath /qn /passive /norestart"
            }
            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn = "[xRemoteFile]DownloadAADConnect"
        }
    }
}

function Get-NetBIOSName {
    [OutputType([string])]
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length = $DomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length = 15
        }
        return $DomainFQDN.Substring(0, $length)
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0, 15)
        }
        else {
            return $DomainFQDN
        }
    }
}