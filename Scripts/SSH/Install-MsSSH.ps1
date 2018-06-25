function Install-MsSSH {
    <#
    .Synopsis
       Installs v7.7.1 of the Microsoft SSH implementation
    .EXAMPLE
       Install-MsSSH
    .NOTES
		Written by Ben Taylor
		Version 1.0, 25.06.2018
    #>
    [CmdletBinding()]
    Param
    (    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $uri = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.1.0p1-Beta/OpenSSH-Win64.zip',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $openSSHPath = 'C:\Program Files\OpenSSH'
    )

    if(Test-Path $openSSHPath)
    {
        Throw 'Installation path allready exists'
    }

    try {
        $sshInstaller = Join-Path $env:TEMP 'installer.zip'

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $webRequest = @{
            uri             = $uri
            UseBasicParsing = $true
            OutFile         = $sshInstaller
        }

        Invoke-WebRequest @webRequest

        $expandArchive = @{
            path            = $sshInstaller
            DestinationPath = $openSSHPath
            ErrorAction     = 'Stop'
        }

        Expand-Archive @expandArchive

        Copy-Item (Join-Path $openSSHPath 'OpenSSH-Win64\*') -Destination $openSSHPath -Recurse

        Remove-Item (Join-Path $openSSHPath 'OpenSSH-Win64') -Force -Recurse

        Set-Location -Path $openSSHPath

        powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1

        $firewallRule = @{
            Name        = 'sshd'
            DisplayName = 'OpenSSH Server (sshd)'
            Enabled     = 'True'
            Direction   = 'Inbound'
            Protocol    = 'TCP'
            Action      = 'Allow'
            LocalPort   = 22
            ErrorAction = 'Stop'

        }

        New-NetFirewallRule @firewallRule

        Start-Service sshd -ErrorAction Stop
        Set-Service sshd -StartupType Automatic -ErrorAction Stop
        Set-Service ssh-agent -StartupType Automatic -ErrorAction Stop
    }
    catch
    {
        if (Test-Path -Path $openSSHPath)
        {
            Set-Location -Path $openSSHPath

            Stop-Service sshd -ErrorAction Stop
            Stop-Service ssh-agent -ErrorAction Stop

            if (Test-Path 'uninstall-sshd.ps1')
            {
                powershell.exe -ExecutionPolicy Bypass -File 'uninstall-sshd.ps1'
            }

            if (Get-NetFirewallRule -Name $firewallRule.Name)
            {
                Remove-NetFirewallRule -Name $firewallRule.Name
            }

            Remove-Item $openSSHPath -Force -Recurse
        }

        Write-Error $_
    }
    finally
    {
        if (Test-Path -Path $sshInstaller)
        {
            Remove-Item $sshInstaller -Force -Recurse
        }
    }
}
