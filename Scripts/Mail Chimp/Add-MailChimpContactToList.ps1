Function Add-MailChimpContactToList {
    <#
        .SYNOPSIS
            Adds a comntact to a Mail Chimp distribution list
        .EXAMPLE
            $apiKey = Read-Host -asSecureString

            Add-MailChimpContactToList -emailAddress 'user@domain.com' -listId '323fsf232' -firstname 'John' -lastname 'Doe' -region 'us17' -apiKey $apiKey
        .AUTHOR
            Ben Taylor - 24/11/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $emailAddress,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]  
        $listId,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]  
        $firstname,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]  
        $lastName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]  
        $region,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [securestring]  
        $apiKey
    )

    $body =  @{
        email_address = $emailAddress
        status        = 'subscribed'
        merge_fields  = @{
            FNAME = $firstname
            LNAME = $lastName
        }
    }

    $mailChimpParams = @{
        uri     = 'https://{0}.api.mailchimp.com/3.0/lists/{1}/members' -f $region, $listId
        Method  = 'POST'
        Headers = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("_user_:$($apiKey)"))
        }
        Body    = $body | ConvertTo-Json
    }

    Invoke-RestMethod @mailChimpParams
}
