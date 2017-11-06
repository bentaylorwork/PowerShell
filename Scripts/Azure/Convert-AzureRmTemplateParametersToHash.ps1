function Convert-AzureRmTemplateParametersToHash
{
    <#
        .SYNOPSIS
            Replaces placeholders in a Azure ARM Template parameters file.
             like the Azure Quick Start templates on GitHub.

            Supported placeholders:
                * GEN-UNIQUE
                * GEN-UNIQUE-N
                * GEN-PASSWORD

            Example JSON paramters file:
                {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {
                        "userName": {
                            "value": "GEN-UNIQUE-4"
                        },
                        "adminPassword": {
                            "value": "GEN-PASSWORD"
                        }
                    }
                }
        .EXAMPLE
            Convert-ParametersJsonToHash -path 'c:\src\azuredeploy.parameters.json'
        .EXAMPLE
            $azureGroupDeployment = @{
                ResourceGroupName       = 'rg-test'
                TemplateFile            = 'c:\src\azuredeploy.json'
                TemplateParameterObject = (Convert-ParametersJsonToHash -path 'c:\src\azuredeploy.parameters.json')
                Verbose                 = $true
                                    }

            Test-AzureRmResourceGroupDeployment @azureGroupDeployment
        .NOTES
            Written by Ben Taylor
            Version 1.0, 23.10.2017
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
		[ValidateScript({ Test-Path $_ })]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    try
    {
        $hashReturn = @{}

        $ParametersObject = Get-Content -Path $Path | ConvertFrom-Json
                
        ($ParametersObject | Select-Object -ExpandProperty parameters).PSObject.Properties | ForEach-Object {
            if ($_.value.value -eq 'GEN-UNIQUE')
            {
                $hashReturn.Add($_.name, "a$(((New-Guid).guid -replace '-').Substring(0, 17))")
            }
            elseif ($_.value.value -like "GEN-UNIQUE*")
            {
                [int]$Number = ($_.value.value -split '-')[2]
                
                if ($Number -ge 32)
                {
                    Throw 'Number out of bounds'
                }
                
                $hashReturn.Add($_.name, "a$(((New-Guid).guid -replace '-').Substring(0, ($Number - 1)))")
            }
            elseif ($_.value.value -eq 'GEN-PASSWORD')
            {
                Add-Type -AssemblyName System.Web | Out-Null

                $hashReturn.Add($_.name, (ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(12,2)) -AsPlainText -Force))
            }
            else
            {
                $hashReturn.Add($_.name, $_.value.value)
            }
        }

        $hashReturn
    }
    catch
    {
        Throw $_   
    }
}
