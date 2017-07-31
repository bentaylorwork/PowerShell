function Add-Mabsv2AddAvailableDisk {
    <#
        .Synopsis
            Adds all available disks to an Azure Backup Server. Its possible to exclude a drive by using the parameter "excludeDrive"
        .EXAMPLE
            Add-Mabsv2AddAvailableDisk
        .EXAMPLE
            Add-Mabsv2AddAvailableDisk -excludeDrive d
        .AUTHOR
            Ben Taylor - 21/07/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty]
        [string]
        $excludeDrive = 'd'
    )

    Get-DPMDiskStorage -Volumes -All | Where-Object { $_.Tag -eq 'NotOwnedByDPM' -and $_.AccessPath -notlike "$excludeDrive*" } | Add-DPMDisk
}