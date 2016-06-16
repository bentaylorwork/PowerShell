function Get-SCvmAudit () {
    <#
        #Requires -Modules { VirtualMachineManager } 
        .SYNOPSIS 
            A function to find the basic resource info for a VM.
        .EXAMPLE
            Import-Module virtualmachinemanager
            Get-SCvmAudit
        .EXAMPLE
            Import-Module virtualmachinemanager
            Get-SCVirtualMachine -name "vmName" | Get-SCvmAudit
        .NOTES
            Written by Ben Taylor
            Version 1.0, 14.06.2016
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline=$True, valuefrompipelinebypropertyname=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String[]]$name,
        [Parameter(Mandatory = $false)]
        [Bool]$includeReplica = $false
    )

    Process {
        ForEach($vmName in $name) {
            try {
                if($includeReplica -eq $true) {
                    $vmInfo = Get-SCVirtualMachine | Where-Object { $_.name -eq $vmName }
                } else {
                    #Where-Object allows for primary replica VM and un-replicated VMs
                    $vmInfo = Get-SCVirtualMachine | Where-Object { $_.name -eq $vmName -and (($_.IsPrimaryVM) -or ($_.IsPrimaryVM -eq $false -and $_.IsRecoveryVM -eq $false)) }
                }

                if($null -ne $vmInfo) {
                    Write-Verbose "Got info about VM: $vmName"

                    #Build Object To Return Info
                    $returnObj = New-Object System.Object
            
                    $returnObj | Add-Member -type NoteProperty -name Name -Value $vmInfo.Name -force
                    $returnObj | Add-Member -type NoteProperty -name MemoryAssignedMB -Value $vmInfo.MemoryAssignedMB -force
                    $returnObj | Add-Member -type NoteProperty -name cpuCount -Value $vmInfo.cpuCount -force
                    $returnObj | Add-Member -type NoteProperty -name virtualHardDisk -Value ($vmInfo | Get-SCVirtualHardDisk | Select-Object Name, Size, Location ) -force
                    $returnObj | Add-Member -type NoteProperty -name virtualNetworkAdapter -Value ($vmInfo | Get-SCVirtualNetworkAdapter | Select-Object VMNetwork, LogicalNetwork, MACAddress ) -force

                    $returnObj
                } else {
                    Write-Warning "Could not get info about VM: $vmName"
                }
            } Catch {
                Write-Warning "Could not get info about VM: $vmName."
            }
        }       
    }
}