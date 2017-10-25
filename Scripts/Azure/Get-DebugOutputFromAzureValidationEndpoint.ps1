function Get-DebugOutputFromAzureValidationEndpoint
{
    <#
        .Synopsis
            Gets the deployed resources without deploying them using Test-AzureRmResourceGroupDeployment
        .EXAMPLE
            Get-DebugOutputFromAzureValidationEndpoint -ResourceGroupName 'test' -TemplateParameterUri 'http://localhost/azuredeploy.parameters.json' -$TemplateUri 'http://localhsot/azuredeploy.json'
        .EXAMPLE
            Get-DebugOutputFromAzureValidationEndpoint -ResourceGroupName 'test' -TemplateParameterFile 'c:\azuredeploy.parameters.json' -TemplateParameterObject @{ parameterone = 'test' }
        .NOTES
            Idea taken from https://github.com/marcvaneijk/AzureResourceManager/blob/master/expandTemplate.ps1

            Written by Ben Taylor
            Version 1.0, 22.10.2017
    #>
    [CmdletBinding()]
    [OutputType()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceGroupName,
        [Parameter(ParameterSetName = 'Deployment via template file and template parameters object', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'A hash table which represents the parameters.')]
        [Parameter(ParameterSetName = 'Deployment via template uri and template parameters object', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'A hash table which represents the parameters.')]
        [hashtable]
        $TemplateParameterObject,
        [Parameter(ParameterSetName = 'Deployment via template file and template parameters file', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'A file that has the template parameters.')]
        [Parameter(ParameterSetName = 'Deployment via template uri and template parameters file', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'A file that has the template parameters.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplateParameterFile,
        [Parameter(ParameterSetName = 'Deployment via template file template parameters uri', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Uri to the template parameter file.')]
        [Parameter(ParameterSetName = 'Deployment via template uri and template parameters uri', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Uri to the template parameter file.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplateParameterUri,
        [Parameter(ParameterSetName = 'Deployment via template file and template parameters object', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Local path to the template file.')]
        [Parameter(ParameterSetName = 'Deployment via template file and template parameters file', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Local path to the template file.')]
        [Parameter(ParameterSetName = 'Deployment via template file template parameters uri', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Local path to the template file.')]
        [Parameter(ParameterSetName = 'Deployment via template file without parameters', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Local path to the template file.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplateFile,
        [Parameter(ParameterSetName = 'Deployment via template uri and template parameters object', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Uri to the template file.')]
        [Parameter(ParameterSetName = 'Deployment via template uri and template parameters file', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Uri to the template file.')]
        [Parameter(ParameterSetName = 'Deployment via template uri and template parameters uri', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Uri to the template file.')]
        [Parameter(ParameterSetName = 'Deployment via template uri without parameters', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Uri to the template file.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplateUri
    )

    $ResourceGroupDeploymentParameters = @{ ResourceGroupName = $ResourceGroupName }

    If ($PSBoundParameters['TemplateParameterObject'])
    {
        $ResourceGroupDeploymentParameters.TemplateParameterObject = $TemplateParameterObject
    }

    If ($PSBoundParameters['TemplateParameterFile'])
    {
        $ResourceGroupDeploymentParameters.TemplateParameterFile = $TemplateParameterFile
    }

    If ($PSBoundParameters['TemplateParameterUri'])
    {
        $ResourceGroupDeploymentParameters.TemplateParameterUri = $TemplateParameterUri
    }

    If ($PSBoundParameters['TemplateFile'])
    {
        $ResourceGroupDeploymentParameters.TemplateFile = $TemplateFile
    }

    If ($PSBoundParameters['TemplateUri'])
    {
        $ResourceGroupDeploymentParameters.TemplateUri = $TemplateUri
    }

    $debugPreference = 'Continue'
    $rawResponse = Test-AzureRmResourceGroupDeployment @ResourceGroupDeploymentParameters -ErrorAction Stop 5>&1
    $debugPreference = 'SilentlyContinue'

    try
    {
        $armTemplateObject = $rawResponse.Item(32) -split 'Body:' | Select-Object -Skip 1 | ConvertFrom-Json

        if ($armTemplateObject.psObject.Properties | Where-Object { $_.name -eq 'properties' })
        {
            $armTemplateObject | Select-Object -ExpandProperty properties
        }
        else
        {
            $armTemplateObject | Select-Object -ExpandProperty error
        }
    }
    catch
    {
        Write-Error $_
    }
}
