#Helper Function - create URL to query API on
function Get-hetznerURI () {
    [cmdletBinding()]
	[OutputType([String])]
    Param (
        [Parameter(HelpMessage="Hetzner Robot URL builder")]
        [String]
		$hetznerRobotUrl='https://robot-ws.your-server.de/', 
		$robotFunction, 
		$robotFunctionAction
    )

    if($null -ne $robotFunctionAction) {
        $robotFunctionAction = $robotFunctionAction.toLower()
    }
    
    $hetznerRobotUrl + ($robotFunction.toLower()) + '/' + $robotFunctionAction
}