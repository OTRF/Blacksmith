# Author: Roberto Rodriguez @Cyb3rWard0g
# Description: A scheduled task that triggers every 10 minutes and sends a GET request to DuckDuckGo and KeyBase Tor services"
$action=New-ScheduledTaskAction -Execute "$PSHome\powershell.exe" -Argument "@('3g2up14pq6kufc4m.onion.to','fncuwbiisyh6ak3i.onion.ws') | ForEach-Object { Invoke-WebRequest -Uri $_}"
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 10) `
    -RepetitionDuration (New-TimeSpan -Days (365 * 20))
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "TestMDEWebRequest" -Description "Testing Web Requests to trigger MDE"