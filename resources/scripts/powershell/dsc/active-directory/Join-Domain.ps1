# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
configuration Join-Domain {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [String]$DCIPAddress,

        [Parameter(Mandatory)]
        [String]$JoinOU
    ) 
    
    Import-DscResource -ModuleName NetworkingDsc, ActiveDirectoryDsc, xPSDesiredStateConfiguration, ComputerManagementDsc

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    $ComputerName = Get-Content env:computername

    Node localhost
    {
        LocalConfigurationManager
        {           
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
            Credential              = $AdminCreds
            DependsOn               = "[DnsServerAddress]SetDNS"
        }

        Computer JoinDomain
        {
            Name          = $ComputerName 
            DomainName    = $DomainFQDN
            Credential    = $AdminCreds
            JoinOU        = $JoinOU
            DependsOn  = "[WaitForADDomain]WaitForDCReady"
        }

        PendingReboot RebootAfterJoiningDomain
        { 
            Name = "RebootServer"
            DependsOn = "[Computer]JoinDomain"
        }
    }
}