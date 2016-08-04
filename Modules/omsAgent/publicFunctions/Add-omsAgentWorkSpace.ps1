<#
	.SYNOPSIS 
		Adds a OMS workspace to remote computers.
	.EXAMPLE
		Add-omsAgentWorkSpace -computerName 'computer1', 'computer2' -workSpaceId '<workSpace>' -workSpaceKey '<workSpaceKey>'
	.NOTES
		Written by Ben Taylor
		Version 1.0, 31.07.2016
#>
function Add-omsAgentWorkSpace {
	[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')]
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
		[string]$workspaceid,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$workspacekey
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

				If(-not(Get-omsAgentWorkSpaceInternal -computerName $computer -session $psSession @omsSessionParams)) {
					If ($Pscmdlet.ShouldProcess($computer, 'Add OMS Agent Work Space')) {
						Write-Verbose "[$(Get-Date -Format G)] - $computer - Adding OMS Workspace"
						Invoke-Command -Session $psSession -ScriptBlock {
							$omsObj = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
							$omsObj.AddCloudWorkspace($USING:workspaceId, $USING:workspaceKey)
							$omsObj.ReloadConfiguration()
						} -ErrorAction Stop
					}
				} else {
					Write-Error "[$(Get-Date -Format G)] - $computer - OMS workspace with that ID found - please use Update-omsAgentWorkSpace"
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