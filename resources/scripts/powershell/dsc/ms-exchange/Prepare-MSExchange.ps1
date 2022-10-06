# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
configuration Prepare-MSExchange
{    
    Import-DscResource -ModuleName ComputerManagementDsc, xPSDesiredStateConfiguration

    Node localhost
    {
        LocalConfigurationManager 
        {
            ActionAfterReboot   = 'ContinueConfiguration'
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        xScript disableHybridDetectionRegKey
        {
            SetScript =
            {
				$registryPath = 'HKLM:SOFTWARE\Microsoft\ExchangeServer\v15\Setup\'
				$name = 'RunHybridDetection'
				$value = '1'
                New-Item -Path $registryPath -Force | Out-Null
				New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null
            }
            GetScript = {
                return @{ "Result" = "false" }
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
            Name = @(
                'NET-Framework-45-Features', # .NET Framework 4.6 Features
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
        }

        # ###############################
        # Install Requirements Features #
        # ###############################

        # ***** Unified Communications Managed API 4.0 Runtime *****
        xRemoteFile DownloadUcma
        {
            DestinationPath = "C:\ProgramData\UcmaRuntimeSetup.exe"
            Uri             = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
            DependsOn       = @("[xScript]disableHybridDetectionRegKey","[xWindowsFeatureSet]InstallWinFeatures")
        }

        Package InstallUCMA4
        {
            Ensure      = "Present"
            Name        = "Microsoft Unified Communications Managed API 4.0, Runtime"
            Path        = "C:\ProgramData\UcmaRuntimeSetup.exe"
            ProductId   = '41D635FE-4F9D-47F7-8230-9B29D6D42D31'
            Arguments   = '-q'
            DependsOn   = "[xRemoteFile]DownloadUcma"
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
            DependsOn       = '[PendingReboot]RebootPostInstallUCMA4'
        }

        # ***** Download VC++ redist 2013 (x64) *****
        xRemoteFile Downloadvcredist2013
        {
            DestinationPath = "C:\ProgramData\vcredist_x64_2013.exe"
            Uri = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            DependsOn = '[PendingReboot]RebootPostInstallUCMA4'
        }

        # ***** Download VC++ redist 2012 (x64) *****
        xRemoteFile Downloadvcredist2012
        {
            DestinationPath = "C:\ProgramData\vcredist_x64_2012.exe"
            Uri = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
            DependsOn = '[PendingReboot]RebootPostInstallUCMA4'
        }

        xScript InstallAdditionalReqs
        {
            SetScript =
            {
                Start-Process -FilePath "C:\ProgramData\vcredist_x64_2013.exe" -ArgumentList @('/install','/quiet','/norestart') -NoNewWindow -Wait
                Start-Process -FilePath "C:\ProgramData\vcredist_x64_2012.exe" -ArgumentList @('/install','/quiet','/norestart') -NoNewWindow -Wait
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
            DependsOn = @("[xRemoteFile]DownloadDotNet48","[xRemoteFile]Downloadvcredist2012","[xRemoteFile]Downloadvcredist2013")
        }

        <#
        IIS URL Rewrite module download and install
        -------------------------------------------
        IIS URL Rewrite 2.1 enables Web administrators to create powerful rules to implement URLs that are easier for users to remember and easier for search engines to find.
        https://www.iis.net/downloads/microsoft/url-rewrite
        #>
        xRemoteFile DownloadUrlRewrite
        {
            DestinationPath = "C:\ProgramData\rewrite_amd64_en-US.msi"
            Uri             = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
            DependsOn       = "[xScript]InstallAdditionalReqs"
        }

        Package UrlRewrite
        {
            Ensure      = "Present"
            Name        = "IIS URL Rewrite Module 2"
            Path        = "C:\ProgramData\rewrite_amd64_en-US.msi"
            ProductId   = "9BCA2118-F753-4A1E-BCF3-5A820729965C"
            Arguments   = '/L*V "C:\ProgramData\urlrewriter.txt" /quiet'
            DependsOn   = "[xRemoteFile]DownloadUrlRewrite"
        }

        # Reboot Before installing MX
        PendingReboot RebootBeforeMXInstall
        { 
            Name        = "RebootBeforeMXInstall"
            DependsOn   = "[Package]UrlRewrite"
        }
    }
}