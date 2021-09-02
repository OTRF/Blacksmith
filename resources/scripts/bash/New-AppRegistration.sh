# Registering a new Azure AD Application
registeredApp=$(az ad app list --query "[?displayName=='$Name']" --all | jq   .[0])
echo "$registeredApp"
if [[ $registeredApp != null ]]; then
    echo "[!] Azure AD application $Name already exists!"
else
    echo "[+] Registering new Azure AD application: $Name"
    if [[ $NativeApp ]]; then
        registeredApp=$(az ad app create --display-name $Name --native-app)
    else 
        registeredApp=$(az ad app create --display-name $Name)
    fi
    sleep 15
fi
appId=$(echo $registeredApp|jq -r .appId)
objectId=$(echo $registeredApp|jq -r .objectId)
echo "Application ID: $appId"
echo "Object ID: $objectId"
  
if [[ $IdentifierUris ]]; then
    echo "[+] Updating $Name application: Adding unique identifier URIs that Azure AD can use for this app"
    az ad app update --id $appId --identifier-uris $IdentifierUris 
fi
if [[ $ReplyUrls ]]; then
    echo "[+] Updating $Name application: Adding URIs to which Azure AD will redirect in response to an OAuth 2.0 request"
    az ad app update --id $appId --reply-urls $ReplyUrls
fi

# Creating the new Azure AD application service principal
spExists=$(az ad sp list --query "[?appDisplayName=='$Name']" --all | jq .[0])
if [[ $spExists != null ]]; then
    echo "[!] Azure AD application $Name already has a service principal"
else 
    echo "[+] Creating Azure AD service principal for $Name application"
    az ad sp create --id $appId

    # Sleep
    sleep 15
fi

#Add credentials to application
if [[ $AddSecret ]]; then
    echo "[+] Getting MS Graph access token with current security context"
    token=$(az account get-access-token --resource-type ms-graph --query accessToken --output tsv)
    echo "Using the following MS Graph token: $token"
    body=$(echo '"CloudKatanaSecret"'|jq -c '{passwordCredential:{displayName:.}}')
    url="https://graph.microsoft.com/v1.0/applications/$objectId/addPassword"
    credentials=$(curl $url -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d $body)
    if [[ ! $credentials ]]; then
        >&2 echo "Error adding credentials to $Name"
        exit 1
    fi
        
    echo "[+] Extracting secret text from results. Save it for future operations"
    secret=$(echo $credentials | jq -r .secretText)
fi

if [[ $DisableImplicitGrantFlowOAuth2 ]]; then
    echo "[+] Updating $Name application: Disabling implicit grant flow for OAuth2"
    az ad app update --id $appId --set oauth2AllowIdTokenImplicitFlow=false *>&1
fi

if [[ $UseV2AccessTokens ]]; then
    # Set application to use V2 access tokens
    body='{"api":{"requestedAccessTokenVersion":"2"}}'
    echo "[+] Updating $Name application: Setting application to use V2 access tokens"
    az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/$objectId" --body "$body" --headers "Content-Type=application/json"
fi

if [[ $RequireAssignedRole ]]; then
    echo "[+] Updating $Name application: Setting application to require users being assigned a role "
    az ad sp update --id $appId --set appRoleAssignmentRequired=true
    sleep 10
fi

if [[ $assignAppRoleToUser ]]; then
    echo "[+] Granting app role assignment to $assignAppRoleToUser "
    appSp=$(az ad sp show --id $appId)
    spObjectId=$(echo $appSp|jq -r .objectId)
    principalId=$(az ad user show --id $assignAppRoleToUser --query 'objectId' -o tsv)
    emptyGuid='00000000-0000-0000-0000-000000000000'
    Body="{\"appRoleId\": \"$emptyGuid\", \"principalId\": \"$principalId\", \"resourceId\": \"$spObjectId\"}"
    existingRole=$(az rest --method get --uri "https://graph.microsoft.com/v1.0/users/$assignAppRoleToUser/appRoleAssignments" --headers "Content-Type=application/json"|jq ".value|.[]|select(.resourceDisplayName==\"$Name\")")
	if [[ $existingRole == null ]]; then
        AssignAppRoleResult=$(az rest --method post --uri "https://graph.microsoft.com/v1.0/users/$assignAppRoleToUser/appRoleAssignments" --body "$Body" --headers "Content-Type=application/json")
        if [[ !$AssignAppRoleResult ]]; then
            >&2 echo "Error granting app role assignment to user $assignAppRoleToUser"
            exit 1
        fi
	fi
fi
echo 1| jq "{appName:\"$Name\", appId:\"$appId\", secretName:\"CloudKatanaSecret\", secretText:\"$secret\"}"> $AZ_SCRIPTS_OUTPUT_PATH