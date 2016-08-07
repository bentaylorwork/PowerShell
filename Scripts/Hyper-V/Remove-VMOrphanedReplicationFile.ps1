#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

<#
	.SYNOPSIS 
		Removes Orphaned files from an incorrectly removed VM replication. Useful for reclaiming HD space.
	.DESCRIPTION 
		Removes Orphaned files from an incorrectly removed VM replication.
	.EXAMPLE
		Remove-VMOrphanedReplicationFiles -computerName 'computer1', 'computer2' -WhatIf -Verbose
	.NOTES
		Written by Ben Taylor
		Version 1.0, 01.04.2016
#>
function Remove-VMOrphanedReplicationFile {
	[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
	[OutputType()]
	Param (
		[parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$computerName = $env:COMPUTERNAME
	)

	Process {
		foreach ($repHost in $computerName) {
			try {
				$repLocation = Get-VMReplicationServer -ComputerName $repHost

				#Get replication locations || Whether Default Location or Authorised Location
				if(($repLocation.DefaultStorageLocation)) {
					$vmRepLocation = ($repLocation.DefaultStorageLocation)

				#Could Use Get-VMReplicationAuthorizationEntry, no point in extra remote call
				} elseif (($repLocation.AuthorizationEntries.StorageLoc)) {
					$vmRepLocation = @()

					#Incase a \ isn't at the end of path causing -unique not to function correctly.
					$repLocation.AuthorizationEntries.StorageLoc | ForEach-Object {
						if(($_.Substring($_.length-1)) -eq '\') {
							$vmRepLocation += $_.Substring(0, $_.length-1)
						} else {
							$vmRepLocation += $_
						}
					}

					$vmRepLocation = $vmRepLocation | Sort-Object -Unique
				} else {
					Write-Error 'No replication locations can be found.'
					Break
				}

				#Launch remote powershell session
				$PSVMHost = New-PSSession -ComputerName $repHost

				$replicaBackupVMFolders = Invoke-Command -Session $PSVMHost -ScriptBlock {
					param( $repLocation )

					Get-ChildItem -Path $repLocation -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName
				} -ArgumentList $vmRepLocation


				$replicaBackupVMFolders.FullName | ForEach-Object {
					$guid = ($_ | split-path -leaf)

					if($guid -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")) {
						$vm = $null

						#Check if GUID of folder matches that of a running machine
						$vm = Get-VM -ComputerName $repHost | Where-Object { $_.vmId -eq $guid }

						if(-not $vm) {
							Write-Verbose "Removing Path - $_"

							If ($Pscmdlet.ShouldProcess($_, 'Remove Item')) {
								Invoke-Command -Session $PSVMHost -ScriptBlock {
									param( $repLocationToRemove )
									Remove-Item -Recurse -Force $repLocationToRemove
								} -ArgumentList $_
							}
						} else {
							Write-Verbose "$($vm.name.tostring()) - matches GUID: $guid"
						}
					}
				}
			} catch {
				Write-Error $_
			} finally {
				#Always Remove PS session regardless off whatif
				If($PSVMHost) {
					Remove-PSSession $PSVMHost -WhatIf:$False -Confirm:$false
				}
			}
		}
	}
}