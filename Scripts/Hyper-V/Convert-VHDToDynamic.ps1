function Convert-VHDToDynamic
{
    <#
      .Synopsis
         Convert Folder Of Fixed VHD's to Dynamic VHDXs
      .EXAMPLE
          Convert-VHDToDynamic -sourcePath 'c:\sourcePath\ -DestinationPath 'c:\destPath' -verbose
      .NOTES
          Written by Ben Taylor
          Version 1.0, 30.01.2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $sourcePath,
        [Parameter(Mandatory=$false, Position=1)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $DestinationPath
    )

    Write-Verbose 'Finding vhd or vhdx to convert'

    Get-ChildItem $sourcePath -Include ('*.vhdx', '*.vhd') -Recurse -file | ForEach-Object {
        Write-Verbose "Converting fixed $($_.FullName) to dynamic"

        Convert-VHD -Path $_.FullName -DestinationPath (Join-Path $DestinationPath (Split-Path -Leaf $_.FullName)) -VHDType Dynamic
    }
}
