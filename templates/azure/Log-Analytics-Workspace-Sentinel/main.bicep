param utcValue string {
    metadata: {
      description: 'Returns the current (UTC) datetime value in the specified format. If no format is provided, the ISO 8601 (yyyyMMddTHHmmssZ) format is used'
    }
    default: utcNow()
  }
  param workspaceName string {
    metadata: {
      description: 'Name for the Log Analytics workspace used to aggregate data'
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
    metadata: {
      description: 'Pricing tier: pergb2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium) which are not available to all customers.'
    }
    default: 'PerGB2018'
  }
  param dataRetention int {
    minValue: 7
    maxValue: 730
    metadata: {
      description: 'Number of days of retention. Workspaces in the legacy Free pricing tier can only have 7 days.'
    }
    default: 30
  }
  param immediatePurgeDataOn30Days bool {
    metadata: {
      description: 'If set to true when changing retention to 30 days, older data will be immediately deleted. Use this with extreme caution. This only applies when retention is being set to 30 days.'
    }
    default: true
  }
  param location string {
    metadata: {
      description: 'Location for all resources.'
    }
    default: resourceGroup().location
  }
  
  var uniqueWorkspace_var = 'log-${workspaceName}${uniqueString(resourceGroup().id, utcValue)}'
  
  resource uniqueWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
    name: uniqueWorkspace_var
    location: location
    properties: {
      retentionInDays: dataRetention
      features: {
        immediatePurgeDataOn30Days: immediatePurgeDataOn30Days
      }
      sku: {
        name: pricingTier
      }
    }
  }
  
  resource SecurityInsights_uniqueWorkspace 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
    name: 'SecurityInsights(${uniqueWorkspace_var})'
    location: location
    properties: {
      workspaceResourceId: uniqueWorkspace.id
    }
    plan: {
      name: 'SecurityInsights(${uniqueWorkspace_var})'
      product: 'OMSGallery/SecurityInsights'
      publisher: 'Microsoft'
      promotionCode: ''
    }
  }
  
  output workspaceName_output string = uniqueWorkspace_var
  output workspaceIdOutput string = reference(uniqueWorkspace.id, '2015-11-01-preview').customerId
  output workspaceKeyOutput string = listKeys(uniqueWorkspace.id, '2015-11-01-preview').primarySharedKey