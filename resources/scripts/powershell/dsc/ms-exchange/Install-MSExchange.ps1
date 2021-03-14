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
        [ValidateSet('MXS2016-x64-CU19-KB4588884','MXS2016-x64-CU18-KB4571788','MXS2016-x64-CU17-KB4556414','MXS2016-x64-CU16-KB4537678','MXS2016-x64-CU15-KB4522150','MXS2016-x64-CU14-KB4514140','MXS2016-x64-CU13-KB4488406','MXS2016-x64-CU12-KB4471392')]
        [string]$MXSRelease
    ) 
    
    Import-DscResource -ModuleName ComputerManagementDsc, xPSDesiredStateConfiguration, xExchange, StorageDsc

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

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
        'MXS2016-x64-CU12-KB4471392' { 'ExchangeServer2016-x64-cu12.iso' }
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

        # ***** Mount Image *****
        MountImage MountMXSISO
        {
            Ensure = 'Present'
            ImagePath = $MXSISOFilePath
            DriveLetter = 'F'
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

        # Install Exchange
        xExchInstall InstallExchange
        {
            Path       = 'F:\Setup.exe'
            Arguments  = "/mode:Install /role:Mailbox /OrganizationName:$DomainNetbiosName /DomainController:$DomainController.$DomainFQDN /Iacceptexchangeserverlicenseterms"
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