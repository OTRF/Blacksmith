# Windows 10 + PAN FW

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhunters-forge%2FBlacksmith%2Fmaster%2Ftemplates%2Fazure%2FWin10-PAN-FW%2Fazuredeploy.json) [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fhunters-forge%2FBlacksmith%2Fmaster%2Ftemplates%2Fazure%2FWin10-PAN-FW%2Fazuredeploy.json)

## Accept MarketPlace PAN Terms

Bundle2: Comes with IDS Threat Category


```
az vm image list --all --publisher paloaltonetworks --offer vmseries1 --sku bundle2 --query '[0].urn'
```

```
az vm image terms accept --urn paloaltonetworks:vmseries1:bundle2:7.1.1
```