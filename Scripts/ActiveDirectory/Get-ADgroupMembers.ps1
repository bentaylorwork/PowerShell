Function Get-ADgroupMembers() {
	<#
		.SYNOPSIS 
			Get all the memember foe every group in Active Directory
		.EXAMPLE
                  Import-Module activedirectory
			Get-ADgroupMembers | Export-Csv -path 'c:\test.csv'
		.NOTES
			Written by Ben Taylor
			Version 1.0, 26.10.2016
	#>
	[CmdletBinding()]
	[OutputType()]
	param()

      try
      {
            $adGroups = Get-ADGroup -Filter 'name -like "*"'

            foreach($adGroup in $adGroups)
            {
                  $adGroup | Get-ADGroupMember -ea 0 -Recursive | ForEach-Object {

                        [PSCustomObject]@{
                              GroupName = $adGroup.Name
                              Name      = $_.Name
                              RACF      = $_.SamAccountName
                        }
                  }
            }
      }
      catch
      {
            Write-Error $_
      }
}
