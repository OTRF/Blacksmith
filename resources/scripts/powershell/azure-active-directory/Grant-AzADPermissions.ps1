function Grant-AzADPermissions {
    <#
    .SYNOPSIS
    A PowerShell wrapper around Az PowerShell and the Microsoft Graph API to grant permissions to a service principal.
    
    Author: Roberto Rodriguez (@Cyb3rWard0g)
    License: MIT
    Required Dependencies: Az PowerShell
    Optional Dependencies: None
    
    .DESCRIPTION
    Grant-AzADPermissions is a simple PowerShell wrapper around the Microsoft Graph API to grant permissions to a service principal. 

    .PARAMETER SvcPrincipalName
    Display name of the service principal. It is usually the same name as the Azure AD application.

    .PARAMETER SvcPrincipalId
    Service principal Id to use to add permissions directly. This helps to use service principals such as user assigned manage identities.

    .PARAMETER RoleSvcPrincipalDisplayName
    Display name of service principal to get roles from.

    .PARAMETER PermissionsList
    List of Microsoft Graph permissions to grant to the service principal.

    .PARAMETER PermissionsType
    Type of permissions. Delegated or Application.

    .PARAMETER PermissionsFile
    JSON file with permissions to grant to the service principal.

    .LINK
    https://docs.microsoft.com/en-us/graph/api/oauth2permissiongrant-post?view=graph-rest-1.0&tabs=http
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignments?view=graph-rest-1.0&tabs=http

    #>

    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $false)]
        [String] $SvcPrincipalName,

        [parameter(Mandatory = $false)]
        [string] $SvcPrincipalId,

        [parameter(Mandatory = $true)]
        [string] $RoleSvcPrincipalDisplayName,

        [parameter(Mandatory = $False)]
        [string[]] $PermissionsList,

        [parameter(Mandatory = $False)]
        [string[]] $PermissionsType,

        [parameter(Mandatory = $False)]
        [string] $PermissionsFile,

        [Parameter(Mandatory=$false)]
        [ValidateSet("User","ManagedIdentity")]
        [string] $ConnectAs = "User"
    )

    # Processing current security context
    Write-Host "[+] Running under the context of a $ConnectAs account"
    $context = az account show
    if (!$context) {
        if ($ConnectAs -eq 'User') {
            az login
        }
        else {
            az login --identity
        }
    }

    # Get MS Graph access token
    Write-Host "[+] Getting MS Graph raw acess token.."
    $accessToken=$(az account get-access-token --resource=https://graph.microsoft.com --query accessToken --output tsv)
    Write-Host $accessToken
    
    # Set up HTTP headers
    $Headers = @{}
    $Headers["Authorization"] = "Bearer $accessToken"
    $Headers["Content-Type"] = "application/json"
    
    # Getting service principal id if service principal name is provided
    if ($SvcPrincipalName){
        Write-Host "[+] Getting service principal id using the following display name: $SvcPrincipalName"
        $params = @{
            "Method"  = "Get"
            "Uri"     = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq '$SvcPrincipalName'"
            "Headers" = $Headers
        }
        $SvcPrincipalId = (((Invoke-RestMethod @params).value)[0]).id
        if (!$SvcPrincipalId) {
            Write-Error "Error looking for Azure AD application service principal"
            return
        }
    }

    Write-Host "[+] Service principal ID: $SvcPrincipalId"
    
    # Get ID of service principal used to get roles from
    $params = @{
        "Method"  = "Get"
        "Uri"     = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq '$RoleSvcPrincipalDisplayName'"
        "Headers" = $Headers
    }
    $roleSvcPrincipalId = (((Invoke-RestMethod @params).value)[0]).id
    if (!$roleSvcPrincipalId) {
        Write-Error "Error looking for Service Principal to get roles from"
        return
    }
    Write-Host "[+] Found ID of service principal to get roles from: $roleSvcPrincipalId"

    # Process MS Graph permissions
    Write-Host "[+] Retrieving permissions from file.."
    if ($PermissionsFile){
        $permissionsTable = Get-Content $PermissionsFile | ConvertFrom-Json
        $appResourceTypes = $permissionsTable | get-member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    }
    else {
        $permissionsTable = @{
            "$PermissionsType" = $PermissionsList
        }
        $appResourceTypes = @($PermissionsType)
    }

    foreach ($type in $appResourceTypes) {
        # Process permissions type
        $rolePropertyType = Switch ($type) {
            'delegated' { 'oauth2PermissionScopes'}
            'application' { 'appRoles' }
        }

        # Get permissions
        Write-Host "[+] Getting $type Permissions from $RoleSvcPrincipalDisplayName"
        $params = @{
            "Method"  = "Get"
            "Uri"     = "https://graph.microsoft.com/v1.0/servicePrincipals/$roleSvcPrincipalId"
            "Headers" = $Headers
        }
        $allPermissions = (Invoke-Restmethod @params).$rolePropertyType

        # Get Role Assignments
        Write-Host "[+]Processing Role Assignments:"
        $roleAssignments = @()
        $RequiredPermissions = $permissionsTable.$type
        Foreach ($rp in $RequiredPermissions) {
            Write-Host "  [>>] $rp"
            $roleAssignment = $allPermissions | Where-Object { $_.Value -eq $rp}
            $roleAssignments += $roleAssignment
        }

        # Granting permissions
        Write-Host "[+] Assigning $rolePropertyType to service principal: $SvcPrincipalId"
        if ($type -eq 'application') {
            # Process required permissions
            $resourceAccessObjects = @()
            Write-Host "[+] Creating Resource Access Object"
            foreach ($roleAssignment in $roleAssignments) {
                $ResourceAccessItem = [PSCustomObject]@{
                    principalId = $SvcPrincipalId
                    resourceId = $roleSvcPrincipalId
                    appRoleId = $roleAssignment.Id
                }
                $resourceAccessObjects += $ResourceAccessItem
            }

            foreach ($role in $resourceAccessObjects) {
                Write-Host "[+] Granting appRole to $SvcPrincipalId"
                Write-Host "  [>>] $role"
                $params = @{ 
                    "Method"  = "Post" 
                    "Uri"     = "https://graph.microsoft.com/v1.0/servicePrincipals/$SvcPrincipalId/appRoleAssignments"
                    "Body"    = $role | ConvertTo-Json -Compress -Depth 10
                    "Headers" = $Headers 
                }
                Invoke-Restmethod @params
            }
        }
        else {
            $body = @{
                clientId = $SvcPrincipalId
                consentType = "AllPrincipals"
                principalId = $null
                resourceId = $roleSvcPrincipalId
                scope = "$RequiredPermissions"
            }
    
            $params = @{
                "Method"  = "Post"
                "Uri"     = 'https://graph.microsoft.com/v1.0/oauth2PermissionGrants'
                "Body"    = $body | ConvertTo-Json -compress
                "Headers" = $Headers
            }
            Write-Host "[+] Granting OAuth permissions: $RequiredPermissions"
            Invoke-RestMethod @params
        }
    }
}