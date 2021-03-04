# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
configuration Import-PfxCert 
{ 
   param 
   (
        [Parameter()]
        [System.String]$PfxCertPath,

        [Parameter()]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [System.String]$Location = 'LocalMachine',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]$Store = 'My',

        [Parameter()]
        [System.Boolean]$Exportable = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]$PfxCertCreds
    ) 
    
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    Node localhost
    {
        LocalConfigurationManager 
        {
            ActionAfterReboot   = 'ContinueConfiguration'
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        xScript ImportPFX
        {
            SetScript = 
            {
                $certFilepath = Get-ChildItem -Path $using:pfxCertPath
                $certStore =  'Cert:' | Join-Path -ChildPath $using:Location | Join-Path -ChildPath $using:Store

                if ($using:Exportable -eq $True)
                {
                    Import-PfxCertificate -Exportable -CertStoreLocation $certStore -FilePath $certFilepath.FullName -Password $using:PfxCertCreds.Password
                }
                else
                {
                    Import-PfxCertificate -CertStoreLocation $certStore -FilePath $certFilepath.FullName -Password $using:PfxCertCreds.Password
                }
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
        }
    }
}