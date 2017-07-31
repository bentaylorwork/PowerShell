function Install-MabsV2PreRequisites {
    <#
        .Synopsis
            Installs the required pre requisites for Azure Backup Server.
        .EXAMPLE
            Install-MabsV2PreRequisites
        .AUTHOR
            Ben Taylor - 21/07/2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param()

    Install-WindowsFeature -Name Hyper-V-PowerShell
    Install-WindowsFeature -Name Net-Framework-Core
}