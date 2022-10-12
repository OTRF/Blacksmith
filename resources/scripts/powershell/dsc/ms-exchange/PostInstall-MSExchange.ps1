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
                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$using:ComputerName.$using:DomainFQDN/PowerShell/" -Authentication Kerberos
                Import-PSSession -Session $Session -DisableNameChecking

                # Enable Audit on the only user (admin account)
                Write-Verbose "[*] Getting all mailboxes.."
                $tries = 0   
                while ((@(Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq 'UserMailbox'").Count -eq 0) -and ($tries -lt 12)) {
                    Write-Verbose "[!] No mailboxes found.."
                    start-sleep -seconds 10
                }

                Write-Verbose "[+] Mailboxes found.."
                Write-Verbose "[*] Checking if audit is enabled on mailboxes.."
                $tries = 0
                $mailboxes = Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq 'UserMailbox'"
                while (!((Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq 'UserMailbox'").AuditEnabled) -and ($tries -lt 12)) {
                    $mailboxes | Set-Mailbox -AuditEnabled $true -erroraction 'silentlycontinue'
                    $tries++
                    Write-Verbose "[!] Audit not enabled.."
                    start-sleep -seconds 10
                }
                Write-Verbose "[+] Audit enabled on mailboxes.."

                # Verify Mailbox Auditing
                # Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq 'UserMailbox'" | Format-List Name,Audit*

                # Enable Admin Audit Logging
                # This example enables administrator audit logging for every cmdlet and every parameter in the organization, with the exception of Get cmdlets.
                Write-Verbose "[+] Setting Admin Audit Logging.."
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