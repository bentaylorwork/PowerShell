function New-UniqueResourceGroup
{
    <#
        .SYNOPSIS
            Creates a Azure Resource Group Name with a unique
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $location = 'NorthEurope'
    )

    do {
        $ResourceGroupName = (New-Guid).Guid
    } until (-not (Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction SilentlyContinue))

    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location

    $ResourceGroupName
}
