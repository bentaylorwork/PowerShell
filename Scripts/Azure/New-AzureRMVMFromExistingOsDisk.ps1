function New-AzureRMVMFromExistingOsDisk
{
    <#
        .SYNOPSIS
            Creates An AzureRM VM from an existing Windows unmanaged data disk.
        .NOTES
            Written by Ben Taylor
            Version 1.0, 27.09.2017
    #>
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')]
    [OutputType()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location = "NorthEurope",
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DiskUri,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $vmName = (New-Guid).Guid,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $vmSize = "Standard_A1",
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InterfaceName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AvailabilitySetName,
        [Parameter(Mandatory=$false)]
        [switch]
        $CreateAvailabilitySet,
        [Parameter(Mandatory=$false, ParameterSetName='NetworkInterface')]
        [switch]
        $CreateNetworkInterface,
        [Parameter(Mandatory=$true, ParameterSetName='NetworkInterface')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubnetName,
        [Parameter(Mandatory=$true, ParameterSetName='NetworkInterface')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VirtualNetworkName
    )

    try
    {
        If ($PSBoundParameters['CreateNetworkInterface'])
        {
            $VNet   = Get-AzureRMVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
            $Subnet = Get-AzureRMVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet -ErrorAction Stop

            New-AzureRMNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id -ErrorAction Stop
        }

        $Interface = Get-AzureRMNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -ErrorAction Stop

        If ($PSBoundParameters['CreateAvailabilitySet'])
        {
            New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName -Location $Location -Managed $false -ErrorAction Stop
        }

        $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName  -Name $AvailabilitySetName -ErrorAction Stop

        $VM  = New-AzureRMVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet.Id -ErrorAction Stop
        $VM  = Add-AzureRMVMNetworkInterface -VM $VM -Id $Interface.Id -ErrorAction Stop
        $VM  = Set-AzureRMVMOSDisk -VM $VM -Name (New-Guid).Guid -VhdUri $DiskUri -CreateOption Attach -Windows -ErrorAction Stop

        New-AzureRMVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM -ErrorAction Stop
    }
    catch
    {
        Write-Error $_
    }
}
