function Find-DuplicateFiles {
    <#
        .Synopsis
            Checks if a file exists with the same name but a different file extension
        .EXAMPLE
            Get-ChildItem -filter *.xls -recurse | Select-Object -expandProperty fullname | Find-DuplicateFiles -fileExtension 'xlsx'
        .AUTHOR
            Ben Taylor - 12/07/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string[]]
        $path,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $fileExtension
    )
    process {
        forEach($filePath in $path) {
            try {
                $workingFile = ($filePath).substring(0, ($filePath).lastindexOf("."))
                $workingFile += '.'
                $workingFile += $fileExtension

                if(Test-Path -Path $workingFile) {
                    [pscustomobject]@{
                        action = 'destinationExists'
                        path   = $filePath
                    }
                }
            } catch {
                [pscustomobject]@{
                    action = 'erroronfile'
                    path   = $filePath
                }
            }
        }
    }
}
