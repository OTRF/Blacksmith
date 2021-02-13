# ##########################################
# Permanent WMI Subscription               #
# Consumer Class: CommandLineEventConsumer #
############################################

$EventFilterArgs = @{
    EventNamespace = 'root/cimv2'
    Name = 'NotepadProcessStarted1'
    Query = "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName='notepad.exe'"
    QueryLanguage = 'WQL'
}

$Filter = Set-WmiInstance -Namespace root/subscription -Class __EventFilter -Property $EventFilterArgs

$CommandLineConsumerArgs = @{
    Name = 'CLConsumer'
    CommandLineTemplate = "powershell.exe -c Add-Content -Value 'CommandLineEventConsumer' -Path C:\ProgramData\WMIEventing.txt"
}

$Consumer = Set-WmiInstance -Namespace root/subscription -Class CommandLineEventConsumer -Property $CommandLineConsumerArgs

$FilterToConsumerArgs = @{
    Filter = $Filter
    Consumer = $Consumer
}

$FilterToConsumerBinding = Set-WmiInstance -Namespace root/subscription -Class __FilterToConsumerBinding -Property $FilterToConsumerArgs

# Cleanup
#$EventConsumerToCleanup = Get-WmiObject -Namespace root/subscription -Class CommandLineEventConsumer -Filter "Name = 'CLConsumer'"
#$EventFilterToCleanup = Get-WmiObject -Namespace root/subscription -Class __EventFilter -Filter "Name = 'NotepadProcessStarted1'"
#$FilterConsumerBindingToCleanup = Get-WmiObject -Namespace root/subscription -Query "REFERENCES OF {$($EventConsumerToCleanup.__RELPATH)} WHERE ResultClass = __FilterToConsumerBinding" -ErrorAction SilentlyContinue
#$FilterConsumerBindingToCleanup | Remove-WmiObject
#$EventConsumerToCleanup | Remove-WmiObject
#$EventFilterToCleanup | Remove-WmiObject