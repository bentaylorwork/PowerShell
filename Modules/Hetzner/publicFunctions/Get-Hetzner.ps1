<# 
    .SYNOPSIS
       A light weight wrapper for interaction with the Hetzner Robot API using Powershell.
    .DESCRIPTION
        Allows Get requests to the Hetzner Robot API. More info on the can be found in the link below.
        http://wiki.hetzner.de/index.php/Robot_Webservice/en
	.PARAMETER userName
		Hetzner Robot API User Name
	.PARAMETER robotFunction
		Hetzner Robot Function E.G failover
	.PARAMETER robotFunctionAction
		Hetzner Robot Function Action E.G <failOverIP>
    .EXAMPLE
        Get-Hetzner -userName "<userName>" -robotFunction "IP"
	.EXAMPLE
        Get-Hetzner -userName "<userName>" -robotFunction "server" -robotFunctionAction "<serverIP>" 
    .EXAMPLE
        Get-HetznerCredential -userName "<userName>" | Get-Hetzner -robotFunction "IP"
	.EXAMPLE
		$credential = Get-HetznerCredential -userName "<userName>"
        $credential = Get-Hetzner -robotFunction "IP"
    .NOTES
        Written by Ben Taylor
        Version 1.0, 12.01.2015
#>
function Get-Hetzner () {
    [cmdletBinding(DefaultParameterSetName='userNameInline')]
	[OutputType([System.Array])]
    Param (
        [Parameter(Position=0, Mandatory=$true, ParameterSetName='userNameInline', HelpMessage='Hetzner Robot API User Name')]
        [string]
		$userName,
		[Parameter(Position=0, Mandatory=$true, ParameterSetName='storedCredential', ValueFromPipeline=$true, HelpMessage='Hetzner Robot API User Name')]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$credential,
        [Parameter(Position=1, Mandatory=$true, HelpMessage='Hetzner Robot Function E.G failover')]
        [ValidateSet('storagebox','snapshot','order', 'key', 'rdns', 'boot', 'wol', 'failover', 'reset', 'subnet', 'ip', 'server')]
        [string]
		$robotFunction,
		[Parameter(Position=2, Mandatory=$false, HelpMessage='Hetzner Robot Function Action E.G <failOverIP>')]
        [string]
		$robotFunctionAction
    )

    Write-Verbose -Message 'INFO: Creating Hetzner API URI'
    $hetznerUri = Get-hetznerURI -robotFunction $robotFunction -robotFunctionAction $robotFunctionAction

	Write-Verbose -Message 'INFO: Creating Hetzner API Credential'
	if($PSBoundParameters.ContainsKey('userName')) {
		$credential = Get-hetznerCredential -userName $userName
	}

    try {
        Write-Verbose -Message 'INFO: Querying Hetzner API'
        $hetznerResponse = Invoke-RestMethod -Uri $hetznerUri -Credential $credential -ContentType application/x-www-form-urlencoded

		#Return data thats not nested under a single heading
        Write-Verbose -Message 'INFO: Processing Hetzner API response'
		$hetznerResponse.$robotFunction
    } catch {
		$errorHash = Get-errorHash -errorResult $_.Exception.Response.GetResponseStream()
        Write-Error -Message "ERROR: There was a error querying the Hetzner API. More Info: $errorHash"
    }
}