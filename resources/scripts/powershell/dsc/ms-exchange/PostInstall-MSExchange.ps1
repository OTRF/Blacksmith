# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3

configuration PostInstall-MSExchange
{ 
   param 
   (
        [Parameter(Mandatory)]
        [String]$DomainFQDN,
        
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds
    ) 
    
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $ComputerName = Get-Content env:computername

    Node localhost
    {
        LocalConfigurationManager 
        {
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }
        
        # ##################################
        # Post Installation Configurations #
        # ##################################

        # Enable audit logging
        # Reference:
        # https://docs.microsoft.com/en-us/exchange/policy-and-compliance/mailbox-audit-logging/enable-or-disable?view=exchserver-2016#enable-or-disable-mailbox-audit-logging
        # https://docs.microsoft.com/en-us/exchange/policy-and-compliance/admin-audit-logging/manage-admin-audit-logging?view=exchserver-2016
        xScript EnableAuditing
        {
            SetScript =
            {
                # Connect to MXS Powershell Exchange
                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$using:ComputerName.$using:DomainFQDN/PowerShell/"
                $M = Import-PSSession $Session

                # Enable Audit on all user mailboxes
                Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq 'UserMailbox'" | Select-Object PrimarySmtpAddress | ForEach-object {Set-Mailbox -Identity $_.PrimarySmtpAddress -AuditEnabled $true}

                # Verify Mailbox Auditing
                # Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq 'UserMailbox'" | Format-List Name,Audit*

                # Enable Admin Audit Logging
                # This example enables administrator audit logging for every cmdlet and every parameter in the organization, with the exception of Get cmdlets.
                Set-AdminAuditLogConfig -AdminAuditLogEnabled $true -AdminAuditLogCmdlets * -AdminAuditLogParameters * -LogLevel Verbose

                # View Admin Audit Logging Settings
                # Get-AdminAuditLogConfig
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
            PsDscRunAsCredential = $DomainCreds
        }    
    }
}

function Get-NetBIOSName {
    [OutputType([string])]
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length = $DomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length = 15
        }
        return $DomainFQDN.Substring(0, $length)
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0, 15)
        }
        else {
            return $DomainFQDN
        }
    }
}