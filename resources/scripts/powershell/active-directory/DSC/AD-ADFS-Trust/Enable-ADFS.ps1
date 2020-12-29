configuration Enable-ADFS 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [String]$DCIPAddress,

        [Parameter(Mandatory)]
        [ValidateSet('TrustedSigned','SelfSigned')]
        [string]$CertificateType,

        [Parameter(Mandatory)]
        [String]$CertificateName,

        [Parameter(Mandatory)]
        [String]$JoinOU
    ) 
    
    Import-DscResource -ModuleName NetworkingDsc, ActiveDirectoryDsc, ComputerManagementDsc, xPSDesiredStateConfiguration

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminCreds.Password)
    $AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    $ComputerName = Get-Content env:computername

    Node localhost
    {
        LocalConfigurationManager 
        {
            ActionAfterReboot   = 'ContinueConfiguration'
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        DnsServerAddress SetDNS 
        { 
            Address         = $DCIPAddress
            InterfaceAlias  = $InterfaceAlias
            AddressFamily   = 'IPv4'
        }

        # ***** Join Domain *****
        WaitForADDomain WaitForDCReady
        {
            DomainName              = $DomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $DomainCreds
            WaitForValidCredentials = $true
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        Computer JoinDomain
        {
            Name          = $ComputerName 
            DomainName    = $DomainFQDN
            Credential    = $DomainCreds
            JoinOU        = $JoinOU
            DependsOn = "[WaitForADDomain]WaitForDCReady"
        }

        PendingReboot RebootAfterJoiningDomain
        { 
            Name = "RebootServer"
            DependsOn = "[Computer]JoinDomain"
        }

	    WindowsFeature installADFS
        {
            Ensure = "Present"
            Name   = "ADFS-Federation"
            DependsOn = "[PendingReboot]RebootAfterJoiningDomain"
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