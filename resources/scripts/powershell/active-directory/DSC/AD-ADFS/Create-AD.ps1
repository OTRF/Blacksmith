# References:
# https://github.com/Azure/azure-quickstart-templates/blob/master/sharepoint-adfs/dsc/ConfigureDCVM.ps1
configuration Create-AD {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdfsSvcCreds,

        [Parameter(Mandatory)]
        [String]$AdfsIPAddress
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xPSDesiredStateConfiguration, ActiveDirectoryCSDsc, CertificateDsc, xDnsServer, ComputerManagementDsc
    
    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    $ComputerName = Get-Content env:computername
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminCreds.Password)
    $AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $ADFSSiteName = "ADFS"

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** Add DNS and AD Features *****
        WindowsFeature DNS 
        { 
            Ensure  = "Present" 
            Name    = "DNS"		
        }

        Script EnableDNSDiags
        {
            SetScript = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript   = { @{} }
            TestScript  = { $false }
            DependsOn   = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure      = "Present"
            Name        = "RSAT-DNS-Server"
            DependsOn   = "[WindowsFeature]DNS"
        }

        DnsServerAddress SetDNS 
        { 
            Address         = '127.0.0.1' 
            InterfaceAlias  = $InterfaceAlias
            AddressFamily   = 'IPv4'
            DependsOn       = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure      = "Present" 
            Name        = "AD-Domain-Services"
            DependsOn   = "[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure      = "Present"
            Name        = "RSAT-ADDS-Tools"
            DependsOn   = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure      = "Present"
            Name        = "RSAT-AD-AdminCenter"
            DependsOn   = "[WindowsFeature]ADDSInstall"
        }
         
        # ****** Create AD Domain *********
        ADDomain CreateADForest 
        {
            DomainName                      = $DomainFQDN
            Credential                      = $DomainCreds
            SafemodeAdministratorPassword   = $DomainCreds
            DatabasePath                    = "C:\NTDS"
            LogPath                         = "C:\NTDS"
            SysvolPath                      = "C:\SYSVOL"
            DependsOn                       = "[DnsServerAddress]SetDNS", "[WindowsFeature]ADDSInstall"
        }

        PendingReboot RebootOnSignalFromCreateADForest
        {
            Name        = 'RebootOnSignalFromCreateADForest'
            DependsOn   = "[ADDomain]CreateADForest"
        }

        WaitForADDomain WaitForDCReady
        {
            DomainName              = $DomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $DomainCreds
            WaitForValidCredentials = $true
            DependsOn               = "[PendingReboot]RebootOnSignalFromCreateADForest"
        }

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
            Name        = "Setup"
            Path        = "C:\Setup"
            FullAccess  = @("Domain Admins", "Domain Computers")
            ReadAccess  = "Authenticated Users"
            DependsOn   = "[File]SrcFolder"
        }

        # ******* Configure AD CS **********
        WindowsFeature AddADCSFeature
        { 
            Name        = "ADCS-Cert-Authority"
            Ensure      = "Present"
            DependsOn   = "[WaitForADDomain]WaitForDCReady"
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
            Subject                   = "$ADFSSiteName.$DomainFQDN"
            FriendlyName              = "$ADFSSiteName.$DomainFQDN site certificate"
            KeyLength                 = '2048'
            Exportable                = $true
            ProviderName              = '"Microsoft RSA SChannel Cryptographic Provider"'
            OID                       = '1.3.6.1.5.5.7.3.1'
            KeyUsage                  = '0xa0'
            CertificateTemplate       = 'WebServer'
            AutoRenew                 = $true
            SubjectAltName            = "dns=certauth.$ADFSSiteName.$DomainFQDN&dns=$ADFSSiteName.$DomainFQDN&dns=enterpriseregistration.$DomainFQDN"
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
            DependsOn = "[CertReq]GenerateADFSSiteCertificate", "[CertReq]GenerateADFSSigningCertificate", "[CertReq]GenerateADFSDecryptionCertificate"
        }

        # ***** Create ADFS SvcUser *****
        ADUser CreateAdfsSvcAccount
        {
            DomainName              = $DomainFQDN
            UserName                = $AdfsSvcCreds.UserName
            Password                = $AdfsSvcCreds
            PasswordAuthentication  = 'Negotiate'
            PasswordNeverExpires    = $true
            Ensure                  = "Present"
            DependsOn               = "[CertReq]GenerateADFSSiteCertificate", "[CertReq]GenerateADFSSigningCertificate", "[CertReq]GenerateADFSDecryptionCertificate"
        }

        xDnsRecord AddADFSHostDNS {
            Name        = $ADFSSiteName
            Zone        = $DomainFQDN
            Target      = $AdfsIPAddress
            Type        = "ARecord"
            Ensure      = "Present"
            DependsOn   = "[WaitForADDomain]WaitForDCReady"
        }

        # ***** Export PFX Certificate Format *****
        xScript ExportPFX
        {
            SetScript = 
            {
                $destinationPath = "C:\Setup"
                $adfsPfxCertName = "ADFS.pfx"
                $cert = Get-ChildItem -Path "cert:\LocalMachine\My\" -DnsName "$using:ADFSSiteName.$using:DomainFQDN"
                Export-PfxCertificate -FilePath ([System.IO.Path]::Combine($destinationPath, $adfsPfxCertName)) -Cert $cert -Password (ConvertTo-SecureString "$using:AdminPassword" -AsPlainText -Force)
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
            DependsOn = "[xScript]ExportCertificates", "[ADUser]CreateAdfsSvcAccount"
        }

        # ***** Install AD Connect *****
        xScript InstallAADConnect
        {
            # reference: https://github.com/pthoor/AzureARMTemplates/blob/ddd09734a3817e459d3dbfb41fc96c9b011e0205/ADFS%20Lab/DSC/adDSC/adDSCConfiguration.ps1
            SetScript = {
                Resolve-DnsName download.microsoft.com
                $AADConnectDLUrl="https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
                $exe="$env:SystemRoot\system32\msiexec.exe"

                $tempfile = [System.IO.Path]::GetTempFileName()
                $folder = [System.IO.Path]::GetDirectoryName($tempfile)

                $webclient = New-Object System.Net.WebClient
                $webclient.DownloadFile($AADConnectDLUrl, $tempfile)

                Rename-Item -Path $tempfile -NewName "AzureADConnect.msi"
                $MSIPath = $folder + "\AzureADConnect.msi"

                Invoke-Expression "& `"$exe`" /i $MSIPath /qn /passive /forcerestart"
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
            DependsOn = "[xScript]ExportPFX"
        }

        WaitForADDomain WaitForDCReady
        {
            DomainName              = $DomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $DomainCreds
            WaitForValidCredentials = $true
            DependsOn               = "[xScript]InstallAADConnect"
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