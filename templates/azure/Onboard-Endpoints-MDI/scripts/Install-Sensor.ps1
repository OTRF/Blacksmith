# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string] $AccessKey
)

Expand-Archive -path "Azure ATP Sensor Setup.zip" -DestinationPath "Azure ATP Sensor Setup"
Start-Process -FilePath "Azure ATP Sensor Setup\Azure ATP Sensor Setup.exe" -ArgumentList @("/quiet","NetFrameworkCommandLineArguments=/q","AccessKey=$AccessKey") -RedirectStandardOutput "MDIStandardOutput.txt" -RedirectStandardError "MDIStandardError.txt" -NoNewWindow -Wait