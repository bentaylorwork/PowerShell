#Requires -Modules VirtualMachineManager
Function Move-SCVmToHost () {
	<#
		.SYNOPSIS 
			A function to move specific vms to a specific destination host. Ignores Replica VMs.
		.EXAMPLE
			Import-Module virtualmachinemanager
			$vms = Get-SCVMHost | Where-Object { $_.Name -eq "host"} | Get-SCVirtualMachine | Where-Object { $_.status -eq "Running" }
			Move-SCVmToHost -name $vms -destinationHost "host"
		.NOTES
			Written by Ben Taylor
			Version 1.1, 24.06.2016
	#>
	[CmdletBinding()]
	[OutputType([System.Collections.ArrayList])]
	param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline=$True, valuefrompipelinebypropertyname=$true)]
			[ValidateNotNullOrEmpty()]
			[String[]]$name,
			[Parameter(Mandatory = $true, Position = 1)]
			[ValidateNotNullOrEmpty()]
			[String]$destinationHost,
			[Parameter(Mandatory = $false, Position = 2)]
			[ValidateNotNullOrEmpty()]
			[int]$timeOut = 3600
	)

	Process {
			#Move Action
			foreach ($n in $name){
			$vm = Get-ScVirtualMachine -name $n |  Where-Object { (($_.IsPrimaryVM) -or ($_.IsPrimaryVM -eq $false -and $_.IsRecoveryVM -eq $false)) }

			if(-not (Get-ScVirtualMachine -name ($vm.name) -VMHost $destinationHost)) {
				Write-Verbose "[$(Get-Date -Format G)] - $($vm.name) - Checking destination host rating"

				$vmHostRating = Get-SCVMHostRating -VM $vm -VMHost $destinationhost 

				if($vmHostRating.Rating -gt "0") {
					#Get VM placement path on preferred storage volume using VM host ratings
					forEach($vmPath in (Get-SCVMHost -ComputerName $destinationhost).VMPaths) {
						if($vmPath -match [regex]::Escape($vmHostRating.PreferredStorage.Name)) {
							$pathToMoveVmTo = $vmPath
							Break
						}
					}

					Write-Verbose "[$(Get-Date -Format G)] - $($vm.name) - Path to move VM is $pathToMoveVmTo"
		
					try {
						Write-Verbose "[$(Get-Date -Format G)] - $($vm.name) - Attempting to move."

						#Setup Timer For TimeOut
						$timer = [Diagnostics.Stopwatch]::StartNew()

						$moveVm = Move-SCVirtualMachine -VM $vm -VMHost $destinationhost -Path $pathToMoveVmTo -RunAsynchronously -ErrorAction Stop

						#Using DO to hit sleep first
						Do {
							if($timer.Elapsed.TotalSeconds -ge $timeOut) {
								Write-Error "[$(Get-Date -Format G)] - $($vm.name) - Hit Timeout Limit And SCVMM job cancelling"

								Stop-ScJob -Job $moveVm.MostRecentTaskID			

								break
							}

							Start-Sleep 5

							Write-Progress -Activity "Moving VM" -status $vm -percentComplete ((Get-SCJob -ID $moveVm.MostRecentTaskID).ProgressValue)
							Write-Verbose "[$(Get-Date -Format G)] - $($vm.name) - Is moving. $((Get-SCJob -ID $moveVm.MostRecentTaskID).ProgressValue) %"

						} While ((Get-SCJob -ID $moveVm.MostRecentTaskID).Status -eq 'Running')

						Start-Sleep 5

						if((Get-SCJob -ID $moveVm.MostRecentTaskID).Status -like 'Completed*') {
							Write-Verbose "[$(Get-Date -Format G)] - $($vm.name) - Was successfully moved"
						} else {
							Write-Error "[$(Get-Date -Format G)] - $($vm.name) - Was not successfully moved"
						}
					} Catch {
						Write-Error $_
					} Finally {
						$timer.Stop()
					}
				} Else {
					Write-Warning "[$(Get-Date -Format G)] - $($vm.name) - Cannot be moved due to a host compatibility issue - $($vmHostRating.Description)"
				}
			} Else {
				Write-Warning "[$(Get-Date -Format G)] - $($vm.name) - Allready exists on destination host"
			}
		}
	}
}
