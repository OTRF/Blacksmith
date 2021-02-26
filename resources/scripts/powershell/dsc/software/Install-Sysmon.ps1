# Author: Roberto Rodriguez @Cyb3rWard0g
configuration Install-Sysmon {
    param 
    ( 
        [string]$SysmonConfigUrl = "https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/configs/sysmon/sysmon.xml"
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** Download Sysmon Installer *****
        xRemoteFile DownloadSysmonInstaller
        {
            DestinationPath = "C:\ProgramData\Sysmon.zip"
            Uri = "https://download.sysinternals.com/files/Sysmon.zip"
        }

        # ***** Unzip Sysmon Installer *****
        xArchive UnzipSysmonInstaller
        {
            Path = "C:\ProgramData\Sysmon.zip"
            Destination = "C:\ProgramData\Sysmon"
            Ensure = "Present"
            DependsOn = "[xRemoteFile]DownloadSysmonInstaller"
        }

        # ***** Download Sysmon Configuration *****
        xRemoteFile DownloadSysmonConfig
        {
            DestinationPath = "C:\ProgramData\sysmon.xml"
            Uri = $SysmonConfigUrl
        }
        # ***** Install Sysmon *****
        xScript InstallSysmon
        {
            SetScript = {
                # Installing Sysmon
                & C:\ProgramData\Sysmon\sysmon.exe -i C:\ProgramData\sysmon.xml -accepteula

                # Set Sysmon to start automatically
                & sc.exe config Sysmon start= auto

                # Setting Sysmon Channel Access permissions
                write-Host "Granting the Network Service account READ access to the Security event log.."
                wevtutil set-log Microsoft-Windows-Sysmon/Operational /ca:'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)'
                #New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Sysmon/Operational" -Name "ChannelAccess" -PropertyType String -Value "O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)" -Force

                write-Host "[+] Restarting Sysmon .."
                Restart-Service -Name Sysmon -Force

                write-Host "  [*] Verifying if Sysmon is running.."
                $s = Get-Service -Name Sysmon
                while ($s.Status -ne 'Running') { Start-Service Sysmon; Start-Sleep 3 }
                Start-Sleep 5
                write-Host "  [*] Sysmon is running.."
            }
            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn = @("[xArchive]UnzipSysmonInstaller","[xRemoteFile]DownloadSysmonConfig")
        }
    }
}