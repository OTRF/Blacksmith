configuration Install-MSExchange
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
        [String]$JoinOU,

        [Parameter(Mandatory)]
        [String]$MXSISODirectory,

        [Parameter(Mandatory)]
        [ValidateSet('MXS2016-x64-CU19-KB4588884','MXS2016-x64-CU18-KB4571788','MXS2016-x64-CU17-KB4556414','MXS2016-x64-CU16-KB4537678','MXS2016-x64-CU15-KB4522150','MXS2016-x64-CU14-KB4514140','MXS2016-x64-CU13-KB4488406')]
        [string]$MXSRelease
    ) 
    
    Import-DscResource -ModuleName NetworkingDsc, ActiveDirectoryDsc, ComputerManagementDsc, xPSDesiredStateConfiguration, xExchange, StorageDsc

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    $ComputerName = Get-Content env:computername

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

    $MXSISOFilePath = Join-Path $MXSISODirectory $MXSISOFile

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

        # ##################
        # Install Features #
        # ##################

        # .NET Framework 4.6 Features
        WindowsFeature NETFramework45Features
        {
            Ensure = "Present"
            Name   = "NET-Framework-45-Features"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # RPC over HTTP Proxy
        WindowsFeature RPCOverHTTPProxy
        {
            Ensure = "Present"
            Name   = "RPC-over-HTTP-proxy"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Failover Clustering Tools
        WindowsFeature RSATClustering
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Failover Cluster Command Interface
        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-CmdInterface"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Failover Failover Cluster Mgmt
        WindowsFeature RSATClusteringMgmt
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-Mgmt"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Failover Cluster Module for Windows PowerShell
        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-PowerShell"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Web Mgmt Console
        WindowsFeature WebMgmtConsole
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Console"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Process Model
        WindowsFeature WASProcessModel
        {
            Ensure = "Present"
            Name   = "WAS-Process-Model"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # ASP.NET 4.6
        WindowsFeature WebAspNet45
        {
            Ensure = "Present"
            Name   = "Web-Asp-Net45"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Basic Authentication
        WindowsFeature WebBasicAuth
        {
            Ensure = "Present"
            Name   = "Web-Basic-Auth"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Client Certificate Mapping Authentication
        WindowsFeature WebClientAuth
        {
            Ensure = "Present"
            Name   = "Web-Client-Auth"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Digest Authentication
        WindowsFeature WebDigestAuth
        {
            Ensure = "Present"
            Name   = "Web-Digest-Auth"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Directory Browsing
        WindowsFeature WebDirBrowsing
        {
            Ensure = "Present"
            Name   = "Web-Dir-Browsing"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Dynamic Content Compression
        WindowsFeature WebDynCompression
        {
            Ensure = "Present"
            Name   = "Web-Dyn-Compression"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # HTTP Errors
        WindowsFeature WebHttpErrors
        {
            Ensure = "Present"
            Name   = "Web-Http-Errors"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # HTTP Redirection
        WindowsFeature HTTPRedirection
        {
            Ensure = "Present"
            Name   = "Web-Http-Redirect"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Tracing
        WindowsFeature HTTPTracing
        {
            Ensure = "Present"
            Name   = "Web-Http-Tracing"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # ISAPI Extensions
        WindowsFeature WebISAPIExt
        {
            Ensure = "Present"
            Name   = "Web-ISAPI-Ext"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # ISAPI Filters
        WindowsFeature WebISAPIFilter
        {
            Ensure = "Present"
            Name   = "Web-ISAPI-Filter"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Web Legacy Mgmt Console
        WindowsFeature WebLgcyMgmtConsole
        {
            Ensure = "Present"
            Name   = "Web-Lgcy-Mgmt-Console"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # IIS 6 Metabase Compatibility
        WindowsFeature WebMetabase
        {
            Ensure = "Present"
            Name   = "Web-Metabase"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Management Service
        WindowsFeature WebMgmtService
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Service"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # .NET Extensibility 4.6
        WindowsFeature WebNetExt45
        {
            Ensure = "Present"
            Name   = "Web-Net-Ext45"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Request Monitor
        WindowsFeature RequestMonitor
        {
            Ensure = "Present"
            Name   = "Web-Request-Monitor"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Web Server IIS
        WindowsFeature WebServer
        {
            Ensure = "Present"
            Name   = "Web-Server"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Static Content Compression
        WindowsFeature WebStatCompression
        {
            Ensure = "Present"
            Name   = "Web-Stat-Compression"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Static Content
        WindowsFeature StaticContent
        {
            Ensure = "Present"
            Name   = "Web-Static-Content"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Windows Authentication
        WindowsFeature WebWindowsAuth
        {
            Ensure = "Present"
            Name   = "Web-Windows-Auth"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # IIS 6 WMI Compatibility
        WindowsFeature WebWMI
        {
            Ensure = "Present"
            Name   = "Web-WMI"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # Windows Identity Foundation
        WindowsFeature WindowsIdentityFoundation
        {
            Ensure = "Present"
            Name   = "Windows-Identity-Foundation"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # AD DS Snap-Ins and Command-Line Tools
        WindowsFeature RSATADDSTools
        {
            Ensure = "Present"
            Name   = "RSAT-ADDS-Tools"
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # #############
        # Join Domain #
        # #############

        # ***** Wait for DC Domain *****
        WaitForADDomain WaitForDCReady
        {
            DomainName              = $DomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $DomainCreds
            WaitForValidCredentials = $true
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        # ***** Join Domain *****
        Computer JoinDomain
        {
            Name          = $ComputerName 
            DomainName    = $DomainFQDN
            Credential    = $DomainCreds
            JoinOU        = $JoinOU
            DependsOn = @(
                "[WaitForADDomain]WaitForDCReady",
                "[WindowsFeature]NETFramework45Features",
                "[WindowsFeature]RPCOverHTTPProxy",
                "[WindowsFeature]RSATClustering",
                "[WindowsFeature]RSATClusteringCmdInterface",
                "[WindowsFeature]RSATClusteringMgmt",
                "[WindowsFeature]RSATClusteringPowerShell",
                "[WindowsFeature]WebMgmtConsole",
                "[WindowsFeature]WASProcessModel",
                "[WindowsFeature]WebAspNet45",
                "[WindowsFeature]WebBasicAuth",
                "[WindowsFeature]WebClientAuth",
                "[WindowsFeature]WebDigestAuth",
                "[WindowsFeature]WebDirBrowsing",
                "[WindowsFeature]WebDynCompression",
                "[WindowsFeature]WebHttpErrors",
                "[WindowsFeature]HTTPRedirection",
                "[WindowsFeature]HTTPTracing",
                "[WindowsFeature]WebISAPIExt",
                "[WindowsFeature]WebISAPIFilter",
                "[WindowsFeature]WebLgcyMgmtConsole",
                "[WindowsFeature]WebMetabase",
                "[WindowsFeature]WebMgmtService",
                "[WindowsFeature]WebNetExt45",
                "[WindowsFeature]RequestMonitor",
                "[WindowsFeature]WebServer",
                "[WindowsFeature]WebStatCompression",
                "[WindowsFeature]StaticContent",
                "[WindowsFeature]WebWindowsAuth",
                "[WindowsFeature]WebWMI",
                "[WindowsFeature]WindowsIdentityFoundation",
                "[WindowsFeature]RSATADDSTools"
            )
        }

        PendingReboot RebootAfterJoiningDomain
        { 
            Name = "RebootServer"
            DependsOn = "[Computer]JoinDomain"
        }

        # ***** Download Pre-Requirements *****

        # ***** Unified Communications Managed API 4.0 Runtime *****
        xRemoteFile DownloadUcma
        {
            DestinationPath = "C:\ProgramData\UcmaRuntimeSetup.exe"
            Uri = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
            DependsOn = "[PendingReboot]RebootAfterJoiningDomain"
        }

        # ***** Download VC++ redist 2013 (x64) *****
        xRemoteFile Downloadvcredist
        {
            DestinationPath = "C:\ProgramData\vcredist_x64.exe"
            Uri = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            DependsOn = "[PendingReboot]RebootAfterJoiningDomain"
        }

        # ***** Install Requirements *****
        xScript InstallingReqs
        {
            SetScript = {
                Start-Process -FilePath "C:\ProgramData\UcmaRuntimeSetup.exe" -ArgumentList "/q" -NoNewWindow -Wait
                Start-Process -FilePath "C:\ProgramData\vcredist_x64.exe" -ArgumentList "/q" -NoNewWindow -Wait
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
            DependsOn = @("[xRemoteFile]Downloadvcredist","[xRemoteFile]Downloadvcredist")
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

        # Install Exchange
        xExchInstall InstallExchange
        {
            Path       = 'F:\Setup.exe'
            Arguments  = '/mode:Install /role:Mailbox /Iacceptexchangeserverlicenseterms'
            Credential = $DomainCreds
            DependsOn  = '[WaitForVolume]WaitForISO'
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