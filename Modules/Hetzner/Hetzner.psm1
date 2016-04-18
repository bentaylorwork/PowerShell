<# 
    .SYNOPSIS
       A light weight wrapper for interaction with the Hetzner Robot API using Powershell. GET and POST methods implemented, had no need for the DELETE method
    .DESCRIPTION
        Allows Get and Post requests to the Hetzner Robot API. More info on the can be found in the link below.
        http://wiki.hetzner.de/index.php/Robot_Webservice/en
    .NOTES
        Written by Ben Taylor
        Version 1.0, 12.01.2015
#>

$publicFunctions  = Get-ChildItem -Path $PSScriptRoot\publicFunctions\*.ps1 -ErrorAction SilentlyContinue
$privateFunctions = Get-ChildItem -Path $PSScriptRoot\privateFunctions\*.ps1 -ErrorAction SilentlyContinue

if($null -ne $publicFunctions) {
    forEach($importFunction in ($publicFunctions + $privateFunctions)) {
        try {
            . $importFunction
        } catch {
            Write-Error -Message "ERROR: Failed to import function $($importFunction)"
        }
    }
} else {
	Write-Error -Message "ERROR: No public functions to load."
}