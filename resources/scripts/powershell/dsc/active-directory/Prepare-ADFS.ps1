# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
# References:
# https://github.com/Azure/azure-quickstart-templates/blob/master/sharepoint-adfs/dsc/ConfigureDCVM.ps1
configuration Prepare-ADFS {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [String]$FederationServiceName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdfsAdminCreds,

        [Parameter(Mandatory)]
        [String]$AdfsIPAddress,

        [Parameter(Mandatory)]
        [String]$PfxCertName,

        [Parameter(Mandatory)]
        [ValidateSet('TrustedSigned','SelfSigned')]
        [string]$CertificateType,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$PfxCertCreds,

        [Parameter()]
        [String]$SmbSharedFolder
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc, xPSDesiredStateConfiguration, xDnsServer, ComputerManagementDsc, ActiveDirectoryCSDsc, CertificateDsc
    
    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $ADFSSiteName = $FederationServiceName.split(".")[0]
    $ComputerName = Get-Content env:computername

    Node localhost
    {
        # ***** Create ADFS SvcUser *****
        ADUser CreateAdfsSvcAccount
        {
            DomainName              = $DomainFQDN
            UserName                = $AdfsAdminCreds.UserName
            Password                = $AdfsAdminCreds
            PasswordAuthentication  = 'Negotiate'
            PasswordNeverExpires    = $true
            Ensure                  = "Present"
        }

        xDnsRecord AddADFSHostDNS {
            Name        = $ADFSSiteName
            Zone        = $DomainFQDN
            Target      = $AdfsIPAddress
            Type        = "ARecord"
            Ensure      = "Present"
        }

        if ($CertificateType -eq 'SelfSigned') {
            # ******* Configure SMB Share **********
            File SrcFolder
            {
                DestinationPath = "C:\Setup"
                Type            = "Directory"
                Ensure          = "Present"
            }

            SmbShare SrcShare
            {
                Ensure      = "Present"
                Name        = $SmbSharedFolder
                Path        = "C:\$SmbSharedFolder"
                FullAccess  = @("Domain Admins", "Domain Computers")
                ReadAccess  = "Authenticated Users"
                DependsOn   = "[File]SrcFolder"
            }

            # ******* Configure AD CS **********
            WindowsFeature AddADCSFeature
            { 
                Name        = "ADCS-Cert-Authority"
                Ensure      = "Present"
            }

            ADCSCertificationAuthority CreateADCSAuthority
            {
                IsSingleInstance = "Yes"
                CAType           = "EnterpriseRootCA"
                Ensure           = "Present"
                Credential       = $DomainCreds
                DependsOn        = "[WindowsFeature]AddADCSFeature"
            }

            WaitForCertificateServices WaitAfterADCSProvisioning
            {
                CAServerFQDN         = "$ComputerName.$DomainFQDN"
                CARootName           = "$DomainNetbiosName-$ComputerName-CA"
                DependsOn            = '[ADCSCertificationAuthority]CreateADCSAuthority'
                PsDscRunAsCredential = $DomainCreds
            }

            # ***** Create ADFS Certificate *****
            CertReq GenerateADFSSiteCertificate
            {
                CARootName                = "$DomainNetbiosName-$ComputerName-CA"
                CAServerFQDN              = "$ComputerName.$DomainFQDN"
                Subject                   = "$FederationServiceName"
                FriendlyName              = "$FederationServiceName site certificate"
                KeyLength                 = '2048'
                Exportable                = $true
                ProviderName              = '"Microsoft RSA SChannel Cryptographic Provider"'
                OID                       = '1.3.6.1.5.5.7.3.1'
                KeyUsage                  = '0xa0'
                CertificateTemplate       = 'WebServer'
                AutoRenew                 = $true
                SubjectAltName            = "dns=certauth.$FederationServiceName&dns=$FederationServiceName&dns=enterpriseregistration.$DomainFQDN"
                Credential                = $DomainCreds
                DependsOn                 = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
            }

            CertReq GenerateADFSSigningCertificate
            {
                CARootName                = "$DomainNetbiosName-$ComputerName-CA"
                CAServerFQDN              = "$ComputerName.$DomainFQDN"
                Subject                   = "$ADFSSiteName.Signing"
                FriendlyName              = "$ADFSSiteName Signing"
                KeyLength                 = '2048'
                Exportable                = $true
                ProviderName              = '"Microsoft RSA SChannel Cryptographic Provider"'
                OID                       = '1.3.6.1.5.5.7.3.1'
                KeyUsage                  = '0xa0'
                CertificateTemplate       = 'WebServer'
                AutoRenew                 = $true
                Credential                = $DomainCreds
                DependsOn                 = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
            }

            CertReq GenerateADFSDecryptionCertificate
            {
                CARootName                = "$DomainNetbiosName-$ComputerName-CA"
                CAServerFQDN              = "$ComputerName.$DomainFQDN"
                Subject                   = "$ADFSSiteName.Decryption"
                FriendlyName              = "$ADFSSiteName Decryption"
                KeyLength                 = '2048'
                Exportable                = $true
                ProviderName              = '"Microsoft RSA SChannel Cryptographic Provider"'
                OID                       = '1.3.6.1.5.5.7.3.1'
                KeyUsage                  = '0xa0'
                CertificateTemplate       = 'WebServer'
                AutoRenew                 = $true
                Credential                = $DomainCreds
                DependsOn                 = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
            }

            # ***** Export ADFS Certificates (.cer) *****
            xScript ExportCertificates
            {
                SetScript = 
                {
                    $destinationPath = "C:\Setup"
                    $adfsSigningCertName = "ADFS Signing.cer"
                    $adfsSigningIssuerCertName = "ADFS Signing issuer.cer"
                    Write-Verbose -Message "Exporting public key of ADFS signing / signing issuer certificates..."
                    New-Item $destinationPath -Type directory -ErrorAction SilentlyContinue
                    $signingCert = Get-ChildItem -Path "cert:\LocalMachine\My\" -DnsName "$using:ADFSSiteName.Signing"
                    $signingCert | Export-Certificate -FilePath ([System.IO.Path]::Combine($destinationPath, $adfsSigningCertName))
                    Get-ChildItem -Path "cert:\LocalMachine\Root\" | Where-Object { $_.Subject -eq $signingCert.Issuer } | Select-Object -First 1 | Export-Certificate -FilePath ([System.IO.Path]::Combine($destinationPath, $adfsSigningIssuerCertName))
                    Write-Verbose -Message "Public key of ADFS signing / signing issuer certificates successfully exported"
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
                DependsOn = "[CertReq]GenerateADFSSiteCertificate", "[CertReq]GenerateADFSSigningCertificate", "[CertReq]GenerateADFSDecryptionCertificate", "[SmbShare]SrcShare"
            }

            # ***** Export PFX Certificate Format *****
            xScript ExportPFX
            {
                SetScript = 
                {
                    $destinationPath = "C:\$using:SmbSharedFolder"
                    $adfsPfxCertName = "$using:PfxCertName"
                    $cert = Get-ChildItem -Path "cert:\LocalMachine\My\" -DnsName "$using:FederationServiceName"
                    Export-PfxCertificate -FilePath ([System.IO.Path]::Combine($destinationPath, $adfsPfxCertName)) -Cert $cert -Password $using:PfxCertCreds.Password
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
                DependsOn = "[xScript]ExportCertificates", "[SmbShare]SrcShare"
            }
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