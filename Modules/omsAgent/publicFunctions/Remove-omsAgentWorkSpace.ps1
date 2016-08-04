<#
	.SYNOPSIS 
		Removes OMS workspace details to remote computers
	.EXAMPLE
		Remove-omsAgentWorkSpace -computerName 'computer1', 'computer2' -workspaceid '<workspaceid>'
	.NOTES
		Written by Ben Taylor
		Version 1.0, 31.07.2016
#>
function Remove-omsAgentWorkSpace {
	[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
	[OutputType()]
	param (
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[Alias('IPAddress', 'Name')]
		[string[]]
		$computerName = $env:COMPUTERNAME,
		[Parameter()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$workspaceid
	)

	Begin {
		$commonSessionParams = @{
			ErrorAction = 'Stop'
		}
		
		If ($PSBoundParameters['Credential']) {
			$commonSessionParams.Credential = $Credential
		}

		$omsSessionParams = @{}

		If ($PSBoundParameters['workspacekey']) {
			$omsSessionParams.workspaceid = $workspaceid
		}
	} Process {
		forEach($computer in $computerName) {
			try {
				Write-Verbose "[$(Get-Date -Format G)] - $computer - Creating Remote PS Session"
				$psSession = New-PSSession -ComputerName $computer @commonSessionParams

				If(Get-omsAgentWorkSpaceInternal -computerName $computer -session $psSession @omsSessionParams) {
					If ($Pscmdlet.ShouldProcess($computer, 'Remove OMS Work Space')) {
						Write-Verbose "[$(Get-Date -Format G)] - $computer - Removing OMS Workspace - $workspaceid"
						Invoke-Command -Session $psSession -ScriptBlock {
							$omsObj = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
							$omsObj.RemoveCloudWorkspace($USING:workspaceId)
							$omsObj.ReloadConfiguration()
						} -ErrorAction Stop
					}
				} else {
					Write-Error "[$(Get-Date -Format G)] - $computer - No OMS workspace with that ID could be found to remove"
				}
			} catch {
				Write-Error $_
			} finally {
				if($null -ne $psSession) {
					Write-Verbose "[$(Get-Date -Format G)] - $computer - Closing Remote PS Session"
					Remove-PSSession $psSession -WhatIf:$false -Confirm:$false
				}
			}
		}
	}
}

