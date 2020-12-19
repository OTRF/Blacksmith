# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
function Update-RemoteTask {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [string]$FolderName,

        [Parameter(Mandatory=$false)]
        [string]$TaskName,

        [Parameter(Mandatory=$false)]
        [string]$Executable,

        [Parameter(Mandatory=$false)]
        [string]$Arguments
    )

    # connect to Task Scheduler:
    $service = New-Object -ComObject Schedule.Service
    $service.Connect($ComputerName)

    # Get task folder that contains tasks:
    $folder = $service.GetFolder($FolderName)

    # Enumerate Specific Task
    $task = $folder.GetTask($TaskName)

    # get task definition and change it (i.e Arguments)
    $taskdefinition = $task.Definition
    $taskdefinition.Actions | ForEach-Object {$_.Path = $Executable}
    $taskdefinition.Actions | ForEach-Object {$_.Arguments = $Arguments}

    # Flags:
    # 4 = UPDATE
    # 6 = CREATE_UPDATE
    #
    # LogonType:
    # 5 = Indicates that a Local System, Local Service, or Network Service account is being used as a security context to run the task.
    $folder.RegisterTaskDefinition($task.Name, $taskdefinition, 4, "System", $null, 5)
}