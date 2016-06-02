function Test-vLanInUse () {
    <#
        #Requires -Modules { VirtualMachineManager } 
        .SYNOPSIS 
            A function to query if a VLAN exists in SCVMM.
        .EXAMPLE
            Test-vlaninUse -vlantocheck $vlanToCheck
        .NOTES
            Written by Ben Taylor
            Version 1.0, 01.06.2016
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [ValidateRange(1, 4095)]
        [Int]$vlanToCheck
    )

    $vlanResult = (Get-SCLogicalNetworkDefinition).SubnetVLANs | Where-Object { $_.VLanID -eq $vlanToCheck }
    
    if($null -ne $vlanResult) {
        $true
    } else {
        $false 
    }
}
