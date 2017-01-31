function Import-Office365DistributionListFromCSV
{
    <#
        .Synopsis
            Imports Distribution Groups from a CSV into Office 365
        .DESCRIPTION
            Imports Distribution Groups from a CSV into Office 365
        
            Example CSV
            --------------------------------------------------------------------------
            DisplayName,EmailAddress,Notes
            'Distribution One',dist@test.com,This is for junk
            --------------------------------------------------------------------------
        .EXAMPLE
            Import-Office365DistributionListFromCSV -path 'path to CSV'
        .NOTES
            Ben Taylor - 02/12/2016
    #>
    [CmdletBinding()]
    [OutputType()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateScript({ Test-Path $_ })]
        [string[]]
        $path
    )

    Process
    {
        forEach($filePath in $path)
        {
            $distributionGroups = Import-Csv -Path $filePath

            if($distributionGroups)
            {
                $distributionGroups | ForEach-Object {
                    try
                    {
                        Write-Verbose "Distribution Group - $($_.DisplayName) - Trying To Add"

                        $office365UserDetails  = @{
                                                    Name               = $_.DisplayName
                                                    DisplayName        = $_.DisplayName
                                                    PrimarySmtpAddress = $_.EmailAddress
                                                    notes              = $_.Notes
                                                    errorAction        = 'Stop'
                                                  }

                        New-DistributionGroup @office365UserDetails

                        Write-Verbose "Distribution Group - $($_.DisplayName) - Added successfully"
                    }
                    catch
                    {
                        Write-Error $_
                    }
                }
            }
            else
            {
                Write-Error 'Nothing found to import.'
            }
        }
    }
}
