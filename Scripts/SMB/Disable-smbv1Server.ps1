function Disable-smbv1Server ()
{
    <#
        .SYNOPSIS 
            Disables the SMB V1 server.
        .EXAMPLE
            Disable-smbv1Server
        .EXAMPLE
            Disable-smbv1Server -computerName 'computer-one', 'computer-two'
        .NOTES
            https://support.microsoft.com/en-us/help/2696547/how-to-enable-and-disable-smbv1,-smbv2,-and-smbv3-in-windows-vista,-windows-server-2008,-windows-7,-windows-server-2008-r2,-windows-8,-and-windows-server-2012

            Written by Ben Taylor
            Version 1.0, 15.05.2017
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
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
            if ($pscmdlet.ShouldProcess($computer, 'Disable-smbv1'))
            {
                try
                {
                    Invoke-Command -ComputerName $computer -ScriptBlock {

                        [version]$OSversion = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Version

                        if ($OSversion -ge [version]'6.2.0.0')
                        {
                            if ((Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol) -eq $true)
                            {
                                Set-SmbServerConfiguration -EnableSMB1Protocol $false -Confirm:$false -Force -WhatIf:$false
                            }
                        }
                        else
                        {
                            if(Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\SMB1')
                            {
                                $isSMBv1Enabled = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' | Select-Object -ExpandProperty SMB1

                                if ($isSMBv1Enabled -ne 0)
                                {
                                    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' SMB1 -Type DWORD -Value 0 -Force
                                }
                            }
                        }
                    } @commonParams 
                }
                catch
                {
                    Write-Error $_
                }
            }
        }
    }
}
