function Get-ComputerFreeSpace () {
	<# 
		.SYNOPSIS 
			A function to query free disk space.
		.EXAMPLE
			Import-Module virtualmachinemanager
			$computerNames = (Get-ScVirtualMachine | Where-Object { ($_.Status –eq 'Running') }).name
			Get-ComputerFreeSpace -computerName $computerNames -Verbose
		.EXAMPLE
			$computers = @('computerOne', 'computerTwo', 'computerThree')
			Get-ComputerFreeSpace -computerName $computers
		.NOTES
			Written by Ben Taylor
			Version 1.1, 08.10.2016
	#>
	[CmdletBinding()]
	[OutputType([System.Object])]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline=$True, valuefrompipelinebypropertyname=$true)]
		[ValidateNotNullOrEmpty()]
		[Alias('IPAddress', 'Name')]
		[String[]]$computerName = $env:COMPUTERNAME,
		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateSet('DCOM', 'WSMan', 'Auto')] 
		[String] $Protocol = 'Auto',
		[Parameter(Mandatory = $false, Position = 2)]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential
	)

	Begin {
		$cimCommonParams = @{
			ErrorAction = 'Stop'
		}

		If ($PSBoundParameters['Credential']) {
			$cimCommonParams.Credential = $Credential
		}
	} Process {
		forEach ($computer in $computerName) {
			try {
				$cimCommonParams.ComputerName = $computer

				Write-Verbose "$computer - Trying to Get Disk Space"
				if($Protocol -eq 'Auto') {
					Try {
						Test-WSMan @cimCommonParams | Out-Null
						$ProtocolAuto = 'WsMan'
					} Catch {
						$ProtocolAuto = 'DCOM'
					}
				} else {
					$ProtocolAuto =  $Protocol
				}

				$cimCommonParams.SessionOption = (New-CimSessionOption -Protocol $ProtocolAuto)

				$cimSession = New-CimSession @cimCommonParams

				#Get Free disk space
				$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3" -CimSession $cimSession -ErrorAction Stop

				Write-Verbose "$computer - Successfully queried Disk space Info"

				if($disks) {
					Write-Verbose "$computer - Disk info found"
					forEach ($disk in $disks) {
						#Build Object To Return Info
						$returnObj = New-Object System.Object

						$returnObj | Add-Member -type NoteProperty -name COMPUTERNAME -Value $computer -force
						$returnObj | Add-Member -type NoteProperty -name DISK -Value $disk.DeviceID -force
						$returnObj | Add-Member -type NoteProperty -name VOLUMENAME -Value $disk.VolumeName -force
						$returnObj | Add-Member -type NoteProperty -name TOTALSPACEBYTES -Value $disk.Size -force
						$returnObj | Add-Member -type NoteProperty -name TOTALSPACEGB -Value ([math]::Round(($disk.Size / 1GB), 2)) -force
						$returnObj | Add-Member -type NoteProperty -name FREESPACEBYTES -Value $disk.FreeSpace -force
						$returnObj | Add-Member -type NoteProperty -name FREESPACEGB -Value ([math]::Round(($disk.FreeSpace / 1GB), 2)) -force
						$returnObj | Add-Member -type NoteProperty -name FREESPACEPERCENT -Value ([math]::Round((($disk.FreeSpace / $disk.Size) * 100), 2)) -force

						$returnObj                    
					}
				}
			} Catch {
				Write-Error "$computer - $_"
			} finally {
				if($null -ne $cimSession) {
					Remove-CimSession $cimSession -ErrorAction SilentlyContinue
				}
			}
		}
	}
}