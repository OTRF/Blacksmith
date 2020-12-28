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
        [String]$CertificateName,

        [Parameter(Mandatory)]
        [Object]$DomainUsers
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xPSDesiredStateConfiguration, xDnsServer, ComputerManagementDsc
    
    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminCreds.Password)
    $AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $ADFSSiteName = "ADFS"
    $ComputerName = Get-Content env:computername

    $DomainUsers.GetType() | Add-Content -Path C:\ProgramData\PSLOGS.txt
    Add-Content -Value $DomainUsers -Path C:\ProgramData\PSLOGS.txt

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

        # ***** Create OUs *****
        xScript CreateOUs
        {
            SetScript = {
                # Verifying ADWS service is running
                $ServiceName = 'ADWS'
                $arrService = Get-Service -Name $ServiceName

                while ($arrService.Status -ne 'Running')
                {
                    Start-Service $ServiceName
                    Start-Sleep -seconds 5
                    $arrService.Refresh()
                }

                $DomainName1,$DomainName2 = ($using:domainFQDN).split('.')

                $ParentPath = "DC=$DomainName1,DC=$DomainName2"
                $OUS = @(("Workstations","Workstations in the domain"),("Servers","Servers in the domain"),("LogCollectors","Servers collecting event logs"),("DomainUsers","Users in the domain"))

                foreach($OU in $OUS)
                {
                    #Check if exists, if it does skip
                    [string] $Path = "OU=$($OU[0]),$ParentPath"
                    if(![adsi]::Exists("LDAP://$Path"))
                    {
                        New-ADOrganizationalUnit -Name $OU[0] -Path $ParentPath `
                            -Description $OU[1] `
                            -ProtectedFromAccidentalDeletion $false -PassThru
                    }
                }
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

        # ***** Create Domain Users *****
        xScript CreateDomainUsers
        {
            SetScript = {
                # Verifying ADWS service is running
                $ServiceName = 'ADWS'
                $arrService = Get-Service -Name $ServiceName

                while ($arrService.Status -ne 'Running')
                {
                    Start-Service $ServiceName
                    Start-Sleep -seconds 5
                    $arrService.Refresh()
                }

                $DomainName = $using:domainFQDN
                $DomainName1,$DomainName2 = $DomainName.split('.')
                $ADServer = $using:ComputerName+"."+$DomainName

                $NewDomainUsers = $using:DomainUsers
                Add-Content -Value $NewDomainUsers -Path C:\ProgramData\PSLOGS.txt
                
                foreach ($User in $NewDomainUsers)
                {
                    write-host $User
                    Add-Content -Value $User -Path C:\ProgramData\PSLOGS.txt
                    $UserPrincipalName = $User.SamAccountName + "@" + $DomainName
                    $DisplayName = $User.LastName + " " + $User.FirstName
                    $OUPath = "OU="+$User.UserContainer+",DC=$DomainName1,DC=$DomainName2"
                    $SamAccountName = $User.SamAccountName
                    $ServiceName = $User.FirstName

                    $User = Get-ADUser -LDAPFilter "(sAMAccountName=$SamAccountName)"

                    if ($User -eq $Null)
                    {
                        write-host "Creating user $UserPrincipalName .."
                        New-ADUser -Name $DisplayName `
                        -DisplayName $DisplayName `
                        -GivenName $User.FirstName `
                        -Surname $User.LastName `
                        -Department $User.Department `
                        -Title $User.JobTitle `
                        -UserPrincipalName $UserPrincipalName `
                        -SamAccountName $User.SamAccountName `
                        -Path $OUPath `
                        -AccountPassword (ConvertTo-SecureString $User.Password -AsPlainText -force) `
                        -Enabled $true `
                        -PasswordNeverExpires $true `
                        -Server $ADServer

                        if($User.Identity -Like "Domain Admins")
                        {
                            $DomainAdminUser = $User.SamAccountName
                            $Groups = @('domain admins','schema admins','enterprise admins')
                            $Groups | ForEach-Object{
                                $members = Get-ADGroupMember -Identity $_ -Recursive | Select-Object -ExpandProperty Name
                                if ($members -contains $DomainAdminUser)
                                {
                                    Write-Host "$DomainAdminUser exists in $_ "
                                }
                                else {
                                    Add-ADGroupMember -Identity $_ -Members $DomainAdminUser
                                }
                            }
                        }
                        if($User.JobTitle -Like "Service Account")
                        {
                            setspn -a $ServiceName/$DomainName $DomainName1\$SamAccountName
                        }
                    }
                }
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
            DependsOn = "[xScript]CreateOUs"
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