function Get-MsolAccountSkuAvailable
{
	<#
		.Synopsis
		   Gets the remaining licences on a Office 365 SKU.
		.EXAMPLE
			Get-MsolAccountSkuAvailable
		.NOTES
			Written by Ben Taylor
			Version 1.0, 29.11.2016
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param()
	
	$accountSku = Get-MsolAccountSku

	if($accountSku)
	{
		if(($accountSku.ActiveUnits - $accountSku.ConsumedUnits) -ge 1) {

			$accountSkuBool = $true
		}
		else
		{
			$accountSkuBool = $false
		}

		[psCustomObject]@{
			AccountSkuId     = $accountSku.AccountSkuId
			ActiveUnits      = $accountSku.ActiveUnits
			ConsumedUnits    = $accountSku.ConsumedUnits
			usableUnits      = ($accountSku.ActiveUnits - $accountSku.ConsumedUnits)
			isUnitsAvailable = $accountSkuBool
		}
	}
	else
	{
		Write-Error 'No SKU found'
	}
}