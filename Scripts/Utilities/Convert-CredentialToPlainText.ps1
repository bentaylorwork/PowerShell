function Convert-CredentialToPlainText {
	<#
		.SYNOPSIS 
			Converts a credential to a plain text username and password.
		.NOTES
			Written by Ben Taylor
			Version 1.0, 05.01.2017
	#>
	[CmdletBinding()]
	[OutputType()]
	param (
		[Parameter(Mandatory=$true)]
		[pscredential]
		$credential
	)

	@{
		userName = $credential.UserName
		passWord = $credential.GetNetworkCredential().Password
	}
}
