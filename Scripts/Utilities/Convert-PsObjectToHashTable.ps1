Function Convert-PsObjectToHashTable() {
	<#
	.SYNOPSIS
	   Converts a psObject to a Hashtable
	.PARAMETER  psObject
		The psObject that is to be converted into a Hashtable
	.EXAMPLE
		Convert-PsObjectToHashTable -psObject $psObject
	.NOTES
		Written by Ben Taylor
		Version 1.0, 02.11.2016  
	#>
	[CmdletBinding()]
	[OutputType('System.Collections.Hashtable')]
	param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[psobject]
		$psObject
	
	)

	$hash = @{}
	
	$psObject.psobject.properties | ForEach-Object {
		$hash[$_.Name] = $_.Value
	}
	
	$hash
}