function Install-SoonRAgent
{
	<#
	.Synopsis
		Installs the SoonR Agent on remote and local computers
	.DESCRIPTION
		Installs the SoonR Agent on remote and local computers. Assumes C: is the system drive.
	.EXAMPLE
		Install-SoonRAgent -computername 'computer-one' -path 'c:\install\soonRInstaller.exe'
	.EXAMPLE
		'computer-one', 'computer-two' | Install-SoonRAgent -path 'c:\install\soonRInstaller.exe'
	.NOTES
		Written by Ben Taylor
		Version 1.0, 13.11.2016
	#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
	[OutputType()]
	Param
	(
		[Parameter(Mandatory=$false, 
				   ValueFromPipeline=$true,
				   ValueFromPipelineByPropertyName=$true,
				   Position=0)]
		[ValidateNotNullOrEmpty()]
		[string[]]
		$computerName = $env:computername,
		[Parameter(Mandatory=$true, Position=1)]
		[ValidateScript({ Test-Path $_ })]
		[string]
		$path,
		[Parameter(Mandatory=$false)]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential
	)

	Begin {
		$commonSessionParams = @{
			ErrorAction = 'Stop'
		}

		If ($PSBoundParameters['Credential']) {
			$commonSessionParams.Credential = $Credential
		}
	} Process {
		forEach ($computer in $computerName) {
			try {
				if ($pscmdlet.ShouldProcess($computer, 'Install-SoonRAgent')) {
					Write-Verbose "$computer - Creating remote session"

					$psSession = New-PSSession -ComputerName $computer @commonSessionParams

					$remoteInstallerpath = Invoke-Command -Session $psSession -ScriptBlock {
						Join-Path ([environment]::GetEnvironmentVariable('temp','machine')) soonRAgent.exe
					} -ErrorAction Stop 

					Write-Verbose "$computer - Copying Installer"
					Copy-Item -Path $path -Destination ($remoteInstallerpath -replace [regex]::Escape('c:\'), "\\$computer\C$\") -Force @commonSessionParams

					Write-Verbose "$computer - Installing SoonR agent"

					Invoke-Command -Session $psSession -ScriptBlock {
						$args = @(
									'/install'
									'/quiet'
									'/norestart'
						)

						Start-Process $USING:remoteInstallerpath -ArgumentList $args -Wait
					} -ErrorAction Stop 
				}
			} catch {
				Write-Error $_
			} finally {
				Write-Verbose "$computer - Tidying up install files\sessions if needed"

				if($null -ne $psSession) {
					try {
						Invoke-Command -Session $pssession -ScriptBlock {
							# Check if file exists and if so remove
							if(Test-Path $USING:remoteInstallerpath) {
								Remove-Item $USING:remoteInstallerpath -force -Confirm:$false -WhatIf:$false
							}
						} -ErrorAction Stop
					} catch {
						Write-Error $_
					}

					Remove-PSSession $psSession -Confirm:$false -WhatIf:$false
				}
			}
		}
	}
}