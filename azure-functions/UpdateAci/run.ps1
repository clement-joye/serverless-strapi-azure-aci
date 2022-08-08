using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "PowerShell HTTP trigger function processed a request."

$SubscriptionId = $env:SUBSCRIPTION_ID
$ResourceGroup = $env:RESOURCE_GROUP_NAME
$StrapiContainerGroup = $env:CONTAINER_GROUP_NAME
$StrapiUrl = $env:ACI_URL

$Action = $Request.Query.Action
$Instance = $Request.Query.Instance
$Code = $Request.Query.Code
$Html = Get-Content ".\UpdateAci\index.html" | Out-String

$BaseUrl = $Request.Url.Substring(0, $Request.Url.IndexOf("?")) 

$StatusRequest = $BaseUrl + "?action=status&code=$Code"

$StrapiStartRequest = $BaseUrl + "?action=start&instance=strapi&code=$Code"
$StrapiStopRequest = $BaseUrl + "?action=stop&instance=strapi&code=$Code"

if ($Action -eq "start" -Or $Action -eq "stop") {

    if ($Action -eq "start") {

        try {
            if ($Instance -eq "strapi" -Or [string]::IsNullOrEmpty($Instance)) {
                Write-Host "Starting Az container group $StrapiContainerGroup."
                Start-AzContainerGroup -Name $StrapiContainerGroup -ResourceGroupName $ResourceGroup -SubscriptionId $SubscriptionId -NoWait
                Write-Host "Starting Az container group $StrapiContainerGroup done."
            }
        }
        catch { }
    }

    elseif ($Action -eq "stop") {

        try {
            if ($Instance -eq "strapi" -Or [string]::IsNullOrEmpty($Instance)) {
                Write-Host "Stopping Az container group $StrapiContainerGroup."
                Stop-AzContainerGroup -Name $StrapiContainerGroup -ResourceGroupName $ResourceGroup -SubscriptionId $SubscriptionId
                Write-Host "Stopping Az container group $StrapiContainerGroup done."
            }
        }
        catch { }
    }
    
    $Html = $Html.Replace("{{url}}", $StatusRequest)
    $Html = $Html.Replace("{{strapiUrl}}", $StrapiUrl)
    
    $Html = $Html.Replace("{{strapiStartUrl}}", $StrapiStartRequest)
    $Html = $Html.Replace("{{strapiStopUrl}}", $StrapiStopRequest)
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        headers = @{'content-type'='text/html'}
        Body = $Html
    })
}
elseif ($Action -eq "status") {

    $StrapiStatus = (Get-AzContainerGroup -ResourceGroupName $ResourceGroup -Name $StrapiContainerGroup).InstanceViewState
    Write-Host "Strapi status: $StrapiStatus"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        headers = @{'content-type'='application/json'}
        Body = @{
            "strapi" = $StrapiStatus
        } | ConvertTo-Json
    })
}
