# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
function Get-CertSigningReq {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FriendlyName,

        [Parameter(Mandatory=$true)]
        [string]$Description,

        [Parameter(Mandatory=$true)]
        [string]$SubjectCommonName,

        [Parameter(Mandatory=$false)]
        [string]$SubjectOrganizationUnit,

        [Parameter(Mandatory=$false)]
        [string]$SubjectOrganization,

        [Parameter(Mandatory=$false)]
        [string]$SubjectCountry,

        [Parameter(Mandatory=$false)]
        [string]$SubjectState,

        [Parameter(Mandatory=$false)]
        [string]$SubjectLocality,

        [Parameter(Mandatory=$false)]
        [String[]]$SubjectAltNames,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Microsoft RSA SChannel Cryptographic Provider','Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider')]
        [string]$PKProviderName = "Microsoft RSA SChannel Cryptographic Provider",

        [Parameter(Mandatory=$false)]
        [string]$PKKeySize = 2048,

        [Parameter(Mandatory=$false)]
        [ValidateSet('True','False')]
        [string]$PKMakeExportable = 'True',

        [Parameter(Mandatory=$true)]
        [string]$CertFilePath
    )

    $SubjectString = @("CN=$SubjectCommonName")
    if ($SubjectOrganizationUnit)
    {
        $SubjectString += "OU=$SubjectOrganizationUnit"
    }
    if ($SubjectOrganization)
    {
        $SubjectString += "O=$SubjectOrganization"
    }
    if ($SubjectLocality)
    {
        $SubjectString += "L=$SubjectLocality"
    }
    if ($SubjectState)
    {
        $SubjectString += "S=$SubjectState"
    }
    if ($SubjectCountry)
    {
        $SubjectString += "C=$SubjectCountry"
    }
    $SubjectString = $SubjectString -join ","

    $CertReqINF = @"
[Version]
Signature= '`$Windows NT$'

[NewRequest]
Subject = `"$SubjectString`"
KeySpec = 1 ; AT_KEYEXCHANGE
KeyLength = $PKKeySize
Exportable = $PKMakeExportable
ExportableEncrypted = $PKMakeExportable
MachineKeySet = True
ProviderName = $PKProviderName
RequestType = PKCS10
KeyUsage = 0xa0; Digital Signature, Key Encipherment
FriendlyName = $FriendlyName

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1
"@

    if ($SubjectAltNames){
        $CertReqINF = $CertReqINF + "`n`n[Extensions]`n2.5.29.17 = `"{text}`""
        foreach ($altName in $SubjectAltNames)
        {
            $CertReqINF = $CertReqINF + "`n_continue_ = `"dns=$altName&`""
        }
    }

    # **** Request INF *****
    Write-Host "[+] Request INF String:"
    $CertReqINF

    $tmpFile = [System.IO.Path]::GetTempFileName()
    $CertReqINF | Out-File $tmpFile
    
    & certreq.exe -new $tmpFile $CertFilePath

    #***** Remove Temp File *****
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
}