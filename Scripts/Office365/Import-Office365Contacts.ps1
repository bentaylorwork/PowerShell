function Import-Office365Contacts {
    <#
        .Synopsis
            Imports Office 365 Contacts From a CSV.
        .EXAMPLE
            Get-ChildItem '<path to logs>\*.log' | Import-Office365Contacts
        .EXAMPLE
            Import-Office365Contacts -path (Get-ChildItem '<path to files to import>\*csv')
        .NOTES
            CSV file fields
            ExternalEmailAddress,Name,FirstName,LastName,StreetAddress,City,StateorProvince,PostalCode,Phone,MobilePhone,Pager,HomePhone,Company,Title,OtherTelephone,Department,CountryOrRegion,Fax,Initials,Notes,Office,Manager
        .AUTHOR
            Ben Taylor - 30/03/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string[]]
        $path
    )

    Process {
        forEach($filePath in $path) {
            Import-Csv $filePath | ForEach-Object {
                try{
                    Write-Verbose "Creating Office 365 contact $($_.Name)"

                    $newMailContact = @{
                        Name                 = $_.Name
                        DisplayName          = $_.Name
                        ExternalEmailAddress = $_.ExternalEmailAddress
                        FirstName            = $_.FirstName
                        LastName             = $_.LastName
                    }

                    New-MailContact @newMailContact

                    Write-Verbose "Updating Office 365 contact $($_.Name)"

                    $mailContactDetails = @{
                        StreetAddress   = $_.StreetAddress
                        City            = $_.City
                        StateorProvince = $_.StateorProvince
                        PostalCode      = $_.PostalCode
                        Phone           = $_.Phone
                        MobilePhone     = $_.MobilePhone
                        Pager           = $_.Pager
                        HomePhone       = $_.HomePhone
                        Company         = $_.Company
                        Title           = $_.Title
                        OtherTelephone  = $_.OtherTelephone
                        Department      = $_.Department
                        Fax             = $_.Fax
                        Initials        = $_.Initials
                        Notes           = $_.Notes
                        Office          = $_.Office
                        Manager         = $_.Manager
                    }

                    Set-Contact $_.Name @mailContactDetails
                }
                catch
                {
                    Write-Error $_
                }
            }
        }
    }
}
