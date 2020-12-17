param (
    [Parameter(Mandatory)]
    [String]$DomainFQDN,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$AdminCreds,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$AdfsSvcCreds
)

$ADFSSiteName = "ADFS"
[String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
[System.Management.Automation.PSCredential] $AdfsSvcCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdfsSvcCreds.UserName)", $AdfsSvcCreds.Password)

$cert = Get-ChildItem -Path "cert:\LocalMachine\My\" -DnsName "$ADFSSiteName.$DomainFQDN"
Install-AdfsFarm -CertificateThumbprint $cert.Thumbprint -FederationServiceName "$ADFSSiteName.$DomainFQDN" -FederationServiceDisplayName "Active Directory Federation Service" -ServiceAccountCredential $AdfsSvcCredsQualified -OverwriteConfiguration -Credential $DomainCreds

# ***** Idp-Initiated Sign On page (Disabled by default)*****
set-AdfsProperties -EnableIdPInitiatedSignonPage $true

# ***** Customize Landing Page *****
Set-AdfsGlobalWebContent -CompanyName "Open Threat Research"
Set-AdfsWebTheme -TargetName default -Illustration @{path="C:\ProgramData\otr.jpg"}
Set-AdfsGlobalWebContent -SignInPageDescriptionTextt "<p>Sign-in to the Open Threat Research Community and collaborate!</p>"

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