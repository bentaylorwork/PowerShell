function Get-SPOCryptoFileExtensionBlackList
{
    <#
    .Synopsis
        Gets the latest RansemWare extensions from 'https://fsrm.experiant.ca/api/v1/get' as this seems to be the most update list.
    .EXAMPLE
        Get-SPOCryptoFileExtensionBlackList
    .EXAMPLE
        $credential = Get-Credential
        $sharepointUrl = 'https://<tenantVanityDomian>-admin.sharepoint.com/'

        # Connect to SharePoint
        Connect-SPOService –url $sharepointUrl -Credential $credential

        # Set File Extenstion Restriction
        Set-SPOTenantSyncClientRestriction -ExcludedFileExtensions ((Get-SPOCryptoFileExtensionBlackList) -join ';' )
    .NOTES
        Written by Ben Taylor
        Version 1.0, 24.01.2017
    #>
    [CmdletBinding()]
    Param()

    Write-Verbose 'Getting up to date ransomware file extensions'
    $cryptoFileExtensions = Invoke-WebRequest -Uri "https://fsrm.experiant.ca/api/v1/get" | Select-Object -ExpandProperty content | ConvertFrom-Json | Select-Object -ExpandProperty filters 

    ForEach($cryptoFileExtension in $cryptoFileExtensions)
    {
        Write-Verbose 'Sorting extension from files'
        if($cryptoFileExtension.Substring(2) -match "^[a-zA-Z0-9]*$")
        {
            if('' -ne $cryptoFileExtension.Substring(2))
            {
                $cryptoFileExtension.Substring(2)
            }
        }
    }
}
