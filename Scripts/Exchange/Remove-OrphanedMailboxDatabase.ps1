#Requires -RunAsAdministrator
#Requires -PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

<#
	.SYNOPSIS 
		Removes orphaned Exchange 2010 MBX databases that can be left over when removing MBX databases or copies of MBX databases
	.DESCRIPTION 
		Removes orphaned Exchange 2010 MBX databases that can be left over when removing MBX databases or copies of MBX databases
	.EXAMPLE
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

		Remove-OrphanedMailboxDatabase -server '<mbx2010 Server>' -EdbFolderPath '<path to dbs>' -WhatIf
	.EXAMPLE
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

		'<path to dbs>', '<path to dbs>' | Remove-OrphanedMailboxDatabase -server '<mbx2010 Server>' -WhatIf
	.NOTES
		Written by Ben Taylor
		Version 1.0, 27.09.2016
#>
function Remove-OrphanedMailboxDatabase() {
	[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
	[OutputType()]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[ValidateNotNullorEmpty()]
		[String]$server = $env:COMPUTERNAME,
		[Parameter(Mandatory=$true, Position=1, ValueFromPipeline = $true)]
		[ValidateNotNullorEmpty()]
		[ValidateScript({
			$exServerPSSession = New-PSSession -ComputerName $server

			Invoke-Command -session $exServerPSSession -ScriptBlock {
				param( $pathToTest )
				Test-Path $pathToTest -PathType ‘Container’
			} -ArgumentList $_

			If($null -ne $exServerPSSession) {
				Remove-PsSession -Session $exServerPSSession -WhatIf:$false -Confirm:$false
			}

		})] 
		[String[]]$EdbFolderPath
	)

	Process {
		try {
			$exServerPSSession = New-PSSession -ComputerName $server

			$dbPaths = Invoke-Command -session $exServerPSSession -ScriptBlock {
				Get-ChildItem $USING:EdbFolderPath
			}

			forEach($dbpath in $dbPaths) {
				try {
					$dbInformation = Get-MailboxDatabase -Identity $dbpath.name -ErrorAction Stop

					#Check if MBX DB Should be on server
					if(-not ($dbInformation.servers | Where-Object { $_ -eq $server })) {
						Write-Warning "$($dbpath.name.toString()) - Should not have a copy of this DB on this server"

						If ($Pscmdlet.ShouldProcess($($dbpath.FullName),"Remove Item")) {
							Invoke-Command -Session $exServerPSSession -ScriptBlock {
								param( $dbLocationToRemove )
								Remove-Item -Recurse -Force $dbLocationToRemove
							} -ArgumentList $dbpath.FullName
						}
					} else {
						Write-Verbose "$($dbpath.name.toString()) - Should have a copy of this DB on this server"
					}
				#For non-Existant MBX DB
				} Catch {
					try {
						#Check if MBX DB is actually a public folder
						Get-PublicFolderDatabase -Identity $dbpath.name -ErrorAction Stop | Out-Null
						Write-Verbose "$($dbpath.name.toString()) - Should have a copy of this PF on this server"
					} Catch {
						Write-Warning "$($dbpath.name.toString()) - Is not found in the Exchange infastructure and is not a public folder"
					
						#Remove MBX DB
						If ($Pscmdlet.ShouldProcess($($dbpath.FullName), 'Remove Item')) {
							$result = Invoke-Command -Session $exServerPSSession -ScriptBlock {
								param( $dbLocationToRemove )
								Remove-Item -Recurse -Force $dbLocationToRemove
							} -ArgumentList $dbpath.FullName
						}
					}
				}
			}
		} Catch {
			Write-Error $_
		} Finally {
			If($null -ne $exServerPSSession) {
				Remove-PsSession -Session $exServerPSSession -WhatIf:$false -Confirm:$false
			}
		}
	}
}
