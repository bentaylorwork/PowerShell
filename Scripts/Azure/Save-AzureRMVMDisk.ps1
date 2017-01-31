function Save-AzureRMVMDisk
{
    <#
    .Synopsis
       Download all VHD's from an Azure VM
    .EXAMPLE
        Save-AzureRMVMDisk -ResourceGroupName 'rgName' -Name 'vmName' -path 'c:\vms\test-vm' -Verbose
    .EXAMPLE
        Save-AzureRMVMDisk -ResourceGroupName 'rgName' -Name 'vmName' -ShutDown -Verbose
    .NOTES
        Written by Ben Taylor
        Version 1.0, 30.01.2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({
            if(Get-AzureRmResourceGroup -Name $_)
            {
                $true
            }
            else
            {
                $false
            }
        })]
        [string]
        $resourceGroupName,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({
            if((Get-AzureRmVm -ResourceGroupName $resourceGroupName -Name $_).count -eq 1)
            {
                $true
            }
            else
            {
                $false
            }
        })]
        [string]
        $name,
        [Parameter(Mandatory=$false, Position=2)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $path = $env:TEMP,
        [Parameter(Mandatory=$false, Position=3)]
        [switch]
        $ShutDown
    )

    $vm = Get-AzureRmVm -ResourceGroupName $resourceGroupName -Name $name

    Write-Verbose 'Finding Out VM Power Status'
    $vmPowerState = (Get-AzureRmVm -ResourceGroupName $resourceGroupName -Name $Vmname -Status).Statuses | Where-Object { $_.Code -eq 'PowerState/deallocated' }

    if($PSBoundParameters['ShutDown'])
    {   
        If(-not $vmPowerState)
        {
            Write-Verbose 'VM was on so trying to turn off'
            $vm | Stop-AzureRmVM | Out-Null

            while(-not $vmPowerState)
            {
                $vmPowerState = (Get-AzureRmVm -ResourceGroupName $resourceGroupName -Name $Vmname -Status).Statuses | Where-Object { $_.Code -eq 'PowerState/deallocated' }
            }
        }
    }

    If($vmPowerState)
    {
        Write-Verbose 'VM is off attempting to save disks'

        $osDiskParams = @{
            ResourceGroupName = $resourceGroupName
            SourceUri         = $vm.StorageProfile.OsDisk.vhd.uri
            LocalFilePath     = Join-Path $path "$($vm.StorageProfile.OsDisk.Name).vhd"
        }

        Write-Verbose 'Saving OS Disk'
        Save-AzureRmVhd @osDiskParams
            
        # Download Each Data Disk
        $vm.storageProfile.DataDisks | ForEach-Object {
            $osDiskParams = @{
                ResourceGroupName = $resourceGroupName
                SourceUri         = ($_.vhd).Uri
                LocalFilePath     = Join-Path $path "$($_.name).vhd"
            }

            Write-Verbose 'Saving Data Disks'           
            Save-AzureRmVhd @osDiskParams
        }
    }
    else
    {
        Write-Error 'VM is still Allocated please De-Allocated or use the shutdown switch.'
    }
}
