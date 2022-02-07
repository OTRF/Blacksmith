# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

$ErrorActionPreference = "Stop"

# Firewall Changes
Write-Host "Allow ICMP Traffic through firewall"
& netsh advfirewall firewall add rule name="ALL ICMP V4" protocol=icmpv4:any,any dir=in action=allow

Write-Host "Enable WMI traffic through firewall"
& netsh advfirewall firewall set rule group="windows management instrumentation (wmi)" new enable=yes

Write-Host "Enable Inbound RPC Dynamic Ports"
# Reference:
# https://serverfault.com/questions/430705/how-do-i-allow-remote-iisreset-through-the-firewall-on-win-server-2008
# https://stackoverflow.com/questions/21092050/comexception-when-trying-to-get-application-pools-using-servermanager
# Local port: Dynamic RPC
# Remote port: ALL
# Protocol number: 6
# Executable: %windir%\\system32\\dllhost.exe
# Remote privilege: Administrator
& netsh advfirewall firewall add rule name="COM+ Remote Administration (All Programs)" dir=in action=allow description="" program="$Env:WinDir\system32\dllhost.exe" enable=yes localport=RPC protocol=tcp

Write-Host "Enable Explorer.exe Inbound (i.e. COM Method ShellWindows)"
& netsh advfirewall firewall add rule name="Windows Explorer UDP" dir=in action=allow description="" program="$Env:WinDir\explorer.exe" enable=yes localport=any protocol=udp remoteip=localsubnet
& netsh advfirewall firewall add rule name="Windows Explorer TCP" dir=in action=allow description="" program="$Env:WinDir\explorer.exe" enable=yes localport=any protocol=tcp remoteip=localsubnet

## Configured firewall to allow SMB
Write-Host "Enable File and Printer Sharing"
& netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes