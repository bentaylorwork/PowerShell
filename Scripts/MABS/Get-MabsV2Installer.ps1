function Get-MabsV2Installer {
    <#
        .Synopsis
            Downloads and Extracts Microsoft Azure Backup Server V2.
        .EXAMPLE
            Get-MabsV2Installer
        .EXAMPLE
            Get-MabsV2Installer -doNotExtract
        .AUTHOR
            Ben Taylor - 21/07/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]
        $workingPath = $env:TEMP,
        [Parameter(Mandatory = $false)]
        [switch]
        $doNotExtract
    )

    $mabsFilesToDownload = @('https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller.exe',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-1.bin',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-2.bin',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-3.bin',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-4.bin',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-5.bin',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-6.bin',
                            'https://download.microsoft.com/download/C/9/3/C93CABA5-2776-4417-8DB2-20B85E6EBA3B/MicrosoftAzureBackupServerInstaller-7.bin'
                            )

    $fileList = @()

    $mabsFilesToDownload | ForEach-Object {
        $outFilePath = Join-Path $workingPath ($_.Substring($_.LastIndexOf("/") + 1))
        $fileList += $outFilePath

        if(Test-Path $outFilePath){
            Remove-Item -Path $outFilePath
        }

        Invoke-WebRequest -UseBasicParsing -Uri $_ -OutFile $outFilePath
    }

    if($doNotExtract -eq $false) {
        Start-Process (($fileList -match 'exe' | Out-String).trim()) /SILENT -Wait

        Remove-Item -path $fileList
    }
}