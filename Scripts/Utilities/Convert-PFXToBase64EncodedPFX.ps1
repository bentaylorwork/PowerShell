function Convert-PFXToBase64EncodedPFX {
    <#
    .SYNOPSIS
        Converts a PFX to a BASE64 encoded PFX. The converted certificate can then be used in things like Azure ARM templates.
    .EXAMPLE
        Convert-PFXToBase64EncodedPFX -path 'c:\test.pfx'
    .EXAMPLE
        Convert-PFXToBase64EncodedPFX -path 'c:\test.pfx' -ExportPath 'c:\outPutfolder'
    .NOTES
        Written By: Ben Taylor (21/05/2019)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ((Test-path $_) -and ((Split-Path -Path $_ -Leaf).split('.') -eq 'pfx' )) {
                $true
            } else {
                $false
            }
        })]
        [string]
        $Path,
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            Test-path $_
        })]
        [string]
        $ExportPath = '.\'
    )

    $exportFile = Join-Path $ExportPath ((Split-Path -Path $Path -Leaf) + '.txt')

    if (Test-Path $exportFile) {
        Write-Error 'Export file allready exists.'
    } else {
        $fileContentBytes = Get-Content $Path -Encoding Byte

        [System.Convert]::ToBase64String($fileContentBytes) | Out-File $exportFile
    }
}
