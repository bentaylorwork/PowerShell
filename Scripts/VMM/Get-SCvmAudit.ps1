#Requires -Modules VirtualMachineManager

function Get-SCvmAudit () {
	<#
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
		[ValidateNotNullOrEmpty()]
		[String[]]$name,
		[Parameter(Mandatory = $false)]
		[Switch]$includeReplica
	)

	Process {
		ForEach($vmName in $name) {
			try {
				if($includeReplica -eq $true) {
					$vmInfoRaw = Get-SCVirtualMachine -name $vmName 
				} else {
					#Where-Object allows for primary replica VM and un-replicated VMs
					$vmInfoRaw = Get-SCVirtualMachine -name $vmName | Where-Object { ($_.IsPrimaryVM) -or ($_.IsPrimaryVM -eq $false -and $_.IsRecoveryVM -eq $false) }
				}

				if($null -ne $vmInfoRaw) {
					forEach($vmInfo in $vmInfoRaw) {
						Write-Verbose "Got info about VM: $vmName"

						[pscustomobject]@{
							Name                  = $vmInfo.Name
							MemoryAssignedMB      = $vmInfo.MemoryAssignedMB
							cpuCount              = $vmInfo.cpuCount
							virtualHardDisk       = ($vmInfo | Get-SCVirtualHardDisk | Select-Object Name, Size, Location)
							virtualNetworkAdapter = ($vmInfo | Get-SCVirtualNetworkAdapter | Select-Object VMNetwork, LogicalNetwork, MACAddress)
							isPrimaryVm           = $vmInfo.IsPrimaryVM
						}
					}
				} else {
					Write-Warning "Could not get info about VM: $vmName"
				}
			} Catch {
				Write-Warning "Could not get info about VM: $vmName."
			}
		}       
	}
}
