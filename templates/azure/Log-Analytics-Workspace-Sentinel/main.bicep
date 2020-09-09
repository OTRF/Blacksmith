param utcValue string {
    default: utcNow()
    metadata: {
        description: 'Returns the current (UTC) datetime value in the specified format. If no format is provided, the ISO 8601 (yyyyMMddTHHmmssZ) format is used'
    }
}
param workspaceName string {
    metadata: {
        description: 'Name for the Log Analytics workspace used to aggregate data.'
    }
}
param pricingTier string {
    allowed: [
        'PerGB2018'
        'Free'
        'Standalone'
        'PerNode'
        'Standard'
        'Premium'
    ]
    default: 'PerGB2018'
    metadata: {
        description: 'Pricing tier: pergb2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium) which are not available to all customers.'
    }
}
param dataRetention int {
    default: 30
    minValue: 7
    maxValue: 30
    metadata: {
        description: 'Number of days of retention. Workspaces in the legacy Free pricing tier can only have 7 days.'
    }
}
param immediatePurgeDataOn30Days bool {
    default: true
    metadata: {
        description: 'If set to true when changing retention to 30 days, older data will be immediately deleted. Use this with extreme caution. This only applies when retention is being set to 30 days.'
    }
}
param location string {
    default: resourceGroup().location
    metadata: {
        description: 'Location for all resources.'
    }
}

var uniqueWorkspace = concat('log-', workspaceName, uniqueString(resourceGroup().id, utcValue))

resource workspace 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: uniqueWorkspace // must be globally unique
  location: location
  properties: {
    sku: {
        name: pricingTier
    }
    retentionInDays: dataRetention
    features: {
        immediatePurgeDataOn30Days: immediatePurgeDataOn30Days
    }
  }
}

resource azureSentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
    name: concat('SecurityInsights(',workspace.name,')') // Implicit Dependency
    location: location
    properties: {
        workspaceResourceId: workspace.id
    }
    plan: {
        name: concat('SecurityInsights(',workspace.name,')') // Implicit Dependency
        product: 'OMSGallery/SecurityInsights'
        publisher: 'Microsoft'
        promotionCode: ''
    }
}

output workspaceNameOutput string = uniqueWorkspace
output workspaceIdOutput string = reference(workspace.id, workspace.apiVersion).customerId
output workspacekeyOutput string = listKeys(workspace.id, workspace.apiVersion).primarySharedKey