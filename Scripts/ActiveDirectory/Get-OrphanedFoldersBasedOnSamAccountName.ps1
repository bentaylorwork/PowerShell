Function Get-OrphanedFoldersBasedOnSamAccountName() {
	<#
		.SYNOPSIS 
			Gives the status of Active Directory Users based on Directorys that are named with the SamAccountName.
		.DESCRIPTION
			Gives the status of Active Directory Users based on Directorys that are named with the SamAccountName. Requires PowerShell V.3
		.EXAMPLE
			Get-OrphanedFoldersBasedOnSamAccountName -path '<path to folders>' -verbose
		.EXAMPLE
			'<path one>', '<path two>' | Get-OrphanedFoldersBasedOnSamAccountName
		.NOTES
			Written by Ben Taylor
			Version 1.0, 26.10.2016
	#>
	[CmdletBinding()]
	[OutputType('psOrpFolderSam')]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path $_ })]
		[string[]]
		$path
	)

	Get-ChildItem -Path $path | Where-Object {$_.PSISContainer} | ForEach-Object {
		try {
			#replace v2 to allow for re-directed folders
			$userAccount = ([ADSISEARCHER]"(samaccountname=$(($_.name -replace '.V2', '')))").FindOne()

			if($userAccount)
			{
				Write-Verbose 'User Account Exists'

				New-Object -TypeName PSObject -Property @{
					SamAccountName  = $_.name
					UserProperties  = $userAccount.properties
					IsAccountExist  = $true 
					IsDisabled      = $userAccount.GetDirectoryEntry().InvokeGet('AccountDisabled')
					Path            = $_.FullName
				}
			}
			else
			{
				Write-Verbose 'User Account Does Not Exist'

				New-Object -TypeName PSObject -Property @{
					SamAccountName  = $_.name
					UserProperties  = $null
					IsAccountExist  = $false
					IsDisabled      = $null
					Path            = $_.FullName
				}
			}
		} catch {
			Write-Error $_
		}
	}
}