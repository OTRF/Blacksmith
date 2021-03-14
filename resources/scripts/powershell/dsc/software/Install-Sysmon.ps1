 # Author: Roberto Rodriguez @Cyb3rWard0g
 configuration Install-Sysmon {
    param 
    ( 
        [string]$SysmonConfigUrl = "https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/configs/sysmon/sysmon.xml"
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        xRegistry SchUseStrongCrypto
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName = 'SchUseStrongCrypto'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        xRegistry SchUseStrongCrypto64
        {
            Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName = 'SchUseStrongCrypto'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        # ***** Download Sysmon Installer *****
        xRemoteFile DownloadSysmonInstaller
        {
            DestinationPath = "C:\ProgramData\Sysmon.zip"
            Uri = "https://download.sysinternals.com/files/Sysmon.zip"
            DependsOn = @("[xRegistry]SchUseStrongCrypto","[xRegistry]SchUseStrongCrypto64")
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
        xRegistry SysmonEula
        {
            Key = 'HKEY_USERS\S-1-5-18\Software\Sysinternals\System Monitor'
            ValueName = 'EulaAccepted';
            ValueType = 'DWORD'
            ValueData = '1'
            Ensure = 'Present'
            Force = $true
            DependsOn = @("[xArchive]UnzipSysmonInstaller","[xRemoteFile]DownloadSysmonConfig")
        }
        xScript InstallSysmon
        {
            SetScript =
            {
                # Installing Sysmon
                start-process -FilePath "C:\ProgramData\Sysmon\sysmon.exe" -ArgumentList @('-i','C:\ProgramData\sysmon.xml','-accepteula') -PassThru -NoNewWindow -ErrorAction Stop | Wait-Process

                # Set Sysmon to start automatically
                sc.exe config Sysmon start= auto

                # Setting Sysmon Channel Access permissions
                wevtutil set-log Microsoft-Windows-Sysmon/Operational /ca:'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)'
                #New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Sysmon/Operational" -Name "ChannelAccess" -PropertyType String -Value "O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)" -Force

                Restart-Service -Name Sysmon -Force
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
            DependsOn = '[xRegistry]SysmonEula'
        }
        xService Sysmon
        {
            Name = "Sysmon"
            State = "Running"
            DependsOn = '[xScript]InstallSysmon'
        }

    }
}