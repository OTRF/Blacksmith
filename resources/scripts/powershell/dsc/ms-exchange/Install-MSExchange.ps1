# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
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

        xScript disableHybridDetectionRegKey {
            GetScript = { }
            SetScript = {
				$registryPath = 'HKLM:SOFTWARE\Microsoft\ExchangeServer\v15\Setup\'
				$name = 'RunHybridDetection'
				$value = '1'
                New-Item -Path $registryPath -Force | Out-Null
				New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null
            }
            TestScript = {
                Test-Path 'HKLM:SOFTWARE\Microsoft\ExchangeServer\v15\Setup\'
            }
        }

        # ##################
        # Install Features #
        # ##################

        # References: https://docs.microsoft.com/en-us/windows-server/administration/server-core/server-core-roles-and-services
        
        xWindowsFeatureSet InstallWinFeatures
        {
            Ensure = 'Present'
            Name = @('NET-Framework-45-Features', # .NET Framework 4.6 Features
                'NET-WCF-HTTP-Activation45', # HTTP Activation
                'Server-Media-Foundation', # Media Foundation
                'RPC-over-HTTP-proxy', # RPC over HTTP Proxy
                'RSAT-Clustering', # Failover Clustering Tools
                'RSAT-Clustering-CmdInterface', # Failover Cluster Command Interface
                'RSAT-Clustering-Mgmt', # Failover Failover Cluster Mgmt
                'RSAT-Clustering-PowerShell', # Failover Cluster Module for Windows PowerShell
                'Web-Mgmt-Console', # Web Mgmt Console
                'WAS-Process-Model', # Process Model
                'Web-Asp-Net45', # ASP.NET 4.6
                'Web-Basic-Auth', # Basic Authentication
                'Web-Client-Auth', # Client Certificate Mapping Authentication
                'Web-Digest-Auth', # Digest Authentication
                'Web-Dir-Browsing', # Directory Browsing
                'Web-Dyn-Compression', # Dynamic Content Compression
                'Web-Http-Errors', # HTTP Errors
                'Web-Http-Logging', # HTTP Logging
                'Web-Http-Redirect', # HTTP Redirection
                'Web-Http-Tracing', # Tracing
                'Web-ISAPI-Ext', # ISAPI Extensions
                'Web-ISAPI-Filter', # ISAPI Filters
                'Web-Lgcy-Mgmt-Console', # Web Legacy Mgmt Console
                'Web-Metabase', # IIS 6 Metabase Compatibility
                'Web-Mgmt-Service', # Management Service
                'Web-Net-Ext45', # .NET Extensibility 4.6
                'Web-Request-Monitor', # Request Monitor
                'Web-Server', # Web Server IIS
                'Web-Stat-Compression', # Static Content Compression
                'Web-Static-Content', # Static Content
                'Web-Windows-Auth', # Windows Authentication
                'Web-WMI', # IIS 6 WMI Compatibility
                'Windows-Identity-Foundation', # Windows Identity Foundation
                'RSAT-ADDS' # AD DS Tools
            )
            DependsOn = "[xScript]disableHybridDetectionRegKey"
        }

        # ###############################
        # Install Requirements Features #
        # ###############################

        # ***** Unified Communications Managed API 4.0 Runtime *****
        xRemoteFile DownloadUcma
        {
            DestinationPath = "C:\ProgramData\UcmaRuntimeSetup.exe"
            Uri = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
            DependsOn = '[xWindowsFeatureSet]InstallWinFeatures'
        }

        Package InstallUCMA4
		{
			Ensure = "Present"
			Name = "Microsoft Unified Communications Managed API 4.0, Runtime"
			Path = "C:\ProgramData\UcmaRuntimeSetup.exe"
			ProductId = '41D635FE-4F9D-47F7-8230-9B29D6D42D31'
			Arguments = '-q' # args for silent mode
			DependsOn = "[xRemoteFile]DownloadUcma"
		}
		
		# Reboot node if necessary
		PendingReboot RebootPostInstallUCMA4
        {
            Name      = "AfterUCMA4"
            DependsOn = "[Package]InstallUCMA4"
        }

        # .NET Framework 4.8 (https://support.microsoft.com/kb/4503548)
        xRemoteFile DownloadDotNet48
        {
            DestinationPath = "C:\ProgramData\ndp48-x86-x64-allos-enu.exe"
            Uri             = "https://go.microsoft.com/fwlink/?linkid=2088631"
            DependsOn = '[PendingReboot]RebootPostInstallUCMA4'
        }

        # ***** Download VC++ redist 2013 (x64) *****
        xRemoteFile Downloadvcredist
        {
            DestinationPath = "C:\ProgramData\vcredist_x64.exe"
            Uri = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            DependsOn = '[PendingReboot]RebootPostInstallUCMA4'
        }

        xScript InstallAdditionalReqs
        {
            SetScript = {
                Start-Process -FilePath "C:\ProgramData\vcredist_x64.exe" -ArgumentList @('/install','/passive','/norestart') -NoNewWindow -Wait
                Start-Process -FilePath "C:\ProgramData\ndp48-x86-x64-allos-enu.exe" -ArgumentList @("/quiet /norestart") -NoNewWindow -Wait
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
            DependsOn = @("[xRemoteFile]DownloadDotNet48","[xRemoteFile]Downloadvcredist")
        }

        # Reboot Before installing MX
        PendingReboot RebootBeforeMXInstall
        { 
            Name = "RebootBeforeMXInstall"
            DependsOn = '[xScript]InstallAdditionalReqs'
        }

        # ***** Mount Image *****
        MountImage MountMXSISO
        {
            Ensure = 'Present'
            ImagePath = $MXSISOFilePath
            DriveLetter = 'F'
            DependsOn = "[PendingReboot]RebootBeforeMXInstall"
        }

        WaitForVolume WaitForISO
        {
            DriveLetter      = 'F'
            RetryIntervalSec = 5
            RetryCount       = 10
            DependsOn = "[MountImage]MountMXSISO"
        }
        
        # ##################
        # Install Exchange #
        # ##################

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
            Arguments  = "/mode:Install /role:Mailbox /OrganizationName:$DomainNetbiosName /Iacceptexchangeserverlicenseterms"
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