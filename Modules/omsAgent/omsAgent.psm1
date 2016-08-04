$publicFunctions  = Get-ChildItem -Path $PSScriptRoot\publicFunctions\*.ps1 -ErrorAction SilentlyContinue
$privateFunctions = Get-ChildItem -Path $PSScriptRoot\privateFunctions\*.ps1 -ErrorAction SilentlyContinue

if($null -ne $publicFunctions) {
	forEach($importFunction in ($publicFunctions + $privateFunctions)) {
		try {
			. $importFunction
		} catch {
			Write-Error "ERROR: Failed to import function $($importFunction)"
		}
	}
} else {
	Write-Error "ERROR: No public functions to load."
}