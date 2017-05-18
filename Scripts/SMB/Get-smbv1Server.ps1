function Get-smbv1Server ()
{
    <#
        .SYNOPSIS 
            A function to query if the SMB v1 server is enabled on a OS.
        .EXAMPLE
            Get-smbv1Server
        .EXAMPLE
            Get-smbv1Server -computerName 'computer-one', 'computer-two'
        .NOTES
            https://support.microsoft.com/en-us/help/2696547/how-to-enable-and-disable-smbv1,-smbv2,-and-smbv3-in-windows-vista,-windows-server-2008,-windows-7,-windows-server-2008-r2,-windows-8,-and-windows-server-2012

            Written by Ben Taylor
            Version 1.0, 15.05.2017
    #>
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $True, valuefrompipelinebypropertyname = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('IPAddress', 'Name')]
        [String[]]
        $computerName = $env:COMPUTERNAME,
        [Parameter(Mandatory = $false, Position = 1)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    Begin
    {
        $commonParams = @{
            ErrorAction = 'Stop'
        }

        If ($PSBoundParameters['Credential']) {
            $commonParams.Credential = $Credential
        }
    }
    Process
    {
        forEach ($computer in $computerName)
        {
            try
            {
                $isSmbV1 = Invoke-Command -ComputerName $computer -ScriptBlock {
                    $isSmbV1 = $false

                    [version]$OSversion = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Version

                    if ($OSversion -ge [version]'6.2.0.0')
                    {
                        if ((Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol) -eq $true)
                        {
                            $isSmbV1 = $true
                        }
                    }
                    else
                    {
                        if(Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\SMB1')
                        {
                            $isSMBv1Enabled = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' | Select-Object -ExpandProperty SMB1

                            if ($isSMBv1Enabled -eq 1)
                            {
                                $isSmbV1 = $true
                            }
                        }
                        else
                        {
                            $isSmbV1 = $true
                        }
                    }

                    $isSmbV1
                } @commonParams

                [psCustomObject]@{
                    computername   = $computer
                    isSMBv1Enabled = $isSmbV1
                }
            }
            catch
            {
                Write-Error $_
            }
        }
    }
}
