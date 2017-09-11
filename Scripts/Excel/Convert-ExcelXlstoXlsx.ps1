function Convert-ExcelXlstoXlsx {
    <#
        .Synopsis
            Converts a directory of Excel xls files to Excel xlsx
        .EXAMPLE
            Convert-ExcelXlstoXlsx -path 'c:\test', 'c:\test2'
        .EXAMPLE
            Convert-ExcelXlstoXlsx -path 'c:\test', 'c:\test2' -removeSourceFile
        .EXAMPLE
            'c:\test' | Convert-ExcelXlstoXlsx -removeSourceFile
        .AUTHOR
            Ben Taylor - 08/09/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript( {Test-Path -Path $_ } )]
        [string[]]
        $path,
        [switch]
        $removeSourceFile
    )

    begin {
        Add-Type -AssemblyName Microsoft.Office.Interop.Excel
    } process {
        forEach ($filePath in $path) {
            $workingFiles = Get-ChildItem -Path $filePath -Include *xls -recurse

            $workingFiles | ForEach-Object {
                Write-Verbose "Working on file $($_.fullname)"

                $workingFile = ($_.fullname).substring(0, ($_.FullName).lastindexOf(".")) + '.xlsx'

                if (-not (Test-Path -Path $workingFile)) {
                    Write-Verbose "Destination file $workingFile does not exist trying to convert"

                    try {
                        $xlFixedFormat     = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook
                        $excel             = New-Object -ComObject excel.application
                        $excel.visible     = $true
                        $excel.Interactive = $true

                        # Open read only incase file has read only password or file in use.
                        $workbook = $excel.workbooks.open($_.fullname, $null, $true)

                        Start-Sleep -Seconds 2

                        $workbook.saveas($workingFile, $xlFixedFormat)
                        $workbook.close()

                        if((Test-Path $workingFile) -and ($removeSourceFile -eq $true)) {
                            Remove-Item -path $_.fullname -Force
                        }
                    } catch {
                        Write-Error $_
                    } finally {
                        $excel.Quit()
                        $excel = $null
                        [gc]::collect()
                        [gc]::WaitForPendingFinalizers()
                    }
                }
            }
        }
    }
}
