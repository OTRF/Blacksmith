param (
    [Parameter(Mandatory)]
    [String]$DomainFQDN,

    [Parameter(Mandatory)]
    [String]$AdminUserName,

    [Parameter(Mandatory)]
    [String]$AdminPassword,

    [Parameter(Mandatory)]
    [String]$AdfsUserName,

    [Parameter(Mandatory)]
    [String]$AdfsPassword
)

function Get-NetBIOSName {
    [OutputType([string])]
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length = $DomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length = 15
        }
        return $DomainFQDN.Substring(0, $length)
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0, 15)
        }
        else {
            return $DomainFQDN
        }
    }
}

$ADFSSiteName = "ADFS"
[String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
$AdminSecPW = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$AdminUserName", $AdminSecPW)
$AdfsSecPW = ConvertTo-SecureString $AdfsPassword -AsPlainText -Force
[System.Management.Automation.PSCredential]$AdfsSvcCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$AdfsUserName", $AdfsSecPW)

$cert = Get-ChildItem -Path "cert:\LocalMachine\My\" -DnsName "$DomainFQDN"

Import-Module ADFS
Install-AdfsFarm -CertificateThumbprint $cert.Thumbprint -FederationServiceName "$ADFSSiteName.$DomainFQDN" -FederationServiceDisplayName "Active Directory Federation Service" -ServiceAccountCredential $AdfsSvcCredsQualified -OverwriteConfiguration -Credential $DomainCreds

# ***** Idp-Initiated Sign On page (Disabled by default)*****
set-AdfsProperties -EnableIdPInitiatedSignonPage $true

# ***** Customize Landing Page *****
Set-AdfsGlobalWebContent -CompanyName "Open Threat Research"
Set-AdfsWebTheme -TargetName default -Illustration @{path="C:\ProgramData\otr.jpg"}
Set-AdfsGlobalWebContent -SignInPageDescriptionText "<p>Sign-in to the Open Threat Research Community and collaborate!</p>"

# ***** Enabling ADFS Verbose Auditing *****
<#
Get-AdfsProperties | Select Auditlevel

AuditLevel
----------
{Basic}
#>
Set-AdfsProperties -Auditlevel verbose
Restart-Service -Name adfssrv

& auditpol.exe /set /subcategory:"Application Generated" /failure:enable /success:enable

# ***** Enable AD FS Logging *****
<#
PS C:\Users\wardog.ADFS01> (Get-AdfsProperties).Loglevel
Errors
FailureAudits
Information
Verbose
SuccessAudits
Warnings
#>
Set-AdfsProperties -LogLevel ((Get-AdfsProperties).LogLevel+'SuccessAudits','FailureAudits')

#***** READY *****
# Browse to: https://adfs.blacksmith.local/adfs/ls/idpinitiatedsignon.aspx