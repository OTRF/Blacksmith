 # Author: Roberto Rodriguez @Cyb3rWard0g
 # https://docs.microsoft.com/en-us/azure/active-directory/hybrid/reference-connect-tls-enforcement

 configuration Enable-TLS12 {
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
   
    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** SchUseStrongCrypto & SystemDefaultTlsVersions *****
        xRegistry SchUseStrongCrypto64
        {
            Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName = 'SchUseStrongCrypto'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        xRegistry SystemDefaultTlsVersions64
        {
            Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName = 'SystemDefaultTlsVersions'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        xRegistry SchUseStrongCrypto
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName = 'SchUseStrongCrypto'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        xRegistry SystemDefaultTlsVersions
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName = 'SystemDefaultTlsVersions'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        # ***** TLS 1.2 Server *****
        xRegistry TLSServerEnabled
        {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
            ValueName = 'Enabled'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        xRegistry TLSServerDisabledByDefault
        {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
            ValueName = 'DisabledByDefault'
            ValueType = 'Dword'
            ValueData =  '0'
            Ensure = 'Present'
        }

        # ***** TLS 1.2 Client *****
        xRegistry TLSClientEnabled
        {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
            ValueName = 'Enabled'
            ValueType = 'Dword'
            ValueData =  '1'
            Ensure = 'Present'
        }

        xRegistry TLSClientDisabledByDefault
        {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
            ValueName = 'DisabledByDefault'
            ValueType = 'Dword'
            ValueData =  '0'
            Ensure = 'Present'
        }
    }
}