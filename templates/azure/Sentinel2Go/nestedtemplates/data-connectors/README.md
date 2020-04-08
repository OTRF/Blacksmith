# Azure Sentinel Data Connectors

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhunters-forge%2FBlacksmith%2Fazure%2Ftemplates%2Fazure%2FSentinel2Go%2Fnestedtemplates%2Fdata-connectors%2FallConnectors.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/> 
</a>
<br/>

The current kind of Data Connectors deployed via ARM templates in this project are of type [Microsoft.OperationsManagement/solutions](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationsmanagement/2015-11-01-preview/solutions) and [Microsoft.OperationalInsights/workspaces/dataSources](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/2015-11-01-preview/workspaces/datasources)


| Kind | Display Name | Description | type | Data Table |
|----|----|----|----|----|
| AmazonWebServicesCloudTrail | Amazon Web Services | Use the AWS connector to stream all your AWS CloudTrail events into Azure Sentinel. This connection process delegates access for Azure Sentinel to your AWS resource logs, creating a trust relationship between AWS CloudTrail and Azure Sentinel. This is accomplished on AWS by creating a role that gives permission to Azure Sentinel to access your AWS logs | Data Connector | AWSCloudTrail |
| AzureActivityLog | Azure Activity | Azure Activity Log is a subscription log that provides insight into subscription-level events that occur in Azure, including events from Azure Resource Manager operational data, service health events, write operations taken on the resources in your subscription, and the status of activities performed in Azure. | Data Source | AzureActivity |
| AzureSecurityCenter | Azure Security Center | This connector allows you stream your security alerts from Azure Security Center into Sentinel | Data Connector | SecurityAlert |
| DnsAnalytics| DNS | The DNS log connector allows you to easily connect your DNS analytic and audit logs with Azure Sentinel, and other related data, to improve investigation. | Solution | DnsEvents, DnsInventory |
| Office365 | Office 365 | The Office 365 activity log connector provides insight into ongoing user activities. You will get details of operations such as file downloads, access requests sent, changes to group events, set-mailbox and details of the user who performed the actions. | Data Connector | OfficeActivity |
| SecurityInsightsSecurityEventCollectionConfiguration | Security Events | You can stream all security events from the Windows Servers connected to your Azure Sentinel workspace. This connection enables you to view dashboards, create custom alerts, and improve investigation. | Data Source | SecurityEvent |
| WindowsFirewall | Windows Firewall | Windows Firewall is a Microsoft Windows application that filters information coming to your system from the Internet and blocking potentially harmful programs. The software blocks most programs from communicating through the firewall. | Solution | WindowsFirewall |