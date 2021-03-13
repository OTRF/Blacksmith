# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3

configuration Install-AADConnect {
    Import-DscResource -ModuleName xPSDesiredStateConfiguration, ComputerManagementDsc

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** Download AADConnect *****
        xRemoteFile DownloadAADConnect {
            DestinationPath = "C:\ProgramData\AzureADConnect.msi"
            Uri = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
        }

        # ***** Install AADConnect *****
        xScript InstallAADConnect
        {
            # reference: https://github.com/pthoor/AzureARMTemplates/blob/ddd09734a3817e459d3dbfb41fc96c9b011e0205/ADFS%20Lab/DSC/adDSC/adDSCConfiguration.ps1
            SetScript = {
                $exe="$env:SystemRoot\system32\msiexec.exe"
                $MSIPath = "C:\ProgramData\AzureADConnect.msi"

                Invoke-Expression "& `"$exe`" /i $MSIPath /qn /passive /forcerestart"
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
            DependsOn = "[xRemoteFile]DownloadAADConnect"
        }

        PendingReboot RebootOnSignalFromAADConnect
        {
            Name        = 'RebootOnSignalFromAADConnect'
            DependsOn   = "[xScript]InstallAADConnect"
        }

        xService AWDS
        {
            Name = "ADWS"
            State = "Running"
            DependsOn = '[PendingReboot]RebootOnSignalFromAADConnect'
        }
    }
}