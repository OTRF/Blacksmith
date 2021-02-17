# Windows 10 + Windows Server (Active Directory) + Windows Server (Active Directory Federation Services)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FOTRF%2FBlacksmith%2Fmaster%2Ftemplates%2Fazure%2FWin10-AD-ADFS%2Fazuredeploy.json) [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FOTRF%2FBlacksmith%2Fmaster%2Ftemplates%2Fazure%2FWin10-AD-ADFS%2Fazuredeploy.json)

## Resources

* One Windows Active Directory domain (One Domain Controller)
    * Active Directory Certificate Services (AD CS) Certification Authority (CA) role service enabled
    * Enterprise Root Certificate Authority created
    * ADFS Site Certificate created
    * ADFS Signing Certificate created
    * ADFS Decryption Certificate created
    * SMB share C:\Setup created to distribute ADFS certificates (.CER & .PFX files)
        * Full Access: Domain Admins & Domain Computers
        * Read Access: Authenticated Users
    * ADFS service account created
    * Azure Active Directory (AAD) Connect installed
* One Windows Active Directory Federation Services (ADFS) server
    * Active Directory Federation Services Role Service enabled
    * ADFS .pfx certificate retrieved from DC C:\Setup share
    * ADFS farm installed
    * Idp-Initiated Sign On page enabled
    * ADFS WebContent customized (Title, Web Theme, SignIn description)
    * ADFS Logging (SuccessAudits & FailureAudits) enabled
    * ADFS Auditing
        * Level: Verbose
        * Auditpol command: auditpol.exe /set /subcategory:"Application Generated" /failure:enable /success:enable
    * Azure Active Directory (AAD) Connect installed
* Windows 10 Workstations (Max. 10)
* [OPTIONAL] Windows [Microsoft Monitoring Agent](https://docs.microsoft.com/en-us/services-hub/health/mma-setup) installed
    * It connects to the Log Analytics workspace defined in the template.
* [OPTIONAL] Sysmon
    * [Sysmon Config](https://github.com/OTRF/Blacksmith/blob/master/resources/configs/sysmon/sysmon.xml)