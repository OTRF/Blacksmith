# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Reference:
# https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-rest
# https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts/Security%20Event%20collection%20tier
# https://medium.com/@mauridb/calling-azure-rest-api-via-curl-eb10a06127

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName,

    [Parameter(Mandatory=$true)]
    [string]$CollectionTier
)

az rest -m put -u "https://management.azure.com/subscriptions/{subscriptionId}/resourcegroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/Workspaces/$WorkspaceName/datasources/SecurityEventCollectionConfiguration?api-version=2015-11-01-preview" --body "
{
    \"kind\": \"SecurityEventCollectionConfiguration\",
    \"properties\": {
        \"Tier\": \"$CollectionTier",
        \"TierSetMethod\": \"Custom\"
    }
}
" --verbose