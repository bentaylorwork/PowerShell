$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace('tests', '')
$scriptsModules = Get-ChildItem $here -Include *.psd1, *.psm1, *.ps1 -Exclude *.tests.ps1 -Recurse

if(($scriptsModules.count -ne 0) -and (Get-Command Invoke-ScriptAnalyzer -errorAction SilentlyContinue)) {
	$scriptAnalyzerRules = Get-ScriptAnalyzerRule
	Describe 'INFO: General - Testing all scripts and modules conform to the Script Analyzer Rules' {
		forEach ($scriptModule in $scriptsModules) {
			switch ($scriptModule) { 
				'*.psm1' { $typeTesting = 'Module' } 
				'*.ps1'  { $typeTesting = 'Script' } 
				'*.psd1' { $typeTesting = 'Manifest' } 
			}

			Context "INFO: Checking $typeTesting – $($module.BaseName) conforms to Script Analyzer Rules" {
				forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
					It "INFO: It passes Script Analyzer Rule: $scriptAnalyzerRule" {
						(Invoke-ScriptAnalyzer -Path $scriptModule.fullName -IncludeRule $scriptAnalyzerRule.ruleName ).Count | Should Be 0
					}
				}
			}
		}
	}
} else {
	Write-Error -Message 'ERROR: No files found to test or Invoke-ScriptAnalyzer not installed.'
}