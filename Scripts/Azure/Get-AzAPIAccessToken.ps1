function Get-AzAPIAccessToken {
    <#
    .SYNOPSIS
        Get a Access Token from Azure AD for use with API
    .EXAMPLE
        $tokenSplat = @{
            clientId     = '49e59f85-272a-405a-83c0-d4845309916e'
            clientSecret = '6FFfKdsdfsdfVSJrJgbFRk/6MFICsdfsdfPS5pzdK3c='
            tenantDomain = 'tenant.onmicrosoft.com'
        }

        Get-AzureRMAccessToken @tokenSplat
    .NOTES
        Writen By: Ben Taylor ( ben@bentaylor.work )
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [guid]
        $clientId,
        [Parameter(Mandatory = $true)]
        [string]
        $clientSecret,
        [Parameter(Mandatory = $true)]
        [string]
        $tenantDomain
        
    )
    $invokeRestMethodSplat = @{
        'uri'    = ('https://login.microsoftonline.com/{0}/oauth2/token?api-version=1.0' -f $tenantDomain)
        'Method' = 'POST'
        'Body'   = @{
            client_id     = $clientId;
            client_secret = $clientSecret;
            scope         = 'user_impersonation ';
            grant_type    = 'client_credentials';
            resource      = 'https://management.azure.com'
        }
        ContentType = "application/x-www-form-urlencoded"
    }
    
    Invoke-RestMethod @invokeRestMethodSplat | Select-Object -ExpandProperty access_token
}