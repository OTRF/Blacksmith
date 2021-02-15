configuration Install-MSExchange
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [String]$DomainController,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [String]$MXSISODirectory,

        [Parameter(Mandatory)]
        [ValidateSet('MXS2016-x64-CU19-KB4588884','MXS2016-x64-CU18-KB4571788','MXS2016-x64-CU17-KB4556414','MXS2016-x64-CU16-KB4537678','MXS2016-x64-CU15-KB4522150','MXS2016-x64-CU14-KB4514140','MXS2016-x64-CU13-KB4488406')]
        [string]$MXSRelease
    ) 
    
    Import-DscResource -ModuleName ComputerManagementDsc, xPSDesiredStateConfiguration, xExchange, StorageDsc

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    # Set MS Exchange ISO File
    # Reference: https://docs.microsoft.com/en-us/exchange/new-features/build-numbers-and-release-dates?view=exchserver-2019&WT.mc_id=M365-MVP-5003086
    $MXSISOFile = Switch ($MXSRelease) {
        'MXS2016-x64-CU19-KB4588884' { 'ExchangeServer2016-x64-CU19.ISO' }
        'MXS2016-x64-CU18-KB4571788' { 'ExchangeServer2016-x64-cu18.iso' }
        'MXS2016-x64-CU17-KB4556414' { 'ExchangeServer2016-x64-cu17.iso' }
        'MXS2016-x64-CU16-KB4537678' { 'ExchangeServer2016-x64-CU16.ISO' }
        'MXS2016-x64-CU15-KB4522150' { 'ExchangeServer2016-x64-CU15.ISO' }
        'MXS2016-x64-CU14-KB4514140' { 'ExchangeServer2016-x64-cu14.iso' }
        'MXS2016-x64-CU13-KB4488406' { 'ExchangeServer2016-x64-cu13.iso' }
    }

    #https://docs.microsoft.com/en-us/Exchange/plan-and-deploy/prepare-ad-and-domains?view=exchserver-2016#exchange-2016-active-directory-versions
    $MXDirVersions = Switch ($MXSRelease) {
        'MXS2016-x64-CU19-KB4588884' { @{SchemaVersion = 15333; OrganizationVersion = 16219; DomainVersion = 13239} }
        'MXS2016-x64-CU18-KB4571788' { @{SchemaVersion = 15332; OrganizationVersion = 16218; DomainVersion = 13238} }
        'MXS2016-x64-CU17-KB4556414' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU16-KB4537678' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU15-KB4522150' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU14-KB4514140' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU13-KB4488406' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
    }

    $MXSISOFilePath = Join-Path $MXSISODirectory $MXSISOFile

    Node localhost
    {
        LocalConfigurationManager 
        {
            ActionAfterReboot   = 'ContinueConfiguration'
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ##################
        # Install Features #
        # ##################

        # References: https://docs.microsoft.com/en-us/windows-server/administration/server-core/server-core-roles-and-services

        # .NET Framework 4.6 Features
        WindowsFeature NETFramework45Features
        {
            Ensure = "Present"
            Name   = "NET-Framework-45-Features"
        }

        # Media Foundation
        WindowsFeature ServerMediaFoundation
        {
            Ensure = 'Present'
            Name = 'Server-Media-Foundation'
        }

        # RPC over HTTP Proxy
        WindowsFeature RPCOverHTTPProxy
        {
            Ensure = "Present"
            Name   = "RPC-over-HTTP-proxy"
        }

        # Failover Clustering Tools
        WindowsFeature RSATClustering
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering"
        }

        # Failover Cluster Command Interface
        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-CmdInterface"
        }

        # Failover Failover Cluster Mgmt
        WindowsFeature RSATClusteringMgmt
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-Mgmt"
        }

        # Failover Cluster Module for Windows PowerShell
        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-PowerShell"
        }

        # Web Mgmt Console
        WindowsFeature WebMgmtConsole
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Console"
        }

        # Process Model
        WindowsFeature WASProcessModel
        {
            Ensure = "Present"
            Name   = "WAS-Process-Model"
        }

        # ASP.NET 4.6
        WindowsFeature WebAspNet45
        {
            Ensure = "Present"
            Name   = "Web-Asp-Net45"
        }

        # Basic Authentication
        WindowsFeature WebBasicAuth
        {
            Ensure = "Present"
            Name   = "Web-Basic-Auth"
        }

        # Client Certificate Mapping Authentication
        WindowsFeature WebClientAuth
        {
            Ensure = "Present"
            Name   = "Web-Client-Auth"
        }

        # Digest Authentication
        WindowsFeature WebDigestAuth
        {
            Ensure = "Present"
            Name   = "Web-Digest-Auth"
        }

        # Directory Browsing
        WindowsFeature WebDirBrowsing
        {
            Ensure = "Present"
            Name   = "Web-Dir-Browsing"
        }

        # Dynamic Content Compression
        WindowsFeature WebDynCompression
        {
            Ensure = "Present"
            Name   = "Web-Dyn-Compression"
        }

        # HTTP Errors
        WindowsFeature WebHttpErrors
        {
            Ensure = "Present"
            Name   = "Web-Http-Errors"
        }

        # HTTP Logging
        WindowsFeature WebHttpLogging
        {
            Ensure = 'Present'
            Name = 'Web-Http-Logging'
        }

        # HTTP Redirection
        WindowsFeature HTTPRedirection
        {
            Ensure = "Present"
            Name   = "Web-Http-Redirect"
        }

        # Tracing
        WindowsFeature HTTPTracing
        {
            Ensure = "Present"
            Name   = "Web-Http-Tracing"
        }

        # ISAPI Extensions
        WindowsFeature WebISAPIExt
        {
            Ensure = "Present"
            Name   = "Web-ISAPI-Ext"
        }

        # ISAPI Filters
        WindowsFeature WebISAPIFilter
        {
            Ensure = "Present"
            Name   = "Web-ISAPI-Filter"
        }

        # Web Legacy Mgmt Console
        WindowsFeature WebLgcyMgmtConsole
        {
            Ensure = "Present"
            Name   = "Web-Lgcy-Mgmt-Console"
        }

        # IIS 6 Metabase Compatibility
        WindowsFeature WebMetabase
        {
            Ensure = "Present"
            Name   = "Web-Metabase"
        }

        # Management Service
        WindowsFeature WebMgmtService
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Service"
        }

        # .NET Extensibility 4.6
        WindowsFeature WebNetExt45
        {
            Ensure = "Present"
            Name   = "Web-Net-Ext45"
        }

        # Request Monitor
        WindowsFeature RequestMonitor
        {
            Ensure = "Present"
            Name   = "Web-Request-Monitor"
        }

        # Web Server IIS
        WindowsFeature WebServer
        {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        # Static Content Compression
        WindowsFeature WebStatCompression
        {
            Ensure = "Present"
            Name   = "Web-Stat-Compression"
        }

        # Static Content
        WindowsFeature StaticContent
        {
            Ensure = "Present"
            Name   = "Web-Static-Content"
        }

        # Windows Authentication
        WindowsFeature WebWindowsAuth
        {
            Ensure = "Present"
            Name   = "Web-Windows-Auth"
        }

        # IIS 6 WMI Compatibility
        WindowsFeature WebWMI
        {
            Ensure = "Present"
            Name   = "Web-WMI"
        }

        # Windows Identity Foundation
        WindowsFeature WindowsIdentityFoundation
        {
            Ensure = "Present"
            Name   = "Windows-Identity-Foundation"
        }

        # AD DS Tools
        WindowsFeature RSATADDS
        {
            Ensure = "Present"
            Name   = "RSAT-ADDS"
        }

        # Check if there is a need to reboot before continuing
        PendingReboot BeforeNETWCF45
        {
            Name   = "BeforeNETWCF45"
            DependsOn = '[WindowsFeature]RSATADDS'
        }

        # HTTP Activation
        WindowsFeature NETWCFHTTPActivation45
        {
            Ensure = 'Present'
            Name = 'NET-WCF-HTTP-Activation45'
            DependsOn = '[PendingReboot]BeforeNETWCF45'
        }

        # ***** Download Pre-Requirements *****

        # .NET Framework 4.8 (https://support.microsoft.com/kb/4503548)
        xRemoteFile dotNet48
        {
            DestinationPath = "C:\ProgramData\ndp48-x86-x64-allos-enu.exe"
            Uri             = "https://go.microsoft.com/fwlink/?linkid=2088631"
            DependsOn = '[PendingReboot]BeforeNETWCF45'
        }

        # ***** Unified Communications Managed API 4.0 Runtime *****
        xRemoteFile DownloadUcma
        {
            DestinationPath = "C:\ProgramData\UcmaRuntimeSetup.exe"
            Uri = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
            DependsOn = '[PendingReboot]BeforeNETWCF45'
        }

        # ***** Download VC++ redist 2013 (x64) *****
        xRemoteFile Downloadvcredist
        {
            DestinationPath = "C:\ProgramData\vcredist_x64.exe"
            Uri = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            DependsOn = '[PendingReboot]BeforeNETWCF45'
        }

        # ***** Install Requirements *****
        xScript InstallingReqs
        {
            SetScript = {
                Start-Process -FilePath "C:\ProgramData\UcmaRuntimeSetup.exe" -ArgumentList @('/quiet','/norestart') -NoNewWindow -Wait
                Start-Process -FilePath "C:\ProgramData\vcredist_x64.exe" -ArgumentList @('/install','/passive','/norestart') -NoNewWindow -Wait
                Start-Process -FilePath "C:\ProgramData\ndp48-x86-x64-allos-enu.exe" -ArgumentList "/q" -NoNewWindow -Wait
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
            DependsOn = @("[xRemoteFile]dotNet48","[xRemoteFile]DownloadUcma","[xRemoteFile]Downloadvcredist")
        }

        # ***** Mount Image *****
        MountImage MountMXSISO
        {
            Ensure = 'Present'
            ImagePath = $MXSISOFilePath
            DriveLetter = 'F'
            DependsOn = "[xScript]InstallingReqs"
        }

        WaitForVolume WaitForISO
        {
            DriveLetter      = 'F'
            RetryIntervalSec = 5
            RetryCount       = 10
            DependsOn = "[MountImage]MountMXSISO"
        }
        
        # Prepare AD
        xExchInstall PrepAD
		{
			Path = 'F:\Setup.exe'
            Arguments = "/PrepareAD /OrganizationName:$DomainNetbiosName /DomainController:$DomainController.$DomainFQDN /IAcceptExchangeServerLicenseTerms"
            Credential = $DomainCreds
            DependsOn  = '[WaitForVolume]WaitForISO'

		}

        # https://docs.microsoft.com/en-us/Exchange/plan-and-deploy/prepare-ad-and-domains?view=exchserver-2016#step-2-prepare-active-directory
		xExchWaitForADPrep WaitPrepAD
		{
			Identity            = "not used"
			Credential          = $DomainCreds
			SchemaVersion       = $MXDirVersions.SchemaVersion
            OrganizationVersion = $MXDirVersions.OrganizationVersion
            DomainVersion       = $MXDirVersions.DomainVersion
            DependsOn           = '[xExchInstall]PrepAD'
        }
        
        # Install Exchange
        xExchInstall InstallExchange
        {
            Path       = 'F:\Setup.exe'
            Arguments  = "/mode:Install /role:Mailbox /OrganizationName:$DomainNetbiosName /Iacceptexchangeserverlicenseterms /InstallWindowsComponents"
            Credential = $DomainCreds
            DependsOn  = '[xExchWaitForADPrep]WaitPrepAD'
        }

        # See if a reboot is required after installing Exchange
        PendingReboot RebootAfterMXInstall
        { 
            Name = "RebootAfterMXInstall"
            DependsOn = '[xExchInstall]InstallExchange'
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