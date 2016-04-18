$moduleLoaded = $true

if(-not (Get-Module Hetzner)) {
	$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace('tests', '')
	Import-Module "$here\Hetzner.psd1"
	$moduleLoaded = $false
}

Describe 'INFO: Specific Module and Function tests' {
	Context 'INFO: Publish-Hetzner - Tests' {
		Set-StrictMode -Version latest
		It 'INFO: Checking parameter validation' {
			{ Publish-Hetzner -robotUserName $null -robotFunction 'ip' -ErrorAction Stop } | Should Throw
			{ Publish-Hetzner -robotUserName "userName" -robotFunction $null -ErrorAction Stop } | Should Throw
			{ Publish-Hetzner -robotUserName "userName" -robotFunction 'ip' -robotAction $null -ErrorAction Stop } | Should Throw
		}

		It 'INFO: Checking if correct info exists for Get-Help' {
			$helpinfo = Get-Help Publish-Hetzner
			$helpinfo.examples | should not BeNullOrEmpty
			$helpinfo.Details | Should not BeNullOrEmpty
			$helpinfo.Description | Should not BeNullOrEmpty
		}
	}
}

if($moduleLoaded -eq $false) {
	Remove-Module Hetzner
}