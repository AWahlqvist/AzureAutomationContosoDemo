$AzureSubscriptionCredential = Get-AutomationPSCredential -Name 'ContosoAutomationUser'

Add-AzureAccount -Credential $AzureSubscriptionCredential

Select-AzureSubscription -SubscriptionName 'Visual Studio Professional med MSDN'

Get-AzureVM | Where-Object -FilterScript { $_.PowerState -eq 'Started' } | Stop-AzureVM -Force
