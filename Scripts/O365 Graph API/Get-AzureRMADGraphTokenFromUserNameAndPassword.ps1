function Get-AzureRMADGraphTokenFromUserNameAndPassword()
{
    <#
        .Synopsis
            Gets a OAuth token from Azure AD for O365 using a username and password. Not xPlat.
        .EXAMPLE
            Get-AzureRMADGraphTokenFromUserNameAndPassword -tenantName contoso.onmicrosoft.com" -credential (Get-Credential)
        .EXAMPLE
            $azureADGraphToken = Get-AzureRMADGraphTokenFromUserNameAndPassword -tenantName contoso.onmicrosoft.com" -credential (Get-Credential)

            $graphGet = @{
                'Method'  = 'GET'
                'Uri'     = 'https://graph.microsoft.com/applications'
                'Headers' = @{
                    'Authorization' = 'Bearer {0}' -f $azureADGraphToken
                    'Content-Type'  = 'application/json'
                }
            }

            Invoke-RestMethod @graphGet
        .NOTES
            Written by Ben Taylor
            Version 1.0, 03.02.2018
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $tenantName,
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $credential
    )

    try
    {
        $tokenEndPoint  = 'https://login.microsoftonline.com/{0}/oauth2/v2.0/authorize' -f $tenantName

        $adCredentials  = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential($credential.UserName, $credential.GetNetworkCredential().Password)
        $authContext    = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext($tokenEndPoint)

        $token = $authContext.AcquireToken(
                    'https://graph.microsoft.com/',
                    '1950a258-227b-4e31-a9cf-717495945fc2',
                    $adCredentials
                )

        return $token.AccessToken
    }
    catch
    {
        Write-Error $_
    }
}
