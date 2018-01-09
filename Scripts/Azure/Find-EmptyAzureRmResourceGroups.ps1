function Find-EmptyAzureRmResourceGroups
{
    <#
        .Synopsis
           Finds Azure Resource Groups that are empty.
        .EXAMPLE
            Find-EmptyAzureRmResourceGroups
        .EXAMPLE
            $emptyResourceGroups = Get-AzureRmSubscription | ForEach-Object {
                Select-AzureRmSubscription -SubscriptionId $_.Id | Out-Null

                Find-EmptyAzureRmResourceGroups
            }

            $emptyResourceGroups
        .NOTES
            Written by Ben Taylor
            Version 1.0, 08.01.2018
    #>
    [CmdletBinding()]
    param ()
    
    $resourceGroups = Get-AzureRmResourceGroup
    
    foreach($resourceGroup in $resourceGroups)
    {
        if(-not (Find-AzureRmResource -ResourceGroupNameEquals $resourceGroup.ResourceGroupName))
        {
            $resourceGroup
        } 
    }
}
