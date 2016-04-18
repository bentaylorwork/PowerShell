#Helper Function - Create Hash Table From Returned Error Results
function Get-errorHash () {
    [cmdletBinding()]
	[OutputType([System.Collections.HashTable])]
    Param (
		[Parameter(Mandatory=$True, HelpMessage="Hetzner Error Result")]
        [object[]]$errorResult
    )

	$reader = New-Object System.IO.StreamReader($errorResult)
	$reader.BaseStream.Position = 0
	$reader.DiscardBufferedData()
	($reader.ReadToEnd() | ConvertFrom-Json).error
}