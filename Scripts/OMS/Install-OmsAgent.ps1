#Requires -RunAsAdministrator
#Requires -Version 5.0

<#
    .Synopsis
       Installs the OMS agent on remote computers.
    .DESCRIPTION
        Either downloads the installer from a URL or copies the installer via the powershell session. Can detected if a previous version is installed and skip if so. If allready installed WorkSpaceId and WorkSpaceKey added to previous install. Doesn't detect invalid workspace IDs or Keys.
    .EXAMPLE
        Install-OmsAgent -sourcePath 'c:\MMASetup-AMD64.exe' -workspaceID <workSpaceID> -workspaceKey <workSpaceKey> -Verbose
    .EXAMPLE
        Install-OmsAgent -computerName <computerName> -workspaceID <workSpaceID> -workspaceKey <workSpaceKey> -download -Verbose
    .OUTPUTS
       Output from this cmdlet (if any)
    .NOTES
        Ben Taylor
        07/07/2016
#>
function Install-OmsAgent {
    [CmdletBinding(DefaultParameterSetName='downloadOMS')]
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
        $downloadURL = "http://download.microsoft.com/download/0/C/0/0C072D6E-F418-4AD4-BCB2-A362624F400A/MMASetup-AMD64.exe",
        [Parameter(ParameterSetName='downloadOMS')]
        [Switch]
        $download,
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

                $psSession = New-PSSession -ComputerName $computer @commonSessionParams

                if($previousInstallSkip) {
                    Write-Verbose "$computer - Checking if OMS is Installed"                   
                    $job = Invoke-Command -Session $psSession -ScriptBlock {
                        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.displayName -eq 'Microsoft Monitoring Agent' }
                    } -AsJob -ErrorAction Stop

                    $job | Wait-Job | Out-Null
                
                    if($job.ChildJobs[0].JobStateInfo.State -ne 'Completed') {
                        # Using throw so goes directly to catch block.
                       Throw "$computer - An error occured querying previous install status"
                    }

                    Receive-Job $job -OutVariable isInstalled | Out-Null

                    if($isInstalled) {
                        Write-Verbose "$computer - OMS is installed so skipping install on this computer"     
                        $install = $false
                    }
                }

                if($install -eq $true){
                     $path = Invoke-Command -Session $pssession -ScriptBlock {
                        $path = Join-Path $ENV:temp "MMASetup-AMD64.exe"

                        # Check if file exists and if so remove
                        if(Test-Path $path) {
                            Remove-Item $path -force -Confirm:$false
                        }

                        $path
                     }

                    if($PSBoundParameters.download -eq $true) {
                        Write-Verbose "$computer - Trying to download installer from URL - $downloadURL"
                        $job = Invoke-Command -Session $psSession -ScriptBlock {
                            Invoke-WebRequest $USING:downloadURL -OutFile $USING:path -ErrorAction Stop | Out-Null
                        } -AsJob -ErrorAction Stop

                        $job | Wait-Job | Out-Null

                        if($job.ChildJobs[0].JobStateInfo.State -ne 'Completed') {
                            # Using throw so goes directly to catch block.
                           Throw 'An error occured downloading the file'
                        }
                    } elseIf($PSBoundParameters.sourcePath) {
                        Write-Verbose "$computer - Copying files over powershell session"

                        Copy-Item -Path $sourcePath -Destination (Split-path $path) -ToSession $psSession -Force
                    }

                    Write-Verbose "$computer - Trying to install OMS..."
                    $installString = $path + ' /C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 ' +  "OPINSIGHTS_WORKSPACE_ID=$workspaceID " + "OPINSIGHTS_WORKSPACE_KEY=$workSpaceKey " +'AcceptEndUserLicenseAgreement=1"'

                    $installSuccess = Invoke-Command -Session $psSession -ScriptBlock {
                        cmd.exe /C $USING:installString
                        $LASTEXITCODE
                    } -ErrorAction Stop

                    if($installSuccess -ne 0) {
                        Throw "$computer - OMS didn't install correctly based on the exit code"
                    } else {
                        Write-Verbose "$computer - OMS installed correctly"
                    }
                }
            } catch {
                Write-Error $_
            } Finally {
                Write-Verbose "$computer - Tidying up install files\sessions if needed"

                if($null -ne $psSession) {
                    try {
                        Invoke-Command -Session $pssession -ScriptBlock {
                            # Check if file exists and if so remove

                            if(Test-Path $USING:path) {
                                Remove-Item $USING:path -force -Confirm:$false
                            }
                        } -ErrorAction Stop
                    } catch {
                        Write-Verbose "$computer - Nothing to tidy up"
                    }
                    Remove-PSSession $psSession
                }
            }
        }
    }
}