<#
    .Synopsis
        Converts plain text IIS logs into a ps Object
    .DESCRIPTION
        Converts plain text IIS logs into a ps Object
    .EXAMPLE
        Get-ChildItem '<path to logs>\*.log' | Convert-IISLogsToObject | Sort-Object c-ip -Unique
    .EXAMPLE
        Convert-IISLogsToObject -path (Get-ChildItem '<path to logs>\*log') | Where-Object { $_.'cs-username' -eq '<userName>' } | Sort-Object c-ip -Unique
    .NOTES
        General notes
    .AUTHOR
        Ben Taylor - 09/07/2016
#>
function Convert-IISLogsToObject {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string[]]
        $path
    )

    Process {
        forEach($filePath in $path) {
            $headers = (Get-Content -Path $filePath -TotalCount 4 | Select -First 1 -Skip 3) -replace '#Fields: ' -split ' '
            Get-Content $filePath | Select-String -Pattern '^#' -NotMatch | ConvertFrom-Csv -Delimiter ' ' -Header $headers
        }
    }
}
