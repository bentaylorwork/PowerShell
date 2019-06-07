function Get-AzLoadBalancerNatRules {
    <#
    .SYNOPSIS
        Gets information about NAT rules from all or one of the load balancers in a subscription.
    .EXAMPLE
        Get-AzLoadBalancerNatRules
    .EXAMPLE
        Get-AzLoadBalancerNatRules -name 'loadbalancerone'
    .NOTES
        Written by Ben Taylor
        Version 1.1, 29.05.2019
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $name
        
    )

    if ($PSBoundParameters['name']) {
        $loadBalancers = Get-AzLoadBalancer -name $name
    } else {
        $loadBalancers = Get-AzLoadBalancer
    }

    if ($loadBalancers) {
        $loadBalancers | ForEach-Object {
            $FrontendIpConfigurations = $_.FrontendIpConfigurations
        
            ForEach ($natRule in $_.InboundNatRules) {
                $FrontendIpConfiguration = $FrontendIpConfigurations | Where-Object { $_.Name -eq ($natRule.FrontendIPConfiguration.Id -split '/')[10] }
        
                $PublicIpname = ($FrontendIpConfiguration.PublicIpAddress.Id -split '/')[8]
        
                [PSCustomObject]@{
                    Subscription                = ($_.Id -split '/')[2]
                    ResourceGroupName           = $_.ResourceGroupName
                    Location                    = $_.Location
                    LoadBalancerName            = $_.Name
                    FrontEndName                = $FrontendIpConfiguration.Name
                    FrontEndPublicIpName        = $PublicIpname
                    FrontEndNamePublicIpAddress = (Get-AzPublicIpAddress -Name $PublicIpname).IpAddress
                    InternalIpAddress           = (Get-AzNetworkInterface -Name ($natRule.BackendIPConfiguration.Id -split '/')[8]).IpConfigurations[0].PrivateIpAddress
                    InboundNatRuleName          = $natRule.Name
                    Protocol                    = $natRule.Protocol
                    FrontendPort                = $natRule.FrontendPort
                    BackendPort                 = $natRule.BackendPort
                    EnableFloatingIP            = $natRule.EnableFloatingIP
                }
            }
        }
    }
}
