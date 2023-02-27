<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCapKeyVault.ps1
 #>
#requires -Modules Az.Resources, Az.KeyVault
#requires -Version 7.1


param (
    # Optional Azure resource group name. If not specified, a default name will be used based on the parameters.json file and the instance number.
    [Parameter()]
    [string]
    $Arm_ResourceGroupName,
    
    # Azure region for the main site. 
    # Basic options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
    # Full list of regions can be found here: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies
    # Not all resources are available in all regions.
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'centralus',
        'eastus',
        'eastus2',
        'northcentralus',
        'southcentralus',
        'westcentralus',
        'westus',
        'westus2',
        'westus3'
    )]    
    [string]
    $Arm_MainSiteResourceLocation,

    # Optional CDPH resource instance number to allow multiple deployments to the same subscription. If not specified, the default value of 1 will be used.
    [Parameter()]
    [int]
    $Cdph_ResourceInstance = 1,

    # Path to PFX certificate file to upload to Key Vault for App Service SSL binding
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]
    $Cdph_PfxCertificatePath,

    # Password for PFX certificate file
    [Parameter(Mandatory = $true)]
    [securestring]
    $Cdph_PfxCertificatePassword,

    # Client IP address to allow access to Key Vault
    [Parameter(Mandatory = $true)]
    [string]
    $Cdph_ClientIPAddress
)

$measured = Measure-Command {
    & {
        Write-Information "Beginning deployment at $((Get-Date).ToString())"

        Import-Module .\ErrorRecord.psm1

        $requiredParameters = @(
            'Cdph_Organization',
            'Cdph_BusinessUnit',
            'Cdph_BusinessUnitProgram'
        )
        $deployParametersPath = 'redcapAzureDeployKeyVault.parameters.json'
        $deployParameters = Get-Content $deployParametersPath | ConvertFrom-Json -Depth 8 -AsHashtable
        if ($null -eq $deployParameters)
        {
            Write-Error "Unable to load deployment parameters from $deployParametersPath"
        }
        if (-not $deployParameters.ContainsKey('parameters'))
        {
            Write-Error "Deployment parameters from $deployParametersPath do not contain a 'parameters' property"
        }
        $parametersEntry = $deployParameters.parameters
        foreach ($requiredParameter in $requiredParameters)
        {
            if (-not $parametersEntry.ContainsKey($requiredParameter))
            {
                Write-Error "Deployment parameters from $deployParametersPath do not contain a required '$requiredParameter' property"
            }
            if (0 -eq $parametersEntry[$requiredParameter].value.Length)
            {
                Write-Error "Deployment parameters from $deployParametersPath do not contain a required value for the '$requiredParameter' property"
            }
        }

        # Create hashtable from parametersEntry moving the value sub-property to the top level
        $flattenedParameters = @{}
        foreach ($parameterName in $parametersEntry.Keys)
        {
            $flattenedParameters[$parameterName] = $parametersEntry[$parameterName].value
        }

        # Override parameters with values from the command line
        if ($PSBoundParameters.ContainsKey('Arm_MainSiteResourceLocation') && ![string]::IsNullOrWhiteSpace( $Arm_MainSiteResourceLocation))
        {
            $flattenedParameters['Arm_MainSiteResourceLocation'] = $Arm_MainSiteResourceLocation
        }
        if ($PSBoundParameters.ContainsKey('Cdph_ResourceInstance') && ![string]::IsNullOrWhiteSpace( $Cdph_ResourceInstance))
        {
            $flattenedParameters['Cdph_ResourceInstance'] = $Cdph_ResourceInstance
        }

        # Merge parameters
        $templateParameters = $flattenedParameters
        $organization = $templateParameters['Cdph_Organization']
        $businessUnit = $templateParameters['Cdph_BusinessUnit']
        $program = $templateParameters['Cdph_BusinessUnitProgram']
        $environment = $templateParameters['Cdph_Environment']
        $instance = $templateParameters['Cdph_ResourceInstance'].ToString().PadLeft(2, '0')

        if (($PSBoundParameters.ContainsKey('Arm_ResourceGroupName')) -and (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['Arm_ResourceGroupName'])))
        {
            $resourceGroupName = $Arm_ResourceGroupName
        }
        else
        {
            $resourceGroupName = "rg-$organization-$businessUnit-$program-$environment-$instance"
        }
        Write-Information "Using resource group name $resourceGroupName"

        $appServicePlanName = "asp-$organization-$businessUnit-$program-$environment-$($instance.PadLeft(2, '0'))"

        # Make sure we're logged in. Use Connect-AzAccount if not.
        Get-AzContext -ErrorAction Stop

        # Start deployment
        $bicepPath = 'redcapAzureDeployKeyVault.bicep'

        try
        {
            Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop
            Write-Information "Resource group $resourceGroupName exists. Updating deployment"
        }
        catch
        {

            Write-Information "Creating new resource group: $resourceGroupName"
            $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $Arm_MainSiteResourceLocation
            Write-Information "Created new resource group $resourceGroupName."
        }

        $version = (Get-Date).ToString('yyyyMMddHHmmss')
        $deploymentName = "REDCapDeployKeyVault.$version"
        $deployArgs = @{
            ResourceGroupName       = $resourceGroupName
            TemplateFile            = $bicepPath
            Name                    = $deploymentName
            TemplateParameterObject = $templateParameters
        }
        # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment]
        $armDeployment = $null
        try
        {
            $armDeployment = New-AzResourceGroupDeployment @deployArgs -Force -Verbose -DeploymentDebugLogLevel ResponseContent | Select-Object -First 1
            if ($null -eq $armDeployment)
            {
                Write-Error 'New-AzResourceGroupDeployment returned $null'
            }
            else
            {
                Write-Information "Provisioning State = $($armDeployment.ProvisioningState)"
            }
        }
        catch
        {
            Write-CaughtErrorRecord $_ Error -IncludeStackTrace
        }

        while (($null -ne $armDeployment) -and ($armDeployment.ProvisioningState -eq 'Running'))
        {
            Write-Information "State = $($armDeployment.ProvisioningState); Check again at $([datetime]::Now.AddSeconds(5).ToLongTimeString())"
            Start-Sleep 5
        }

        if (($null -ne $armDeployment) -and ($armDeployment.ProvisioningState -eq 'Succeeded'))
        {
            $armDeployment.Outputs | ConvertTo-Json -Depth 8

            $keyVaultResourceName = $armDeployment.Outputs['out_KeyVault_ResourceName'].Value

            Import-AzKeyVaultCertificate `
                -VaultName $keyVaultResourceName `
                -Name $appServicePlanName `
                -FilePath $Cdph_PfxCertificatePath `
                -Password $Cdph_PfxCertificatePassword

            Write-Output [PSCustomObject]@{
                Result = $true
            }
        }
        else
        {
            # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSDeploymentOperation]
            $deploymentErrors = $null
            try
            {
                $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
                $deploymentErrors | ConvertTo-Json -Depth 8
                Write-Output [PSCustomObject]@{
                    Result = $false
                    Errors = $deploymentErrors
                }
            }
            catch
            {
                Write-CaughtErrorRecord $_ Error -IncludeStackTrace
                Write-Output [PSCustomObject]@{
                    Result = $false
                    Errors = $deploymentErrors
                }
            }
        }

    } | Out-Default
}
Write-Information "Total Deployment time: $($measured.ToString())"
