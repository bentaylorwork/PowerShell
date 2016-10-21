$ConfigurationData = @{
	AllNodes = @(
		@{
			NodeName = '*'
			PSDscAllowPlainTextPassword = $true
		 }
		@{
			NodeName = 'localhost'
		 }
	)
}


Configuration solidCP
{
	Import-DscResource –ModuleName PSDesiredStateConfiguration
	Import-DSCResource -ModuleName InstallSolidCP

	Node $AllNodes.NodeName {
		WindowsFeature netFrameworkCore
		{
			Name   = 'NET-Framework-core'
			Ensure = 'Present'
		}
	
		WindowsFeature WebServerRole
		{
			Name      = 'Web-Server'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]netFrameworkCore'
		}
	
		WindowsFeature WebStaticContent
		{
			Name      = 'Web-Static-Content'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebServerRole'
		}
	
		WindowsFeature WebDefaultDoc
		{
			Name      = 'Web-Default-Doc'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebStaticContent'
		}
	
		WindowsFeature WebHttpErrors
		{
			Name      = 'Web-Http-Errors'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebDefaultDoc'
		}
	
		WindowsFeature WebHttpRedirect
		{
			Name      = 'Web-Http-Redirect'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebHttpErrors'
		}
	
		WindowsFeature WebAspNet
		{
			Name      = 'Web-Asp-Net'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebHttpRedirect'
		}
	
		WindowsFeature WebAspNet45
		{
			Name      = 'Web-Asp-Net45'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebAspNet'
		}
	
		WindowsFeature WebNetExt
		{
			Name      = 'Web-Net-Ext'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebAspNet45'
		}
	
		WindowsFeature WebNetExt45
		{
			Name      = 'Web-Net-Ext45'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebNetExt'
		}
	
		WindowsFeature WebISAPIExt
		{
			Name      = 'Web-ISAPI-Ext'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebNetExt45'
		}
	
		WindowsFeature  WebISAPIFilter
		{
			Name      = 'Web-ISAPI-Filter'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebISAPIExt'
		}
	
		WindowsFeature  WebHttpLogging
		{
			Name      = 'Web-Http-Logging'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebISAPIFilter'
		}
	
		WindowsFeature  WebLogLibraries
		{
			Name      = 'Web-Log-Libraries'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebHttpLogging'
		}
	
		WindowsFeature  WebHttpTracing
		{
			Name      = 'Web-Http-Tracing'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebLogLibraries'
		}
	
		WindowsFeature  WebWindowsAuth
		{
			Name      = 'Web-Windows-Auth'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebHttpTracing'
		}
	
		WindowsFeature  WebClientAuth
		{
			Name      = 'Web-Client-Auth'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebWindowsAuth'
		}
	
		WindowsFeature  WebFiltering
		{
			Name      = 'Web-Filtering'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebClientAuth'
		}
	
		WindowsFeature  WebStatCompression
		{
			Name      = 'Web-Stat-Compression'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebFiltering'
		}
	
		WindowsFeature  WebMgmtConsole
		{
			Name      = 'Web-Mgmt-Console'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebStatCompression'
		}
	
		WindowsFeature  WebScriptingTools
		{
			Name      = 'Web-Scripting-Tools'
			Ensure    = 'Present'
			DependsOn = '[WindowsFeature]WebMgmtConsole'
		}
	
		InstallSolidCP enterprise
		{
			Component           = 'Enterprise Server'
			portalPassword      =  Get-Credential -Message 'Portal Password' -UserName 'serverAdmin'
			Ensure              = 'Present'
			DependsOn           = '[WindowsFeature]WebMgmtConsole'
		}

		InstallSolidCP portal
		{
			Component           = 'Portal'
			enterpriseServerURL = 'http://127.0.0.1:9002'
			Ensure              = 'Present'
			DependsOn           = '[InstallSolidCP]enterprise'
		}

		InstallSolidCP server
		{
			Component           = 'Server'
			serverPassword      =  Get-Credential -Message 'Server Password' -UserName 'ServerPassword'
			Ensure              = 'Present'
			DependsOn           = '[InstallSolidCP]portal'
		}
	}
}

solidCP -ConfigurationData $ConfigurationData -Verbose
Start-DscConfiguration solidCP -Wait -Verbose -Force -Debug