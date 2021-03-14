# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
configuration PrepareAD-MSExchange
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

    #https://docs.microsoft.com/en-us/Exchange/plan-and-deploy/prepare-ad-and-domains?view=exchserver-2016#exchange-2016-active-directory-versions
    $MXDirVersions = Switch ($MXSRelease) {
        'MXS2016-x64-CU19-KB4588884' { @{SchemaVersion = 15333; OrganizationVersion = 16219; DomainVersion = 13239} }
        'MXS2016-x64-CU18-KB4571788' { @{SchemaVersion = 15332; OrganizationVersion = 16218; DomainVersion = 13238} }
        'MXS2016-x64-CU17-KB4556414' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU16-KB4537678' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU15-KB4522150' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU14-KB4514140' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU13-KB4488406' { @{SchemaVersion = 15332; OrganizationVersion = 16217; DomainVersion = 13237} }
        'MXS2016-x64-CU12-KB4471392' { @{SchemaVersion = 15332; OrganizationVersion = 16215; DomainVersion = 13236} }
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
        
        # #####################
        # Prepare Exchange AD #
        # #####################

        # Prepare Schema
        xScript PrepSchema
        {
            SetScript =
            {
                F:\Setup.exe /PrepareSchema /DomainController:$using:DomainController.$using:DomainFQDN /IAcceptExchangeServerLicenseTerms
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
            PsDscRunAsCredential = $DomainCreds
            DependsOn  = '[WaitForVolume]WaitForISO'
        }
        <#
        xExchInstall PrepSchema
		{
			Path = 'F:\Setup.exe'
            Arguments = "/PrepareSchema /DomainController:$DomainController.$DomainFQDN /IAcceptExchangeServerLicenseTerms"
            Credential = $DomainCreds
            DependsOn  = '[WaitForVolume]WaitForISO'
        }
        
        # Prepare AD
        xExchInstall PrepAD
		{
			Path = 'F:\Setup.exe'
            Arguments = "/PrepareAD /OrganizationName:$DomainNetbiosName /DomainController:$DomainController.$DomainFQDN /IAcceptExchangeServerLicenseTerms"
            Credential = $DomainCreds
            DependsOn  = '[xExchInstall]PrepSchema'
        }
        #>
        xScript PrepAD
        {
            SetScript =
            {
                F:\Setup.exe /PrepareAD /OrganizationName:$using:DomainNetbiosName /DomainController:$using:DomainController.$using:DomainFQDN /IAcceptExchangeServerLicenseTerms
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
            PsDscRunAsCredential = $DomainCreds
            DependsOn  = '[xScript]PrepSchema'
        }

        # https://docs.microsoft.com/en-us/Exchange/plan-and-deploy/prepare-ad-and-domains?view=exchserver-2016#step-2-prepare-active-directory
		xExchWaitForADPrep WaitPrepAD
		{
			Identity            = "not used"
			Credential          = $DomainCreds
			SchemaVersion       = $MXDirVersions.SchemaVersion
            OrganizationVersion = $MXDirVersions.OrganizationVersion
            DomainVersion       = $MXDirVersions.DomainVersion
            DependsOn           = '[xScript]PrepAD'
        }

        # See if a reboot is required after Exchange PrepAD
        PendingReboot RebootAfterMXPrepAD
        { 
            Name = "RebootAfterMXInstall"
            DependsOn = '[xExchWaitForADPrep]WaitPrepAD'
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