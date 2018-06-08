function Restore-SPORecycleBinFile
{
    <#
        .Synopsis
            Restores files from a Sharepoint Online recycle bin by a users UPN or file path.
        .EXAMPLE
            Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
            Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

            Restore-SPORecycleBinByUserUPN -Credential (Get-Credential) -url 'https://test.sharepoint.com/sites/FileShare' -userUpn 'test@test.com'
        .EXAMPLE
            Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
            Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

            Restore-SPORecycleBinByUserUPN -Credential (Get-Credential) -url 'https://test.sharepoint.com/sites/FileShare' -path '/test/folderone'
        .NOTES
            Written by Ben Taylor
            Version 1.0, 06.06.2018
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]
        $Url,
        [Parameter(ParameterSetName='userUPN')]
        [ValidateNotNullorEmpty()]
        [string]
        $userUPN,
        [Parameter(ParameterSetName='path')]
        [ValidateNotNullorEmpty()]
        [string]
        $path
    )

    try
    {
        $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
        $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credential.UserName, $Credential.Password)
        $ctx.ExecuteQuery()
        $rb = $ctx.Site.RecycleBin
        $ctx.Load($rb)
        $ctx.ExecuteQuery()
    }
    catch
    {
        Write-Error $_

        return
    }

    If ($PSBoundParameters['userUPN'])
    {
        $list = $ctx.Site.RecycleBin | Where-Object { $_.DeletedByEmail -eq $userUPN  -and $_.ItemType -eq  'File' }
    }

    If ($PSBoundParameters['path'])
    {
        $list = $ctx.Site.RecycleBin | Where-Object { $_.DirName -like "*$path*"  -and $_.ItemType -eq  'File' }
    }

    if($list)
    {
        for ($i = 0; $i -lt $list.Count; $i++)
        {
            try
            {
                $list[$i].Restore()

                $ctx.ExecuteQuery()

                Write-Verbose ($list[$i].DirName + '/' + $list[$i].LeafName)
            }
            catch
            {
                Write-Error $_
            }
        }
    }
    else
    {
        Write-Error 'No files found'
    }

    $ctx.Dispose()
}
