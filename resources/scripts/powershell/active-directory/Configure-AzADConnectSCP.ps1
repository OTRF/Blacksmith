#
# Windows PowerShell script to configure the SCP for Hybrid Azure AD join
# The service connection point (SCP) is used by your devices to discover your Azure AD tenant information.
# If your devices are in different forets, each forest needs an SCP.
# Reference: https://docs.microsoft.com/en-us/azure/active-directory/devices/howto-hybrid-azure-ad-join

param([string]$Domain, [switch]$Help)

function funHelp()
{
     $helpTxt = @"

     NAME:        ConfigureSCP.ps1
     PURPOSE:     Configures the service connection point for Hybrid Azure AD join in the current forest
     REQUIREMENT: Must be run by an Enterprise Admin of the current forest

     PARAMETERS: 

        -Domain <NAME>  Specifies the Azure AD domain to use for device authentication
               If you are using federation to authenticate with Azure AD, enter a federated domain name.
               If you are not using federation, enter your primary *.onmicrosoft.com domain name.

        -Help           Prints the help file

     EXAMPLES:

     1. ConfigureSCP.ps1 -Domain contoso.com

     2. ConfigureSCP.ps1 -Domain contoso.onmicrosoft.com

"@
     $helpTxt
     exit 1
}

if ($Help)
{
     funHelp
}

if (-not($Domain))
{
     Write-Output "You must specify a value for -Domain"
     funhelp
}

Write-Output "Configuring the SCP for Hybrid Azure AD join in your Active Directory forest."

## Set variables
$azureADId = "azureADId:4006d304-c6df-477e-9013-34009024c45d"
$azureADName = "azureADName:" + $Domain
$keywords = "keywords"
$ldap = "LDAP://"
$rootDSE = New-Object System.DirectoryServices.DirectoryEntry($ldap + "RootDSE")
$configCN = $rootDSE.Properties["configurationNamingContext"][0].ToString()
$servicesCN = "CN=Services," + $configCN
$drcCN = "CN=Device Registration Configuration," + $servicesCN
$scpCN = "CN=62a0ff2e-97b9-4513-943f-0d221bd30080," + $drcCN

## Get/Create: CN=Device Registration Configuration,CN=Services
if ([System.DirectoryServices.DirectoryEntry]::Exists($ldap + $drcCN))
{
     $deDRC = New-Object System.DirectoryServices.DirectoryEntry($ldap + $drcCN)
}
else
{
     $de = New-Object System.DirectoryServices.DirectoryEntry($ldap + $servicesCN)
     $deDRC = $de.Children.Add("CN=Device Registration Configuration", "container")
     $deDRC.CommitChanges()
}

## Edit/Create: CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration,CN=Services
if ([System.DirectoryServices.DirectoryEntry]::Exists($ldap + $scpCN))
{
     $deSCP = New-Object System.DirectoryServices.DirectoryEntry($ldap + $scpCN)
     foreach ($value in $deSCP.Properties[$keywords].Value)
     {
          $deSCP.Properties[$keywords].Remove($value)
     }
     $deSCP.Properties[$keywords].Add($azureADName)
     $deSCP.Properties[$keywords].Add($azureADId)
     $deScp.CommitChanges()
}
else
{
     $deSCP = $deDRC.Children.Add("CN=62a0ff2e-97b9-4513-943f-0d221bd30080", "serviceConnectionPoint")
     $deSCP.Properties[$keywords].Add($azureADName)
     $deSCP.Properties[$keywords].Add($azureADId)
     $deScp.CommitChanges()
}

if ($Error)
{
     Write-Output "Configuration could not be completed."
     Write-Output $Error
}
else
{
     Write-Output "Configuration complete!"
}
