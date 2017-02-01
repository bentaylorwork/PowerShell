function Get-AzureRmVHDStatus
{
    <#
        .Synopsis
           Gets the lease status of every vhd in a subscription. Works by wrapping existing cmdLets.
        .EXAMPLE
            Get-AzureRmVHDStatus
        .NOTES
            Written by Ben Taylor
            Version 1.0, 31.01.2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param()

    $vhds = Get-AzureRmStorageAccount | Get-AzureStorageContainer | Get-AzureStorageBlob | Where-Object {$_.Name -match '\.vhd$'}

    forEach($vhd in $vhds)
    {
        [psCustomObject]@{
                    Name           = $vhd.Name
                    URI            = $vhd.ICloudBlob.Uri
                    StorageAccount = $Vhd.Context.StorageAccountName
                    LeaseState     = $vhd.icloudblob.Properties.LeaseState
                    LeaseStatus    = $vhd.icloudblob.Properties.LeaseStatus
                    sizeGB         = [math]::Round(($vhd.Length/1GB),2)
                    LastModified   = $vhd.LastModified
        }
    }
}
