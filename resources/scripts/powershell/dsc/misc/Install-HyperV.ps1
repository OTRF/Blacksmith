Configuration Install-HyperV {

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    Node "localhost" {

        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration'
        }

        WindowsFeature Hyper-V {
            Name   = "Hyper-V"
            Ensure = "Present"
        }
        WindowsFeature DHCP {
            Name   = "DHCP"
            Ensure = "Present"
        }
        WindowsFeature RemoteAccess {
            Name   = "RemoteAccess"
            Ensure = "Present"
        }
        WindowsFeature Routing {
            Name   = "Routing"
            Ensure = "Present"
        }
        WindowsFeature RSAT-Hyper-V-Tools {
            Name = "RSAT-Hyper-V-Tools"
            Ensure = "Present"
        }
        WindowsFeature RSAT-DHCP {
            Name = "RSAT-DHCP"
            Ensure = "Present"
        }
        WindowsFeature RSAT-RemoteAccess {
            Name = "RSAT-RemoteAccess"
            Ensure = "Present"
        }
    }
}