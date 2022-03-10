function Invoke-M365DStreaming {
    <#
    .SYNOPSIS
    A PowerShell script to use the Microsoft 365 Defender Streaming API.
    
    Author: Roberto Rodriguez (@Cyb3rWard0g)
    License: MIT
    Required Dependencies: None
    Optional Dependencies: None
    
    .DESCRIPTION
    Invoke-M365DStreaming is a simple PowerShell wrapper to interact with the Microsoft 365 Defender Streaming APIs to configure M365D export settings. 

    .PARAMETER RequestMethod
    HTTP request method. POST,GET,DELETE

    .PARAMETER DestinationType
    Specific type of destination. Currently this script only supports Microsoft Sentinel.

    .PARAMETER WorkspaceName
    if destination is Sentinel. Name of the Log Analytics workspace you want to stream Microsoft Defender for Endpoint and for Office 365 logs to.

    .PARAMETER WorkspaceResourceId
    if destination is Sentinel. Name of the Log Analytics workspace you want to stream Microsoft Defender for Endpoint and for Office 365 logs to.

    .PARAMETER AlertTables
    Microsoft Defender advanced hunting alert tables. Currently this script supports AlertEvidence,AlertInfo.
    
    .PARAMETER DeviceTables
    Microsoft Defender advanced hunting device tables. Currently this script supports DeviceInfo,DeviceNetworkInfo,DeviceProcessEvents,DeviceNetworkEvents,DeviceFileEvents,DeviceRegistryEvents,DeviceLogonEvents,DeviceImageLoadEvents,DeviceEvents,DeviceFileCertificateInfo.

    .PARAMETER EmailTables
    Microsoft Defender advanced hunting Email tables. Currently this script supports EmailAttachmentInfo,EmailEvents,EmailPostDeliveryEvents,EmailUrlInfo.

    .LINK
    https://docs.microsoft.com/en-us/microsoft-365/security/defender/advanced-hunting-schema-tables?view=o365-worldwide.

    #>

    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("post","get","delete")]
        [String]$RequestMethod='get',

        [Parameter(Mandatory = $false)]
        [ValidateSet("Microsoft Sentinel")]
        [String]$DestinationType='Microsoft Sentinel',

        [Parameter(Mandatory = $false)]
        [string]$WorkspaceName,

        [Parameter(Mandatory = $false)]
        [string]$WorkspaceResourceId,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AlertInfo","AlertEvidence")]
        [AllowEmptyCollection()]
        [string[]]$AlertTables,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AdvancedHunting-DeviceInfo","AdvancedHunting-DeviceNetworkInfo","AdvancedHunting-DeviceProcessEvents","AdvancedHunting-DeviceNetworkEvents","AdvancedHunting-DeviceFileEvents","AdvancedHunting-DeviceRegistryEvents","AdvancedHunting-DeviceLogonEvents","AdvancedHunting-DeviceImageLoadEvents","AdvancedHunting-DeviceEvents","AdvancedHunting-DeviceFileCertificateInfo")]
        [AllowEmptyCollection()]
        [string[]]$DeviceTables,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AdvancedHunting-EmailEvents","AdvancedHunting-EmailUrlInfo","AdvancedHunting-EmailAttachmentInfo","AdvancedHunting-EmailPostDeliveryEvents")]
        [AllowEmptyCollection()]
        [string[]]$EmailTables
        
    )

    # Get MS Graph access token
    Write-Host "[+] Getting WindowsDefenderAtp raw acess token.."
    $accessToken = (Get-AzAccessToken -ResourceUrl "https://securitycenter.microsoft.com/mtp").Token
    Write-Host $accessToken

    $headers = @{
        'Content-Type' = 'application/json'
    }
    
    Write-Host "[+] Setting HTTP request.."
    $Params = @{
        Headers = $headers
        Uri     = "https://api.security.microsoft.com/api/dataexportsettings$(if($WorkspaceName -And $RequestMethod -in @('Get','Delete')){"/SentinelExportSettings-$WorkspaceName"})"
        method  = $RequestMethod
    }

    $tables = $AlertTables + $DeviceTables + $EmailTables
    $logs = @()
    if ($tables.count -gt 0){
        Write-Host "[+] Creating Logs array with all M365 defender tables specified .."
        foreach ($t in $tables) {
            $logEntry = @{
                category = $t
                enabled = $true
            }
            $logs += $logEntry
        }

        Write-Host "[+] Setting up HTTP request body .."
        $body = @{
            id =  "SentinelExportSettings-" + $WorkspaceName
            workspaceProperties = @{
                workspaceResourceId = $WorkspaceResourceId
            }
            logs = $logs
        }
        $Params += @{ body = $body}
    }

    Write-Host "[+] Sending HTTP request to M365 defender streaming APIs .."
    Invoke-RestMethod @params
}