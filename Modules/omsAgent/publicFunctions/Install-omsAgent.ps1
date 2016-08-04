#Requires -Version 5.0

<#
	.Synopsis
		Installs the OMS agent on remote computers.
	.DESCRIPTION
		Either downloads the installer from a URL or copies the installer via the powershell session. Can detected if a previous version is installed and skip if so. If allready installed WorkSpaceId and WorkSpaceKey added to previous install. Doesn't detect invalid workspace IDs or Keys.
	.EXAMPLE
		Install-OmsAgent -sourcePath 'c:\MMASetup-AMD64.exe' -workspaceID '<workSpaceID>' -workspaceKey '<workSpaceKey>' -Verbose
	.EXAMPLE
		Install-OmsAgent -computerName <computerName> -workspaceID '<workSpaceID>' -workspaceKey '<workSpaceKey>' -Verbose
	.NOTES
		Written by Ben Taylor
		Version 1.0, 31.07.2016
#>
function Install-OmsAgent {
	[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low', DefaultParameterSetName='downloadOMS')]
	[OutputType([String])]
	Param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline=$True, valuefrompipelinebypropertyname=$true)]
		[ValidateNotNullOrEmpty()]
		[Alias('IPAddress', 'Name')]
		[string[]]
		$computerName = $env:COMPUTERNAME,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$workSpaceID,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]        
		$workSpaceKey,
		[Parameter(ParameterSetName='downloadOMS')]
		[ValidateNotNullOrEmpty()]
		[string]
		$downloadURL = 'http://download.microsoft.com/download/0/C/0/0C072D6E-F418-4AD4-BCB2-A362624F400A/MMASetup-AMD64.exe',
		[Parameter(ParameterSetName='localOMS')]
		[ValidateScript({Test-Path $_ })]
		[string]
		$sourcePath,
		[Parameter()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential,
		[Parameter()]
		[Switch]
		$previousInstallSkip
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
				$install = $true

				Write-Verbose "[$(Get-Date -Format G)] - $computer - Creating Remote PS Session"
				$psSession = New-PSSession -ComputerName $computer @commonSessionParams

				if($previousInstallSkip) {
					Write-Verbose "$computer - Checking if OMS is Installed"
					
					if(Get-omsAgentInternal -computerName $computer -session $psSession) {
						Write-Verbose "[$(Get-Date -Format G)] - $computer - OMS is installed so skipping install on this computer"     
						$install = $false
					}
				}

				if($install -eq $true){
					If ($Pscmdlet.ShouldProcess($computer, 'Install OMS Agent')) {
						 $path = Invoke-Command -Session $pssession -ScriptBlock {
							$path = Join-Path $ENV:temp "MMASetup-AMD64.exe"

							# Check if file exists and if so remove
							if(Test-Path $path) {
								Remove-Item $path -force -Confirm:$false
							}

							$path
						 }

						if($PSBoundParameters.sourcePath -eq $true) {
							Write-Verbose "[$(Get-Date -Format G)] - $computer - Copying files over powershell session"
							Copy-Item -Path $sourcePath -Destination (Split-path $path) -ToSession $psSession -Force
						} else {
							Write-Verbose "[$(Get-Date -Format G)] - $computer - Trying to download installer from URL - $downloadURL"
							Invoke-Command -Session $psSession -ScriptBlock {
								Invoke-WebRequest $USING:downloadURL -OutFile $USING:path -ErrorAction Stop | Out-Null
							} -ErrorAction Stop
						}

						Write-Verbose "$computer - Trying to install OMS..."
						$installString = $path + ' /C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 ' +  "OPINSIGHTS_WORKSPACE_ID=$workspaceID " + "OPINSIGHTS_WORKSPACE_KEY=$workSpaceKey " +'AcceptEndUserLicenseAgreement=1"'

						$installSuccess = Invoke-Command -Session $psSession -ScriptBlock {
							cmd.exe /C $USING:installString
							$LASTEXITCODE
						} -ErrorAction Stop

						if($installSuccess -ne 0) {
							Write-Error "$computer - OMS didn't install correctly based on the exit code"
						} else {
							if(Get-omsAgentInternal -computerName $computer -session $psSession) {
								Write-Verbose "[$(Get-Date -Format G)] - $computer - OMS installed correctly"
							} else {
								Write-Error "[$(Get-Date -Format G)] - $computer - OMS didn't install correctly based on the exit code"
							}
						}
					}
				}
			} catch {
				Write-Error $_
			} Finally {
				Write-Verbose "[$(Get-Date -Format G)] - $computer - Tidying up install files\sessions if needed"
				if($null -ne $psSession) {
					try {
						Invoke-Command -Session $pssession -ScriptBlock {
							if(Test-Path $USING:path) {
								Remove-Item $USING:path -force -Confirm:$false
							}
						} -ErrorAction Stop
					} catch {
						Write-Verbose "[$(Get-Date -Format G)] - $computer - Nothing to tidy up"
					}
					Remove-PSSession $psSession -whatif:$false -Confirm:$false
				}
			}
		}
	}
}