<#
    .SYNOPSIS
       A light weight wrapper for interaction with the Hetzner Robot API using Powershell.
    .DESCRIPTION
        Allows Get requests to the Hetzner Robot API. More info on the can be found in the link below.
        http://wiki.hetzner.de/index.php/Robot_Webservice/en
	.PARAMETER userName
		Hetzner Robot API User Name
    .EXAMPLE
        Get-HetznerCredential -userName "<userName>" | Get-Hetzner -robotFunction "IP"
	.EXAMPLE
		$credential = Get-HetznerCredential -userName "<userName>"
    .NOTES
        Written by Ben Taylor
        Version 1.0, 12.01.2015
#>
function Get-HetznerCredential () {
    [cmdletbinding()]
	[outputType([System.Management.Automation.PSCredential])]
    Param (
        [Parameter(Mandatory=$True, HelpMessage="Hetzner Robot User Name")]
		[string]$userName
    )

    $robotPassword = Read-Host -Prompt "Enter Hetzner API Password" -AsSecureString
    New-Object System.Management.Automation.PSCredential ($userName, $robotPassword)
}