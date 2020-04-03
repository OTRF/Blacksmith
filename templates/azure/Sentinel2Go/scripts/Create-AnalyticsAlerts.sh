#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Reference:
# https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-rest
# https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts/Security%20Event%20collection%20tier
# https://medium.com/@mauridb/calling-azure-rest-api-via-curl-eb10a06127
# https://oncletom.io/2016/pipelining-http/
# https://starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
# https://cameronnokes.com/blog/working-with-json-in-bash-using-jq/

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

# Install some additional libraries
apt install -y uuid-runtime

if [ -z "$RESOURCE_GROUP_NAME" ] || [ -z "$WORKSPACE_NAME" ]; then
    usage
else
    for row in $(curl -sS https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/templates/azure/Sentinel2Go/nestedtemplates/analytics-alerts/analyticsAlerts.json | jq -r '.[] | @base64'); do
        name=$(uuidgen)
        echo ${row} | base64 --decode | jq -r ${1} | az rest -m put -u "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE_NAME}/providers/Microsoft.SecurityInsights/alertRules/${name}?api-version=2019-01-01-preview" --body @-  --verbose
        sleep 1
    done
fi