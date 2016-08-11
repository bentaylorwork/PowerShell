function Get-ServiceRunAsAccount {
	<# 
		.SYNOPSIS 
			A function to query services running under a certain account.
		.EXAMPLE
			Import-Module virtualmachinemanager
			$computerNames = (Get-ScVirtualMachine | Where-Object { ($_.Status –eq 'Running') }).name
			Get-ServiceRunAsAccount -computerName $computerNames -Verbose
		.EXAMPLE
			Get-ServiceRunAsAccount -computerName 'computerOne', 'computerTwo' -serviceAccount LocalSystem -Verbose
		.EXAMPLE
			Import-Module ActiveDirectory
			(Get-ADComputer -Filter *).name | Get-ServiceRunAsAccount -serviceAccount LocalSystem -verbose -Protocol DCOM
		.EXAMPLE
			Get-ServiceRunAsAccount
		.EXAMPLE
			Get-ServiceRunAsAccount -Credential (Get-Credential)
		.NOTES
			Written by Ben Taylor
			Version 1.1, 25.04.2016
	#>
	[CmdletBinding()]
	[OutputType([System.Object])]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline=$True, valuefrompipelinebypropertyname=$true)]
		[ValidateNotNullOrEmpty()]
		[Alias('IPAddress', 'Name')]
		[string[]]$computerName = $env:COMPUTERNAME,
		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateNotNull()]
		[String] $serviceAccount = 'Administrator',
		[Parameter(Mandatory = $false, Position = 2)]
		[ValidateSet('DCOM', 'WsMAN', 'Auto')] 
		[String] $Protocol = 'Auto',
		[Parameter(Mandatory = $false, Position = 3)]
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

				if($Protocol -eq 'Auto') {
					Try {
						Test-WSMan @cimCommonParams | Out-Null
						$ProtocolAuto = 'WsMAN'
					} Catch {
						$ProtocolAuto = 'DCOM'
					}
				} else {
					$ProtocolAuto =  $Protocol
				}

				$cimCommonParams.SessionOption = (New-CimSessionOption -Protocol $ProtocolAuto)

				$cimSession = New-CimSession @cimCommonParams

				$services = Get-CimInstance -CimSession $cimSession -ClassName win32_service

				forEach ($service in $services) {
					If ($service.startName -contains $serviceAccount) {
						Write-Verbose "The service $service.Name on $computer is running as $serviceAccount"

						$service
					}
				}
			} catch {
				Write-Error "$computer - $_"
			} finally {
				if($null -ne $cimSession) {
					Remove-CimSession $cimSession -ErrorAction SilentlyContinue
				}
			}
		}
	}
}