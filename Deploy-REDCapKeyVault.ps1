<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCapKeyVault.ps1

This .PS1 is meant to be loaded using dot-sourcing (.) or using the using module command. It is not meant to be executed directly.

 #>

using namespace System.Diagnostics

#requires -Modules Az.Resources, Az.KeyVault
#requires -Version 7.1

using module .\ErrorRecord.psm1
using module .\CdphNaming.psm1

function Deploy-REDCapKeyVault
{
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
        [ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')]
        [string]
        $Cdph_ClientIPAddress
    )

    $deploymentResult = [PSCustomObject]@{
        Successful       = $true
        Error            = $null
        DeploymentErrors = $null
        Certificate      = $null
    }

    [Stopwatch] $stopwatch = [Stopwatch]::StartNew()

    Write-Information "Beginning deployment at $((Get-Date).ToString())"

    try
    {
        $requiredParameters = @(
            'Cdph_Organization',
            'Cdph_BusinessUnit',
            'Cdph_BusinessUnitProgram'
        )
        $deployParametersPath = 'redcapAzureDeployKeyVault.parameters.json'
        $deployParameters = Get-Content $deployParametersPath | ConvertFrom-Json -Depth 8 -AsHashtable
        if ($null -eq $deployParameters)
        {
            throw "Unable to load deployment parameters from $deployParametersPath"
        }

        if (-not $deployParameters.ContainsKey('parameters'))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a 'parameters' property"
        }

        $parametersEntry = $deployParameters.parameters
        foreach ($requiredParameter in $requiredParameters)
        {
            if (-not $parametersEntry.ContainsKey($requiredParameter))
            {
                throw "Deployment parameters from $deployParametersPath do not contain a required '$requiredParameter' property"
            }
            if (0 -eq $parametersEntry[$requiredParameter].value.Length)
            {
                throw "Deployment parameters from $deployParametersPath do not contain a required value for the '$requiredParameter' property"
            }
        }

        # Create hashtable from parametersEntry moving the value sub-property to the top level
        $flattenedParameters = @{}
        foreach ($parameterName in $parametersEntry.Keys)
        {
            $flattenedParameters[$parameterName] = $parametersEntry[$parameterName].value
        }

        # Override parameters with values from the command line
        if ($PSBoundParameters.ContainsKey('Arm_MainSiteResourceLocation') -and ![string]::IsNullOrWhiteSpace($Arm_MainSiteResourceLocation))
        {
            $flattenedParameters['Arm_MainSiteResourceLocation'] = $Arm_MainSiteResourceLocation
        }
        if ($PSBoundParameters.ContainsKey('Cdph_ResourceInstance') -and ![string]::IsNullOrWhiteSpace($Cdph_ResourceInstance))
        {
            $flattenedParameters['Cdph_ResourceInstance'] = $Cdph_ResourceInstance
        }
        if ($PSBoundParameters.ContainsKey('Cdph_ClientIPAddress') -and ![string]::IsNullOrWhiteSpace($Cdph_ClientIPAddress))
        {
            $flattenedParameters['Cdph_ClientIPAddress'] = $Cdph_ClientIPAddress
        }

        # Merge parameters
        $templateParameters = $flattenedParameters
        $organization = $templateParameters['Cdph_Organization']
        $businessUnit = $templateParameters['Cdph_BusinessUnit']
        $program = $templateParameters['Cdph_BusinessUnitProgram']
        $environment = $templateParameters['Cdph_Environment']
        $instance = $templateParameters['Cdph_ResourceInstance']
        $paddedInstance = $instance.ToString().PadLeft(2, '0')

        $keyVaultResourceName = New-KeyVaultResourceName `
            -Cdph_Organization $organization `
            -Cdph_BusinessUnit $businessUnit `
            -Cdph_BusinessUnitProgram $program `
            -Cdph_Environment $environment `
            -Cdph_ResourceInstance $instance

        $templateParameters.Add('Cdph_KeyVaultResourceName', $keyVaultResourceName)

        $templateParameters.Add('Arm_AdministratorObjectId', (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id)

        if (($PSBoundParameters.ContainsKey('Arm_ResourceGroupName')) -and (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['Arm_ResourceGroupName'])))
        {
            $resourceGroupName = $Arm_ResourceGroupName
        }
        else
        {
            $resourceGroupName = "rg-$organization-$businessUnit-$program-$environment-$paddedInstance"
        }
        Write-Information "Using resource group name $resourceGroupName"

        $appServiceResourceName = "app-$organization-$businessUnit-$program-$environment-$paddedInstance"

        # Make sure we're logged in. Use Connect-AzAccount if not.
        Get-AzContext -ErrorAction Stop | Out-Null

        # Start deployment
        $bicepPath = 'redcapAzureDeployKeyVault.bicep'

        $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($resourceGroup))
        {
            Write-Information "Creating new resource group: $resourceGroupName"
            $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $Arm_MainSiteResourceLocation
            Write-Information "Created new resource group $resourceGroupName."
        }
        else
        {
            Write-Information "Resource group $resourceGroupName exists. Updating deployment"
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
        $armDeployment = New-AzResourceGroupDeployment @deployArgs -Force -Verbose -DeploymentDebugLogLevel ResponseContent | Select-Object -First 1
        if ($null -eq $armDeployment)
        {
            throw 'New-AzResourceGroupDeployment returned $null'
        }
        else
        {
            Write-Information "Provisioning State = $($armDeployment.ProvisioningState)"
        }

        while (($null -ne $armDeployment) -and ($armDeployment.ProvisioningState -eq 'Running'))
        {
            Write-Information "State = $($armDeployment.ProvisioningState); Check again at $([datetime]::Now.AddSeconds(5).ToLongTimeString())"
            Start-Sleep 5
        }

        if (($null -ne $armDeployment) -and ($armDeployment.ProvisioningState -eq 'Succeeded'))
        {
            Write-Information $armDeployment.Outputs | ConvertTo-Json -Depth 8

            $certificate = $null
            $certificate = Get-AzKeyVaultCertificate `
                -VaultName $keyVaultResourceName `
                -Name $appServiceResourceName `
                -ErrorAction SilentlyContinue

            if ($null -eq $certificate)
            {
                Write-Information "Importing certificate $Cdph_PfxCertificatePath into Key Vault $keyVaultResourceName"
                $certificate = Import-AzKeyVaultCertificate `
                    -VaultName $keyVaultResourceName `
                    -Name $appServiceResourceName `
                    -FilePath $Cdph_PfxCertificatePath `
                    -Password $Cdph_PfxCertificatePassword
            }
            else
            {
                Write-Information "Certificate $appServiceResourceName already exists in Key Vault $keyVaultResourceName"
            }
            $deploymentResult.Certificate = $certificate
        }
        else
        {
            $deploymentResult.Successful = $false
            # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSDeploymentOperation]
            $deploymentErrors = $null
            $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
            Write-Information $deploymentErrors | ConvertTo-Json -Depth 8
            $deploymentResult.DeploymentErrors = $deploymentErrors
        }
    }
    catch
    {
        $x = $_
        Write-CaughtErrorRecord $x Error -IncludeStackTrace
        $deploymentResult.Error = $x
        $deploymentResult.Successful = $false
    }
    finally
    {
        # Stop timer
        $stopwatch.Stop() | Out-Null
        $measured = $stopwatch.Elapsed
    
        Write-Information "Total Key Vault Deployment time: $($measured.ToString())"
    }
    return $deploymentResult
}
