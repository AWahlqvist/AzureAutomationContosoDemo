workflow Stop-SubscriptionVMEnvironment
{
    Param([bool] $ForceUserLogoff = $true)

    $AzureCredAssetName = 'ContosoAutomationUser'
    $VMAdminUserAssetName = 'VMAdmin'
    $SubscriptionName = 'Visual Studio Professional med MSDN'
    $AzureCred = Get-AutomationPSCredential -Name $AzureCredAssetName
    $VMAdminCred = Get-AutomationPSCredential -Name $VMAdminUserAssetName

    $null = Add-AzureAccount -Credential $AzureCred

    Select-AzureSubscription -SubscriptionName $SubscriptionName

    $VMsToShutdown = Get-AzureVM | Where-Object -FilterScript { $_.Status -eq 'ReadyRole' }

    foreach ($VM in $VMsToShutdown) {
    
        $VMUri = Connect-AzureVM -AzureSubscriptionName $SubscriptionName -AzureOrgIdCredential $AzureCred -ServiceName $VM.ServiceName -VMName $VM.Name

        InlineScript {

            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connecting to $($using:VM.Name)..."

            $ShutdownVM = Invoke-Command -ConnectionUri $using:VMUri -Credential $using:VMAdminCred -ArgumentList $using:VM.Name, $using:ForceUserLogoff -ScriptBlock {
                $VMName = $args[0]
                $ForceUserLogoff = $args[1]
                $LoggedOnUsers = query.exe session | Select-String -Pattern 'Active' -Quiet

                if ($LoggedOnUsers -and !$ForceUserLogoff) {
                    Write-Warning "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - At least one user is logged onto $VMName. Skipping this server!"
                    return $false
                }
                else {
                    return $true
                }
            }

            if ($ShutdownVM) {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Shutting down $($using:VM.Name)..."
                Stop-AzureVM -Name $using:VM.Name -ServiceName $using:VM.ServiceName -Force
            }
            else {
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($using:VM.Name) will not be shut down, users are logged on!"
            }
        }

        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done with $($VM.Name)."
    }

    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done with all VMs."
}