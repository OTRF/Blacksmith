# Windows 10 + Palo Alto Networks VM-Series Firewall

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FOTRF%2FBlacksmith%2Fmaster%2Ftemplates%2Fazure%2FWin10-PAN-FW%2Fazuredeploy.json) [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FOTRF%2FBlacksmith%2Fmaster%2Ftemplates%2Fazure%2FWin10-PAN-FW%2Fazuredeploy.json)

## VM-Series Licensing

For both AWS and Microsoft Azure, the licensing options are bring your own license (BYOL) and pay as you go/consumption-based (PAYG) subscriptions.

* **BYOL**: Any one of the VM-Series models, along with the associated Subscriptions and Support, are purchased via normal Palo Alto Networks channels and then deployed through your AWS or Azure management console.
* **PAYG (Pay-as-you-go)**: Purchase the VM-Series and select Subscriptions and Premium Support as an hourly subscription bundle from the AWS Marketplace.
    * **Bundle 1 contents**: VM-300 firewall license, Threat Prevention Subscription (inclusive of IPS, AV, Malware prevention) and Premium Support.
    * **Bundle 2 contents**: VM-300 firewall license, Threat Prevention (inclusive of IPS, AV, Malware prevention), WildFire™ threat intelligence service, URL Filtering, GlobalProtect Subscriptions and Premium Support.

## Accept Azure VM Marketplace Terms (MUST DO)

* The Palo Alto Networks (PAN) VM-Series Firewall is deployed from Azure Marketplace. You need to accept the legal terms to use the VM.
* **Make sure you run the commands below before deploying this template**
* You can do it locally via [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) or via the [Azure Clould Shell](https://shell.azure.com/). 

Look for the PAN VM-Series Firewall you are deploying:

```
az vm image list --all --publisher paloaltonetworks --offer vmseries1 --sku bundle2 --query '[0].urn'
```

Accept terms:

```
az vm image terms accept --urn paloaltonetworks:vmseries1:bundle2:7.1.1
```