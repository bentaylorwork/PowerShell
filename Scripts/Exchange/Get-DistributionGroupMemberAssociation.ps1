#Requires -RunAsAdministrator

Function Get-DistributionGroupMemberAssociation() {
    <#
        .SYNOPSIS
            Gets Exchange distribution groups and its members.
        .EXAMPLE
            Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
            Get-DistributionGroupMemberAssociation
        .NOTES
            Written by Ben Taylor
            Version 1.0, 23.11.2016
    #>
    [CmdletBinding()]
    [OutputType()]
    param()

    Get-DistributionGroup | Sort-Object -Property DisplayName | ForEach-Object {
        $distributionGroupName = $_.displayname
        $distributionGroupPrimarySmtpAddress = $_.PrimarySmtpAddress

        Get-DistributionGroupMember $distributionGroupName | Select-Object @{Label = "DistributionGroupName"; Expression = {$distributionGroupName}}, @{Label = "DistributionGroupPrimarySmtpAddress"; Expression = {$distributionGroupPrimarySmtpAddress}}, DisplayName, Alias, PrimarySmtpAddress , RecipientType
    }
}
