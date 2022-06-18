using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "PowerShell HTTP trigger function processed a request."

$SubscriptionId = $env:SUBSCRIPTION_ID
$ResourceGroup = $env:RESOURCE_GROUP_NAME
$ContainerGroup = $env:CONTAINER_GROUP_NAME
$AciUrl = $env:ACI_URL

$Action = $Request.Query.Action

if($Action -eq "start") {

    try {
        Write-Host "Starting Az container group $ContainerGroup."
        Start-AzContainerGroup -Name $ContainerGroup -ResourceGroupName $ResourceGroup -SubscriptionId $SubscriptionId
        Write-Host "Starting Az container group $ContainerGroup done."

        $StartDate = Get-Date
        $IsRunning = $False

        do {
            $Status = (Get-AzContainerGroup -ResourceGroupName $ResourceGroup -Name $ContainerGroup).InstanceViewState
            Write-Host "Status: $Status"
            if($Status -eq "Running") {
                $IsRunning = $True;
            }
            Start-Sleep 15
        } while ($IsRunning -eq $False -and $StartDate.AddMinutes(4) -gt (Get-Date))
    }
    catch { }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Redirect
        Headers = @{Location = "$AciUrl/admin"}
        Body = ''
    })
}
else {

    try {
        Write-Host "Stopping Az container group $ContainerGroup."
        Stop-AzContainerGroup -Name $ContainerGroup -ResourceGroupName $ResourceGroup -SubscriptionId $SubscriptionId
        Write-Host "Stopping Az container group $ContainerGroup done."

        $StartDate = Get-Date
        $IsRunning = $True

        do {
            $Status = (Get-AzContainerGroup -ResourceGroupName $ResourceGroup -Name $ContainerGroup).InstanceViewState
            Write-Host "Status: $Status"
            if($Status -eq "Stopped") {
                $IsRunning = $False;
            }
            Start-Sleep 10
        } while ($IsRunning -eq $True -and $StartDate.AddMinutes(3) -gt (Get-Date))
    }
    catch { }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = "This HTTP triggered function executed successfully. ACI is now closed."
    })
}


