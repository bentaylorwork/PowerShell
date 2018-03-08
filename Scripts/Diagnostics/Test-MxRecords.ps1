function Test-MxRecords {
    <#
      .Synopsis
         Tests if a domain has the correct MX records. Uses a wild card each side of the domain to match.
      .EXAMPLE
            Test-MxRecords -name 'test.com', 'test1.com' -domain 'smtp.test.com'
      .EXAMPLE
            Test-MxRecords -name 'test.com' -domain 'smtp.test.com' -server '8.8.4.4'
      .NOTES
          Written by Ben Taylor
          Version 1.0, 29.11.2016
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String[]]
        $name,
        [Parameter()]
        [String]
        $server = '8.8.8.8',
        [Parameter()]
        [String]
        $domain
    )

    foreach($acceptedDomain in $name) {
        try {
            $queriedDomain = $acceptedDomain | Resolve-DnsName -Server $server -Type Mx -ErrorAction Stop

            if(-not($queriedDomain.NameExchange -Like ('*{0}*' -f $domain))) {
                [pscustomobject]@{
                    'name'         = $queriedDomain.Name
                    'NameExchange' = $queriedDomain.NameExchange
                }
            }
        } catch {
            [pscustomobject]@{
                'name'         = $queriedDomain.Name
                'NameExchange' = $null
            }
        }
    }
}
