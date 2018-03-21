Function Set-MailAssureOutGoingDomainUser
{
    <#
    .Synopsis
        A function to set a outgoing user on a domain
    .EXAMPLE
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

        Get-AcceptedDomain | Select-Object -ExpandProperty DomainName | Set-MailAssureOutGoingDomainUser -domainCredential (Get-Credential) -credential (Get-Credential) -verbose
    .EXAMPLE
        $domains = @('domainone.com', 'domaintwo.com')

        Set-MailAssureOutGoingDomainUser -domain $domains -domainCredential (Get-Credential) -credential (Get-Credential) -verbose
    .NOTES
        Written By: Ben Taylor
        Date:       20/03/3018
        Version:    1.0

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true,Position = 0)]
        [string[]]
        $domain,
        [Parameter(Mandatory = $true )]
        [pscredential]
        $domainCredential,
        [Parameter(Mandatory = $true )]
        [pscredential]
        $credential
    )

    Process
    {
        foreach($dom in $domain) {
            try
            {
                Write-Verbose "Trying to set outgoing user on Domain [$dom]"

                $uri = 'https://login.antispamcloud.com/api/outgoingusers/add/domain/{0}/username/{1}/password/{2}/' -f $dom, $domainCredential.UserName, $domainCredential.GetNetworkCredential().Password
    
                $response = Invoke-WebRequest -Uri $uri -Credential $credential
        
                if($response.statuscode -ne 200 -or (-not ($response.Content -like "*SUCCESS*")))
                {
                    Write-Error "Problem setting outgoing user on Domain [$domain]"

                    [pscustomobject]@{
                        status      = 'ERROR'
                        Description = $response.Content
                        Domain      = $dom
                    }

                    break
                }

                Write-Verbose "Outgoing user set correctly on Domain [$dom]"

                [pscustomobject]@{
                    status      = 'SUCCESS'
                    Description = $response.Content
                    Domain      = $dom
                }
            }
            catch
            {
                Write-Error $_

                [pscustomobject]@{
                    status      = 'ERROR'
                    Description = $_
                    Domain      = $dom
                }
            }
        }
    }
}
