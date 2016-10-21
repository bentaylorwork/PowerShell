enum Ensure
{
	Absent
	Present
}

[DscResource()]
class InstallSolidCP
{
	[DscProperty(Key)]
	[ValidateSet('Server', 'Enterprise Server', 'Portal')]
	[string]
	$component

	[DscProperty(Mandatory)]
	[Ensure]
	$ensure

	[DscProperty()]
	[pscredential]
	$portalPassword

	[DscProperty()]
	[pscredential]
	$serverPassword

	[DscProperty()]
	[string]
	$enterpriseServerURL

	Hidden[string] $installPath   = 'C:\SolidCP\'
	Hidden[string] $installerPath = 'C:\Program Files (x86)\SolidCP Installer\'

	# Sets solidCPs desired state.
	[void] Set()
	{
		Write-Verbose "Trying to set resource"
		$isSolidCPInstalled = $this.testSolidCP()

		Try 
		{
			If ($this.Ensure -eq [Ensure]::'Present') 
			{
				If (-not $isSolidCPInstalled) 
				{
					#Check if installer is intalled and if not install
					if(-not ($this.isSolidCPInstaller()))
					{
						$this.installSolidCPInstaller()
					}

					$this.installSolidCPComponent()
				}
			}
			Else
			{
				If ($isSolidCPInstalled) 
				{
					$this.removeSolidCPComponent()
				}
			}
		}
		Catch
		{
			Write-Verbose $_
		}
	}

	# Tests solidCP is in the DesiredState.
	[bool] Test()
	{
		$present = $this.testSolidCP()

		if ($this.Ensure -eq [Ensure]::Present)
		{
			return $present
		}
		else
		{
			return -not $present
		}
	}

	# Gets solidCP current state.
	[InstallSolidCP] Get()
	{
		If ($this.testSolidCP()) 
		{
			$this.Ensure = [Ensure]::Present
		} 
		Else 
		{
			$this.Ensure = [Ensure]::Absent
		}

		return $this
	} 

	#Testing SolidCP
	[bool] testSolidCP()
	{
		$Present = $true

		$pathToTest = Join-Path $this.installPath $this.component

		if (-not (Test-Path $pathToTest))
		{
			$Present = $false
		}

		return $Present
	}

	#Installing SolidCP
	[void] installSolidCPComponent()
	{
		$_installerPath = (Join-Path $this.installerPath SolidCP.SilentInstaller.exe)

		If($this.component -eq 'Server')
		{
			Write-Verbose "Installing the SolidCP Server"

			$_serverPassword = $this.getPlainPasswordFromCredential($this.serverPassword)
			$arguments = "/cname:`"$($this.component)`" /passw:`"$_serverPassword`""

			Start-Process -FilePath $_installerPath -Argumentlist $arguments -wait -ErrorAction Stop
		}
		elseif($this.component -eq 'Enterprise Server')
		{
			Write-Verbose "Installing the SolidCP Enterprise Server"

			$_portalPassword = $this.getPlainPasswordFromCredential($this.portalPassword)
			$arguments = "/cname:`"$($this.component)`" /passw:`"$_portalPassword`""

			Start-Process -FilePath $_installerPath -Argumentlist $arguments -wait -ErrorAction Stop
		}
		elseif($this.component -eq 'Portal')
		{
			Write-Verbose "Installing the SolidCP Portal"

			$arguments = "/cname:`"$($this.component)`" /esurl:`"$($this.enterpriseServerURL)`""

			Start-Process -FilePath $_installerPath -Argumentlist $arguments -wait -ErrorAction Stop
		}
	}

	#Removing SolidCP
	[void] removeSolidCPComponent()
	{
		$componentInfo = $this.getInstallerConfig() | Where-Object { $_.component -eq $this.component }
		Write-Verbose ($componentInfo.component | Out-String)

		$componentInfo | ForEach-Object {
			Write-Verbose "Removing Component - $($_.component)"

			#If enterprise server run addtional clean up
			if($_.component -eq 'Enterprise Server') 
			{
				$this.removeService('SolidCP Scheduler')
			}

			if(Get-Website -Name $_.settings.WebSiteId -ErrorAction SilentlyContinue)
			{
				Remove-Website -Name $_.settings.WebSiteId
			}

			#No check as Get-ChildItem –Path IIS:\AppPools requires the importing of the web administration module to setup drive
			Remove-WebAppPool -name $_.settings.ApplicationPool -ErrorAction SilentlyContinue

			if(Test-Path $_.settings.InstallFolder -ErrorAction SilentlyContinue) 
			{
				Remove-Item $_.settings.InstallFolder -Recurse -Force -ErrorAction SilentlyContinue
			}

			$this.removeLocalUser($_.settings.UserAccount)
		}

		#Check if install folder is empty if so run additional clean up
		if(-not ((Get-ChildItem -LiteralPath $this.installPath -Force | Select-Object -First 1 | Measure-Object).Count -ne 0))
		{
			Write-Verbose 'Running Additonal Clean Up'
			if(Test-Path $this.installPath -ErrorAction SilentlyContinue)
			{
				Remove-Item $this.installPath -force
			}

			if(Test-Path $this.installerPath) {
				$this.removeSolidCPInstaller()
			}
		}
	}

	#Installing SolidCP Installer
	[void] installSolidCPInstaller()
	{
		$tempPath = Join-Path $env:TMP SolidCPInstaller.msi

		$solidCpVersion = ([xml](Invoke-RestMethod "http://installer.solidcp.com/Data/ProductReleasesFeed-1.0.xml").TrimStart('ï»¿')).components.component.releases.release | Select-Object -ExpandProperty Version | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
		Invoke-WebRequest "http://installer.solidcp.com/Files/$solidCpVersion/SolidCPInstaller.msi" -OutFile $tempPath

		Start-Process -FilePath $tempPath -ArgumentList '/qb IACCEPTSQLNCLILICENSETERMS=YES' -Wait

		Remove-Item $tempPath -Force
	}

	#Removing SolidCP Installer
	[void] removeSolidCPInstaller()
	{
		if($this.isSolidCPInstaller())
		{
			$uninstall = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.displayName -eq 'SolidCP Installer' }  | Select-Object UninstallString

			if ($uninstall)
			{
				$uninstall = ($uninstall.UninstallString -Replace 'msiexec.exe', '' -Replace '/I', '' -Replace '/X', '').trim()
				Start-Process 'msiexec.exe' -arg "/X $uninstall /qb" -Wait
			}
		}
	}

	[bool] isSolidCPInstaller()
	{
		$isInstalled = $false

		if(Test-Path (Join-Path $this.installerPath SolidCP.SilentInstaller.exe))
		{
			if(Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*)
			{
				$isInstalled = $true
			}
		}

		return $isInstalled
	}

	#Removing Local User
	[void] removeLocalUser($userName) 
	{
		try 
		{
			$ADSIComp = [adsi]"WinNT://$env:COMPUTERNAME"
			$ADSIComp.Delete('User', $userName)
		}
		catch
		{
			Write-Verbose 'User Not Found'
		}
	}

	#Removing Service
	[void] removeService($service) 
	{
		if(Get-Service $service -ErrorAction SilentlyContinue) 
		{
			Stop-Service $service -Force
			Get-CimInstance -ClassName win32_service -Filter "Name LIKE '$service'" | Invoke-CimMethod -methodname Delete
		}
	}

	#Get SolidCP.Installer.exe.config config variables
	[object] getInstallerConfig() 
	{
		$array = @()

		$xml = New-Object -TypeName XML
		$xml.Load((Join-Path $this.installerPath SolidCP.Installer.exe.config))
		$xml.configuration.installer.components.ChildNodes | ForEach-Object {

			$hash = $this.getHashTableFromConfig($_.settings.add)

			$array += [psCustomObject] @{
				component = $hash.ComponentCode
				id        = $_.id
				settings  = $hash
			}
		}

		return $array
	}

	#Converts XML add keys to hash table
	[object] getHashTableFromConfig($xmlInput)
	{
		$hash = @{}

		$xmlInput | ForEach-Object { 
			if($null -ne $_.key) 
			{
				$hash += @{$_.key = $_.value} 
			}
		}

		return $hash
	}

	#convert a securestring to a plain text password
	[string] getPlainPasswordFromCredential($secureStringToConvert) {
		Return $secureStringToConvert.GetNetworkCredential().Password
	}
}