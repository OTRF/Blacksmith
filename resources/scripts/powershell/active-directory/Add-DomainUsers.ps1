# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://aws.amazon.com/blogs/compute/optimizing-joining-windows-server-instances-to-a-domain-with-powershell-in-aws-cloudformation/
# https://github.com/aws-quickstart/quickstart-microsoft-activedirectory/blob/master/scripts/archive/Create-AdminUser.ps1
# http://woshub.com/new-aduser-create-active-directory-users-powershell/
# https://blog.netwrix.com/2018/06/07/how-to-create-new-active-directory-users-with-powershell/
# https://stackoverflow.com/questions/30617758/splitting-a-string-into-separate-variables

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [string]$domainFQDN,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$dcVMName
)

# Verifying ADWS service is running
$ServiceName = 'ADWS'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }
}

Start-Sleep 10

$ADServer = $dcVMName+"."+$domainFQDN
$DomainName1,$DomainName2 = $domainFQDN.split('.')

$domainUsers = @"
FirstName,LastName,SamAccountName,Department,JobTitle,Password,Identity,UserContainer
Norah,Martha,nmartha,Human Resources,HR Director,S@l@m3!123,Users,DomainUsers
Pedro,Gustavo,pgustavo,IT Support,CIO,W1n1!2019,Domain Admins,DomainUsers
Lucho,Rodriguez,lrodriguez,Accounting,VP,T0d@y!2019,Users,DomainUsers
Stevie,Beavers,sbeavers,Sales,Agent,B1gM@c!2020,Users,DomainUsers
Pam,Beesly,pbeesly,Reception,Receptionist,Fl0nk3rt0n!T0by,Users,DomainUsers
Dwight,Schrute,dschrute,Sales,Assistant,Schrut3F@rms!B33ts,Users,DomainUsers
Michael,Scott,mscott,Management,BestBoss,abc123!D@t3M1k3,Domain Admins,DomainUsers 
Sysmon,MS,sysmonsvc,IT Support,Service Account,Buggy!1122,Users,DomainUsers
Nxlog,Shipper,nxlogsvc,IT Support,Service Account,S3nData!1122,Users,DomainUsers
Defense,Shield,defensesvc,IT Support,Service Account,Sh13ld!1122,Users,DomainUsers
OTR,Community,otrsvc,IT Support,Service Account,L0v30p3nS0urc3!2020,Users,DomainUsers
Ring,Mordor,mordorsvc,IT Support,Service Account,Th3K1ng!1122,Users,DomainUsers
"@

write-host "Creating domain users.."
$domainUsers | ConvertFrom-Csv | ForEach-Object {
    $UserPrincipalName = $_.SamAccountName + "@" + $domainFQDN
    $DisplayName = $_.LastName + " " + $_.FirstName
    $OUPath = "OU="+$_.UserContainer+",DC=$DomainName1,DC=$DomainName2"
    $SamAccountName = $_.SamAccountName
    $ServiceName = $_.FirstName

    write-host "Checking if user $SamAccountName exists or not.."

    $User = Get-ADUser -LDAPFilter "(sAMAccountName=$SamAccountName)"
    Write-Host $User

    if ($User -eq $Null)
    {
        write-host "Creating user $UserPrincipalName .."
        New-ADUser -Name $DisplayName `
        -DisplayName $DisplayName `
        -GivenName $_.FirstName `
        -Surname $_.LastName `
        -Department $_.Department `
        -Title $_.JobTitle `
        -UserPrincipalName $UserPrincipalName `
        -SamAccountName $_.SamAccountName `
        -Path $OUPath `
        -AccountPassword (ConvertTo-SecureString $_.Password -AsPlainText -force) `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -Server $ADServer

        write-host "Successfully Created $UserPrincipalName..."

        if($_.Identity -Like "Domain Admins"){

            write-host "Adding user $UserPrincipalName to Domain Admin groups .."
            $DomainAdminUser = $_.SamAccountName
            $Groups = @('domain admins','schema admins','enterprise admins')
            $Groups | ForEach-Object{
                $members = Get-ADGroupMember -Identity $_ -Recursive | Select-Object -ExpandProperty Name
                if ($members -contains $DomainAdminUser) {
                    Write-Host "$DomainAdminUser exists in $_ "
                }
                else {
                    Write-Host "$DomainAdminUser does not exists in group $_ "
                    write-host "Adding user $DomainAdminUser to $_ .."
                    Add-ADGroupMember -Identity $_ -Members $DomainAdminUser
                }
            }
        }
        if($_.JobTitle -Like "Service Account"){
            setspn -a $ServiceName/$domainFQDN $DomainName1\$SamAccountName
        }
    }
    else
    {
        write-host "Account already exists.."
    }
}