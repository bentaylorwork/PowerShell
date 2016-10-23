function Get-omsAgentInternal {
	[CmdletBinding()]
	[OutputType()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$computerName,
		[Parameter(Mandatory=$false)]
		[object]$session
	)

	try {
		Invoke-Command -Session $session -ScriptBlock {
			$oms = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.displayName -eq 'Microsoft Monitoring Agent' }

			if($oms) {
				$omsInfo = @{}
				$omsInfo.DisplayName = $oms.DisplayName
				$omsInfo.Version = $oms.Version
				$omsInfo.DisplayVersion = $oms.DisplayVersion
				$omsInfo.UninstallString = $oms.UninstallString

				try {
					$omsObj = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
					$omsObj.GetCloudWorkspaces()
					$omsInfo.comObjectAvailable = $true
				} catch {
					$omsInfo.comObjectAvailable = $false
				}

				New-Object –TypeName PSObject -Property $omsInfo
			} else {
				Write-Error "[$(Get-Date -Format G)] - $computerName - OMS Agent Not Installed"
			}
		} -ErrorAction Stop
	} catch {
		Write-Error "[$(Get-Date -Format G)] - $computerName - $_"
	}
}