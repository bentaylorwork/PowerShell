function Get-omsAgentWorkSpaceInternal {
	[CmdletBinding()]
	[OutputType()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$computerName,
		[Parameter(Mandatory=$true)]
		[object]$session,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$workspaceid
	)

	try {
		Invoke-Command -Session $session -ScriptBlock {
			$omsObj = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'

			if($USING:PSBoundParameters['workspaceid']) {
				$omsObj.GetCloudWorkspace($USING:workspaceid)
			} else {
				$omsObj.GetCloudWorkspaces()
			}
		} -ErrorAction Stop

	} catch {
		Write-Error "[$(Get-Date -Format G)] - $computerName - $_"
	}
}