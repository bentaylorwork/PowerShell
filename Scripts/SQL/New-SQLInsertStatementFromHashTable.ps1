function New-SQLInsertStatementFromHashTable
{
	<#
	.SYNOPSIS
	   Generates a MsSQL Insert Statement From A Hash table
	.DESCRIPTION
	   Generates a MsSQL Insert Statement From A Hash table. The Hash table's key must be the column name to be inserted.
	.PARAMETER  sqlTable
		[string] Name of the SQL Table you want to insert the data into.
	.PARAMETER  sqlData
		[hashtable] Data to be inserted into the SQL table. Key of the Hash table should be column name.
	.EXAMPLE
		$sqlSplat = @{
			sqlTable = 'testTable'
			sqlData  = @{
				dateTime      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
				columnOne     = 'Value One'
				columnTwo     = 'Value Two'
			}
		}

		New-SQLInsertStatementFromHashTable @sqlSplat
	.EXAMPLE
		$sqlData  = @{
			dateTime      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			columnOne     = 'Value One'
			columnTwo     = 'Value Two'
		}

		New-SQLInsertStatementFromHashTable -sqlTable 'testTable' -sqlData $sqlData
	.NOTES
		Written by Ben Taylor
		Version 1.0, 02.11.2016  
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param
	(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$sqlTable,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[hashtable]
		$sqlData
	)

	$sqlColumns = @()
	$sqlValues  = @()

	foreach($key in $($sqlData.Keys)){
		$sqlColumns += $key
		$sqlValues  += $sqlData.Item($key)
	}

	"INSERT INTO [$sqlTable] ([" + ($sqlColumns -join "], [") + "]) VALUES ('" + ($sqlValues -join "', '") + "')"
}