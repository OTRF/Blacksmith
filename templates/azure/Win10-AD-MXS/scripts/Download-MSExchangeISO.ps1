# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('MXS2016-x64-CU19-KB4588884','MXS2016-x64-CU18-KB4571788','MXS2016-x64-CU17-KB4556414','MXS2016-x64-CU16-KB4537678','MXS2016-x64-CU15-KB4522150','MXS2016-x64-CU14-KB4514140','MXS2016-x64-CU13-KB4488406')]
    [string] $MXSRelease = 'MXS2016-x64-CU19-KB4588884',

    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if( -Not ($_ | Test-Path -PathType Container) ){
            throw "Folder does not exist"
        }
        return $true
    })]
    [System.IO.FileInfo]$MXSISODirectory
)

# Reference: https://docs.microsoft.com/en-us/exchange/new-features/build-numbers-and-release-dates?view=exchserver-2019&WT.mc_id=M365-MVP-5003086
$MXSReleaseDownloadUri = Switch ($MXSRelease) {
    'MXS2016-x64-CU19-KB4588884' { 'https://download.microsoft.com/download/a/8/4/a84c8458-c924-4e6d-a19b-be65848c0fe3/ExchangeServer2016-x64-CU19.ISO' }
    'MXS2016-x64-CU18-KB4571788' { 'https://download.microsoft.com/download/d/2/3/d23b113b-9634-4456-acba-1f7b0ce22b0e/ExchangeServer2016-x64-cu18.iso' }
    'MXS2016-x64-CU17-KB4556414' { 'https://download.microsoft.com/download/0/5/f/05fbbfff-8316-4d12-a59d-80b3c56e4d81/ExchangeServer2016-x64-cu17.iso' }
    'MXS2016-x64-CU16-KB4537678' { 'https://download.microsoft.com/download/b/e/d/bed20ad6-a4cb-4a6c-b744-354b3fed6a98/ExchangeServer2016-x64-CU16.ISO' }
    'MXS2016-x64-CU15-KB4522150' { 'https://download.microsoft.com/download/5/6/6/566de1bf-336a-4662-841c-98ef4e2c30bf/ExchangeServer2016-x64-CU15.ISO' }
    'MXS2016-x64-CU14-KB4514140' { 'https://download.microsoft.com/download/f/4/e/f4e4b3a0-925b-4eff-8cc7-8b5932d75b49/ExchangeServer2016-x64-cu14.iso' }
    'MXS2016-x64-CU13-KB4488406' { 'https://download.microsoft.com/download/5/9/6/59681DAE-AB62-4854-8DEC-CA25FFEFE3B3/ExchangeServer2016-x64-cu13.iso' }
}

################
# Download ISO #
################

# Initializing Web Client
$wc = new-object System.Net.WebClient

$request = [System.Net.WebRequest]::Create($MXSReleaseDownloadUri)
$response = $request.GetResponse()
$totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
$OutputFile = [System.IO.Path]::GetFileName($response.ResponseUri)
$response.Close()

$OutputFilePath = Join-Path $MXSISODirectory $OutputFile
if (Test-Path $OutputFilePath)
{ 
    Write-host "[!] $OutputFilePath already exist"
}
else 
{
    # Download if it does not exists
    write-Host "[*] Downloading" $OutputFile "From" $MXSReleaseDownloadUri
    $maxAttempts = 5
    $attemptCount = 0
    Do {
        $attemptCount++
        Write-host "  [+] Attempt $attemptCount out of $maxAttempts.."
        $wc.DownloadFile($MXSReleaseDownloadUri, $OutputFilePath)
    } while (((Test-Path $OutputFilePath) -eq $false) -and ($attemptCount -le $maxAttempts))

    # If for some reason, a file does not exists, STOP. Something went wrong..
    if (!(Test-Path $OutputFilePath)) { Write-Error "$OutputFilePath does not exist" -ErrorAction Stop } 
}