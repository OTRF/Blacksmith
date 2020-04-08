# Azure Sentinel Data Connectors

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhunters-forge%2FBlacksmith%2Fazure%2Ftemplates%2Fazure%2FSentinel2Go%2Fnestedtemplates%2Fdata-connectors%2FallConnectors.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/> 
</a>
<br/>
<br/>

Current Data Connectors deployed via ARM templates:

| Name | Display Name | Description | Data Source / Solution | Data Table |
|----|----|----|----|----|
| AzureActivityLog | Azure Activity | Azure Activity Log is a subscription log that provides insight into subscription-level events that occur in Azure, including events from Azure Resource Manager operational data, service health events, write operations taken on the resources in your subscription, and the status of activities performed in Azure. | Data Source | AzureActivity |
| DnsAnalytics| DNS | The DNS log connector allows you to easily connect your DNS analytic and audit logs with Azure Sentinel, and other related data, to improve investigation. | Solution | DnsEvents, DnsInventory |
| SecurityEvents | Security Events | You can stream all security events from the Windows Servers connected to your Azure Sentinel workspace. This connection enables you to view dashboards, create custom alerts, and improve investigation. | Data Source | Data Table | SecurityEvent |
| WindowsFirewall | Windows Firewall | Windows Firewall is a Microsoft Windows application that filters information coming to your system from the Internet and blocking potentially harmful programs. The software blocks most programs from communicating through the firewall. | Solution | WindowsFirewall |