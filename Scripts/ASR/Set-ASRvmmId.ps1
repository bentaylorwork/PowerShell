function Set-ASRvmmId ()
{
    <#
        .SYNOPSIS 
            Adds the VMM ID to the correct registry key to allow the ASR agent to install.
        .EXAMPLE
            Set-ASRvmmId -VMMid '234234-2342423-23423442'
        .EXAMPLE
            Set-ASRvmmId -computerName 'computer-one', 'computer-two' -VMMid '234234-2342423-23423442'
        .EXAMPLE
            'computer-one', 'computer-two' | Set-ASRvmmId -VMMid '234234-2342423-23423442'
        .NOTES
            Written by Ben Taylor
            Version 1.0, 09.08.2017
    #>
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $True, valuefrompipelinebypropertyname = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('IPAddress', 'Name')]
        [String[]]
        $computerName = $env:COMPUTERNAME,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMMId,
        [Parameter(Mandatory = $false, Position = 2)]
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
                Invoke-Command -ComputerName $computer -ScriptBlock {
                    if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft System Center Virtual Machine Manager Server\Setup')
                    {
                        $vmmIdSetting = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft System Center Virtual Machine Manager Server\Setup' | Select-Object -ExpandProperty VmmID

                        if ($vmmIdSetting -ne $VMMId)
                        {
                            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft System Center Virtual Machine Manager Server\Setup' -Name "VmmID" -Value $VMMId
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
