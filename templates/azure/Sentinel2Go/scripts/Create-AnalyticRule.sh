#!/bin/bash

# Reference:
# https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-rest
# https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts/Security%20Event%20collection%20tier
# https://medium.com/@mauridb/calling-azure-rest-api-via-curl-eb10a06127

set -e

script_name=$0

usage(){
  echo "Invalid option: -$OPTARG"
  echo "Usage: ${script_name} -r [Resource group name]"
  echo "                      -w [Log Analytics Workspace Name]"
  exit 1
}

while getopts r:w:h opt; do
    case "$opt" in
        r)  RESOURCE_GROUP_NAME=$OPTARG;;
        w)  WORKSPACE_NAME=$OPTARG;;
        h) #Show help
            usage
            exit 2
            ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

if [ -z "$RESOURCE_GROUP_NAME" ] || [ -z "$WORKSPACE_NAME" ]; then
    usage
else
    az rest -m put -u "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE_NAME}/providers/Microsoft.SecurityInsights/alertRules/73e01a99-5cd7-4139-a149-9f2736ff2ab5?api-version=2019-01-01-preview" --body '
    {
        "kind": "Scheduled",
        "properties": {
            "alertRuleTemplateName": null,
            "description": "Basic internal rule to detect binary named sandcat.exe",
            "displayName": "Sandcat Payload",
            "enabled": true,
            "incidentConfiguration": {
                "createIncident": true,
                "groupingConfiguration": {
                    "enabled": false,
                    "entitiesMatchingMethod": "All",
                    "groupByEntities": [],
                    "lookbackDuration": "PT5H",
                    "reopenClosedIncident": false
                }
            },
            "query": "SecurityEvent\n| where EventID == \"4688\" and CommandLine contains \"sandcat.exe\"",
            "queryFrequency": "PT5M",
            "queryPeriod": "PT5M",
            "queryResultsAggregationSettings": {
                "aggregationKind": "SingleAlert"
            },
            "severity": "High",
            "suppressionDuration": "PT5H",
            "suppressionEnabled": false,
            "tactics": [
                "Execution"
            ],
            "triggerOperator": "Equal",
            "triggerThreshold": 1
        }
    }
    ' --verbose
fi