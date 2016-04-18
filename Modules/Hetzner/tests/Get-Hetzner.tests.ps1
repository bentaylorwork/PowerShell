$moduleLoaded = $true

if(-not (Get-Module Hetzner)) {
	$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace('tests', '')
	Import-Module "$here\Hetzner.psd1"
	$moduleLoaded = $false
}

Describe 'INFO: Specific Module and Function tests' {
	Context "INFO: Get-Hetzner - Tests" {
		Set-StrictMode -Version latest
		It 'INFO: Checking parameter validation' {
			{ Get-Hetzner -robotUserName $null -robotFunction 'ip' -ErrorAction Stop } | Should Throw
			{ Get-Hetzner -robotUserName 'userName' -robotFunction $null -ErrorAction Stop } | Should Throw
		}

		It 'INFO: Checking if correct info exists for Get-Help' {
			$helpinfo = Get-Help Get-Hetzner
			$helpinfo.examples | should not BeNullOrEmpty
			$helpinfo.Details | Should not BeNullOrEmpty
			$helpinfo.Description | Should not BeNullOrEmpty
		}
	}
}

if($moduleLoaded -eq $false) {
	Remove-Module Hetzner
}