<#
	.Synopsis
	   Un-installs the OMS agent on remote computers.
	.DESCRIPTION
	   Un-installs the OMS agent on remote computers.
	.EXAMPLE
		Uninstall-OmsAgent -computerName 'computer1', 'computer2' -Verbose
	.NOTES
		Written by Ben Taylor
		Version 1.0, 31.07.2016
#>
function Uninstall-OmsAgent {
	[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
	[OutputType()]
	Param (
		[Parameter(Mandatory = $false, ValueFromPipeline=$True, valuefrompipelinebypropertyname=$true,  Position=0)]
		[ValidateNotNullOrEmpty()]
		[Alias('IPAddress', 'Name')]
		[string[]]
		$computerName = $env:COMPUTERNAME,
		[Parameter()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential
	)

	Begin {
		$commonSessionParams = @{
			ErrorAction = 'Stop'
		}

		If ($PSBoundParameters['Credential']) {
			$commonSessionParams.Credential = $Credential
		}
	} Process {
		forEach ($computer in $computerName) {
			try {
				Write-Verbose "[$(Get-Date -Format G)] - $computer - Creating Remote PS Session"
				$psSession = New-PSSession -ComputerName $computer @commonSessionParams

				Write-Verbose "[$(Get-Date -Format G)] - $computer - Checking if OMS is Installed"
				$omsInstall = Get-omsAgentInternal -computerName $computer -session $psSession

				if($omsInstall) {
					If ($Pscmdlet.ShouldProcess($computer, 'Uninstall OMS Agent')) {
						Write-Verbose "[$(Get-Date -Format G)] - $computer - OMS is installed so will try to uninstall"

						Invoke-Command -Session $psSession -ScriptBlock {
							$uninstallString = ($USING:omsInstall.UninstallString).ToLower().Replace("/i", "").Replace("msiexec.exe", "")
							Start-Process "msiexec.exe" -arg "/X $uninstallString /qn" -Wait
						} -ErrorAction Stop

						$omsInstallStatus = Get-omsAgentInternal -computerName $computer -session $psSession -ErrorAction SilentlyContinue

						if(-not($omsInstallStatus)) {
							Write-Verbose "[$(Get-Date -Format G)] - $computer - OMS uninstalled correctly"
						} else {
							Write-Error "[$(Get-Date -Format G)] - $computer - OMS didn't uninstall correctly based registry check"
						}
					}
				} else {
					Write-Verbose "[$(Get-Date -Format G)] - $computer - OMS not installed so skipping uninstall process"
				}
			} catch {
				Write-Error $_
			} Finally {
				if($null -ne $psSession) {
					Write-Verbose "[$(Get-Date -Format G)] - $computer - Closing Remote PS Session"
					Remove-PSSession $psSession -WhatIf:$false -Confirm:$false
				}
			}
		}
	}
}
