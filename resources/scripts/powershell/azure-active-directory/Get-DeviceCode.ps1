function Get-DeviceCode {
    <#
    .SYNOPSIS
    A PowerShell script to get a device code to initiate authentication.
    
    Author: Roberto Rodriguez (@Cyb3rWard0g)
    License: MIT
    Required Dependencies: None
    Optional Dependencies: None
    
    .DESCRIPTION
    Get-DeviceCode is a simple PowerShell to get a device code for a specific Azure AD application to initiate authentication. 

    .PARAMETER ClientId
    The Application (client) ID assigned to the Azure AD application.

    .PARAMETER TenantId
    Tenant ID. Can be /common, /consumers, or /organizations. It can also be the directory tenant that you want to request permission from in GUID or friendly name format.

    .PARAMETER Scope
    A space-separated list of scopes that you want the user to consent to.

    .LINK
    https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-device-code#:~:text=The%20device%20code%20flow%20is%20a%20polling%20protocol,hasn%27t%20finished%20authenticating%2C%20but%20hasn%27t%20canceled%20the%20flow.

    #>

    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ClientId,
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        [Parameter(Mandatory = $true)]
        [string]$Scope
    )
    # Force TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Device authorization request
    # Authentication server for a device
    if (!$TenantId){
        $TenantId = 'organizations'
    }
    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    $body = @{
        client_id = $ClientId
        scope = $Scope
    }
    $Params = @{
        Headers = $headers
        uri     = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode"
        Body    = $body
        method  = 'Post'
    }
    $request  = Invoke-RestMethod @Params

    # Process authorization request
    if(-not $request.device_code)
    {
        throw "Device Code Flow failed"
    }
    else{
        $request
    }
}