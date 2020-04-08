# Azure Sentinel Data Connectors

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhunters-forge%2FBlacksmith%2Fazure%2Ftemplates%2Fazure%2FSentinel2Go%2Fnestedtemplates%2Fdata-connectors%2FallConnectors.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/> 
</a>
<br/>
<br/>

The current kind of Data Connectors deployed via ARM templates in this project are of type [Microsoft.OperationsManagement/solutions](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationsmanagement/2015-11-01-preview/solutions) and [Microsoft.OperationalInsights/workspaces/dataSources](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/2015-11-01-preview/workspaces/datasources)


| Display Name | Description | Data Table | Type | Kind |
|----|----|----|----|----|
| Amazon Web Services | Use the AWS connector to stream all your AWS CloudTrail events into Azure Sentinel. This connection process delegates access for Azure Sentinel to your AWS resource logs, creating a trust relationship between AWS CloudTrail and Azure Sentinel. | AmazonWebServicesCloudTrail | Data Connector | AWSCloudTrail |
| Azure Activity | This connector allows you to get insight into subscription-level events that occur in Azure, including events from Azure Resource Manager operational data, service health events, write operations taken on the resources in your subscription, and the status of activities performed in Azure. | AzureActivity | Data Source | AzureActivityLog |
| Azure Security Center | This connector allows you stream your security alerts from Azure Security Center into Sentinel | SecurityAlert | Data Connector | AzureSecurityCenter |
| DNS | The DNS log connector allows you to easily connect your DNS analytic and audit logs with Azure Sentinel, and other related data, to improve investigation. | DnsEvents, DnsInventory | Solution | DnsAnalytics |
| Office 365 | The Office 365 activity log connector provides insight into ongoing user activities. You will get details of operations such as file downloads, access requests sent, changes to group events, set-mailbox and details of the user who performed the actions. |  OfficeActivity | Data Connector | Office365 |
| Security Events | This connector allows you to collect Windows event logs from the Windows Security Auditing event provider. | SecurityEvent | Data Source | SecurityInsightsSecurityEventCollectionConfiguration |
| Windows Firewall | Windows Firewall is a Microsoft Windows application that filters information coming to your system from the Internet and blocking potentially harmful programs. The software blocks most programs from communicating through the firewall. | WindowsFirewall | Solution | WindowsFirewall |