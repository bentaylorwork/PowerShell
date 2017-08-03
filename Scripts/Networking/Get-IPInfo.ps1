function Get-IPInfo
{
    <#
        .Synopsis
            Allows the easy retrieval of IP information
        .EXAMPLE
            Get-IPInfo
        .EXAMPLE
            Get-IPInfo -ip 1.1.1.1, 2.2.2.2
        .EXAMPLE
            1.1.1.1, 2.2.2.2 | Get-IPInfo
        .NOTES
            Written by Ben Taylor
            Version 1.0, 06.10.2016
    #>
    [CmdletBinding()]
    [OutputType()]
    Param (
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateScript({ [bool]($_ -as [ipaddress] )} )]
        [string[]]
        $ip = (Invoke-RestMethod -Uri http://checkip.amazonaws.com/)
    )

    Process
    {
        forEach($_ip in $ip)
        {
            Invoke-RestMethod -Uri "http://geoip.nekudo.com/api/$_ip"| Select-Object -ExpandProperty Country -Property City, IP, Location
        }
    }
}
