param utcValue string {
    metadata: {
      description: 'Returns the current (UTC) datetime value in the specified format. If no format is provided, the ISO 8601 (yyyyMMddTHHmmssZ) format is used'
    }
    default: utcNow()
  }
  param projectName string {
    metadata: {
      description: 'Specifies a project name that is used to generate the Event Hub name and the Namespace name.'
    }
  }
  param location string {
    metadata: {
      description: 'Specifies the Azure location for all resources.'
    }
    default: resourceGroup().location
  }
  param eventHubSku string {
    allowed: [
      'Basic'
      'Standard'
    ]
    metadata: {
      description: 'Specifies the messaging tier for service Bus namespace.'
    }
    default: 'Standard'
  }
  
  var uniqueNamespace = concat(projectName, uniqueString(resourceGroup().id, utcValue))
  var eventHubName_var = 'evh-${projectName}'
  var eventHubNamespaceName_var = 'evhns-${uniqueNamespace}'
  var defaultSASKeyName = 'RootManageSharedAccessKey'
  var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName_var, defaultSASKeyName)
  
  resource eventHubNamespaceName 'Microsoft.EventHub/namespaces@2017-04-01' = {
    name: eventHubNamespaceName_var
    location: location
    sku: {
      name: eventHubSku
      tier: eventHubSku
      capacity: 1
    }
    properties: {
      isAutoInflateEnabled: false
      maximumThroughputUnits: 0
    }
  }
  
  resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
    name: '${eventHubNamespaceName.name}/${eventHubName_var}'
    properties: {
      messageRetentionInDays: 7
      partitionCount: 1
    }
  }
  
  output EventHubName string = eventHubName_var
  output EventHubNamespace string = eventHubNamespaceName_var
  output NamespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
  output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey