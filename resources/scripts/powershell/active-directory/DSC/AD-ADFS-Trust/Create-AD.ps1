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
        [String]$AdfsIPAddress,

        [Parameter(Mandatory)]
        [String]$CertificateName
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xPSDesiredStateConfiguration, xDnsServer, ComputerManagementDsc
    
    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
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

        # ***** Create ADFS SvcUser *****
        ADUser CreateAdfsSvcAccount
        {
            DomainName              = $DomainFQDN
            UserName                = $AdfsSvcCreds.UserName
            Password                = $AdfsSvcCreds
            PasswordAuthentication  = 'Negotiate'
            PasswordNeverExpires    = $true
            Ensure                  = "Present"
            DependsOn               = "[WaitForADDomain]WaitForDCReady"
        }

        xDnsRecord AddADFSHostDNS {
            Name        = $ADFSSiteName
            Zone        = $DomainFQDN
            Target      = $AdfsIPAddress
            Type        = "ARecord"
            Ensure      = "Present"
            DependsOn   = "[WaitForADDomain]WaitForDCReady"
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
            DependsOn = "[WaitForADDomain]WaitForDCReady"
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
            DependsOn = "[xScript]ImportPFX"
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