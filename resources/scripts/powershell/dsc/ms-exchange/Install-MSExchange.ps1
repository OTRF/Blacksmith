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
        [ValidateSet(
            'MXS2019-x64-CU12-KB5011156',
            'MXS2019-x64-CU11-KB5005334',
            'MXS2016-x64-CU23-KB5011155',
            'MXS2016-x64-CU22-KB5005333',
            'MXS2016-x64-CU21-KB5003611',
            'MXS2016-x64-CU20-KB4602569',
            'MXS2016-x64-CU19-KB4588884',
            'MXS2016-x64-CU18-KB4571788',
            'MXS2016-x64-CU17-KB4556414',
            'MXS2016-x64-CU16-KB4537678',
            'MXS2016-x64-CU15-KB4522150',
            'MXS2016-x64-CU14-KB4514140',
            'MXS2016-x64-CU13-KB4488406',
            'MXS2016-x64-CU12-KB4471392'
        )]
        [string]$MXSRelease
    ) 
    
    Import-DscResource -ModuleName ComputerManagementDsc, xPSDesiredStateConfiguration, xExchange, StorageDsc

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    # Set MS Exchange ISO File
    # Reference: https://docs.microsoft.com/en-us/exchange/new-features/build-numbers-and-release-dates?view=exchserver-2019&WT.mc_id=M365-MVP-5003086
    $MXSISOFile = Switch ($MXSRelease) {
        'MXS2019-x64-CU12-KB5011156' { @{ISO = 'ExchangeServer2019-x64-CU12.ISO'; ServerVersion = 2019; CumulativeUpdate = 12} }
        'MXS2019-x64-CU11-KB5005334' { @{ISO = 'ExchangeServer2019-x64-CU11.ISO'; ServerVersion = 2019; CumulativeUpdate = 11} }
        'MXS2016-x64-CU23-KB5011155' { @{ISO = 'ExchangeServer2016-x64-CU23.ISO'; ServerVersion = 2016; CumulativeUpdate = 23} }
        'MXS2016-x64-CU22-KB5005333' { @{ISO = 'ExchangeServer2016-x64-CU22.ISO'; ServerVersion = 2016; CumulativeUpdate = 22} }
        'MXS2016-x64-CU21-KB5003611' { @{ISO = 'ExchangeServer2016-x64-CU21.ISO'; ServerVersion = 2016; CumulativeUpdate = 21} }
        'MXS2016-x64-CU20-KB4602569' { @{ISO = 'ExchangeServer2016-x64-CU20.ISO'; ServerVersion = 2016; CumulativeUpdate = 20} }
        'MXS2016-x64-CU19-KB4588884' { @{ISO = 'ExchangeServer2016-x64-CU19.ISO'; ServerVersion = 2016; CumulativeUpdate = 19} }
        'MXS2016-x64-CU18-KB4571788' { @{ISO = 'ExchangeServer2016-x64-cu18.iso'; ServerVersion = 2016; CumulativeUpdate = 18} }
        'MXS2016-x64-CU17-KB4556414' { @{ISO = 'ExchangeServer2016-x64-cu17.iso'; ServerVersion = 2016; CumulativeUpdate = 17} }
        'MXS2016-x64-CU16-KB4537678' { @{ISO = 'ExchangeServer2016-x64-CU16.ISO'; ServerVersion = 2016; CumulativeUpdate = 16} }
        'MXS2016-x64-CU15-KB4522150' { @{ISO = 'ExchangeServer2016-x64-CU15.ISO'; ServerVersion = 2016; CumulativeUpdate = 15} }
        'MXS2016-x64-CU14-KB4514140' { @{ISO = 'ExchangeServer2016-x64-cu14.iso'; ServerVersion = 2016; CumulativeUpdate = 14} }
        'MXS2016-x64-CU13-KB4488406' { @{ISO = 'ExchangeServer2016-x64-cu13.iso'; ServerVersion = 2016; CumulativeUpdate = 13} }
        'MXS2016-x64-CU12-KB4471392' { @{ISO = 'ExchangeServer2016-x64-cu12.iso'; ServerVersion = 2016; CumulativeUpdate = 12} }
    }

    $MXSISOFileCU = $MXSISOFile.CumulativeUpdate
    $MXSISOFileServerVersion = $MXSISOFile.ServerVersion

    <#
    https://support.microsoft.com/en-us/topic/setup-fails-for-unattended-installation-of-exchange-server-2019-cu11-or-2016-cu22-or-later-234d7d9a-a94e-4386-9384-46761edf9268
    Exchange Server 2019 CU11 and Exchange Server 2016 CU22 introduce two new setup switches for the EULA, and remove an existing parameter (IAcceptExchangeServerLicenseTerms).
    This change was made to enable administrators to set the state of diagnostic data collection that is done in Exchange Server 2019 CU11 and Exchange Server 2016 CU22 and later CUs.
    To accept the EULA and set the state of diagnostic data collection, use either of following parameters:
    - /IAcceptExchangeServerLicenseTerms_DiagnosticDataON (This parameter enables sending data to Microsoft.)
    - /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF (This parameter disables sending data to Microsoft.)
    #>

    if (($MXSISOFileServerVersion -eq 2016 -and $MXSISOFileCU -ge 22) -or ($MXSISOFileServerVersion -eq 2019 -and $MXSISOFileCU -ge 11)) {
        $InstallExchangeArgs = "/mode:Install /role:Mailbox /OrganizationName:$DomainNetbiosName /DomainController:$DomainController.$DomainFQDN /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF"
    } else {
        $InstallExchangeArgs = "/mode:Install /role:Mailbox /OrganizationName:$DomainNetbiosName /DomainController:$DomainController.$DomainFQDN /Iacceptexchangeserverlicenseterms"
    }
    $MXSISOFilePath = Join-Path $MXSISODirectory $MXSISOFile.ISO

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
            Arguments  = $InstallExchangeArgs
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