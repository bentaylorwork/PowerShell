#Import DSC Resource
Using Module 'C:\Program Files\WindowsPowerShell\Modules\installSolidCP\InstallSolidCP.psm1'

Describe 'InstallSolidCP' {
	$InstallSolidCP = [InstallSolidCP]::new()

	Context '$InstallSolidCP.Get()' {
		It 'Output type of Get() method should be InstallSolidCP' {
			Mock Test-Path { $true }
			($InstallSolidCP.Get()).Gettype() | Should be 'InstallSolidCP'
		}
		It 'Get().Ensure when component is Present' {
			Mock Test-Path { $true }
			($InstallSolidCP.Get()).Ensure | Should be 'Present'
		}
		It 'Get().Ensure when component is Absent' {
			Mock Test-Path { $false }
			($InstallSolidCP.Get()).Ensure | Should be 'Absent'
		}
	}
	Context 'Set() - Present' {
		It '$InstallSolidCP.Set() - $null' {
			Mock Test-Path {$true}
			$InstallSolidCP.Set() | Should be $null
		}
	}
	Context 'Test() - Present' {
		$InstallSolidCP.ensure = 'Present'

		It '$InstallSolidCP.Test() - Path Exists' {
			Mock Test-Path {$true}
			$InstallSolidCP.Test() | should be $true
		}
		It '$InstallSolidCP.Test() - Path Does not Exists' {
			Mock Test-Path {$false}
			$InstallSolidCP.Test() | should be $false
		}
	}
	Context 'Test() - Absent' {
		$InstallSolidCP.ensure = 'Absent'

		It '$InstallSolidCP.Test() - Path Exists' {
			Mock Test-Path {$true}
			$InstallSolidCP.Test() | should be $false
		}
		It '$InstallSolidCP.Test() - Path Does not Exists' {
			Mock Test-Path {$false}
			$InstallSolidCP.Test() | should be $true
		}
	}
}