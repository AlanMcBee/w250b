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

<#
.SYNOPSIS
Invokes the deployment of the REDCap Key Vault using Bicep.

.DESCRIPTION
Instead of loading the parameters from a file, this function will load the parameters from the file redcapAzureDeployKeyVault.parameters.json and then override the values with the values passed in as parameters to this function. This allows the parameters to be loaded from a file and then overridden with values passed in from the command line.
#>
function Deploy-REDCapKeyVault
{
    param (
        # CDPH Owner
        [Parameter(Mandatory = $true)]
        [ValidateSet('ITSD', 'CDPH')]
        [string]
        $Cdph_Organization,

        # CDPH Business Unit (numbers & digits only)
        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9]{2,5}$')]
        [string]
        $Cdph_BusinessUnit,

        # CDPH Business Unit Program (numbers & digits only)
        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9]{2,7}$')]
        [string]
        $Cdph_BusinessUnitProgram,

        # Optional CDPH environment name to allow multiple deployments to the same subscription.
        [Parameter()]
        [ValidateSet('dev', 'test', 'stage', 'prod')]
        [string]
        $Cdph_Environment,

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
        Write-Information 'Making sure that all required parameters are present and have values in the file redcapAzureDeployKeyVault.parameters.json'

        $requiredParameters = @(
            'MicrosoftKeyVault_vaults'
        )
        $deployParametersPath = 'redcapAzureDeployKeyVault.parameters.json'
        $deployParameters = Get-Content $deployParametersPath | ConvertFrom-Json -AsHashtable
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
            if ([string]::IsNullOrWhiteSpace($parametersEntry[$requiredParameter].value))
            {
                throw "Deployment parameters from $deployParametersPath do not contain a required value for the '$requiredParameter' property"
            }
        }

        Write-Information 'Overriding loaded parameters from redcapAzureDeployKeyVault.parameters.json with arguments from the command line'

        # Common parameters
        $arm_AdministratorObjectId_parameters = $parametersEntry.Arm_AdministratorObjectId
        if ($null -eq $arm_AdministratorObjectId_parameters)
        {
            $parametersEntry.Arm_AdministratorObjectId = $null
            $arm_AdministratorObjectId_parameters = $parametersEntry.Arm_AdministratorObjectId
        }
        $currentUserObjectId = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id
        $arm_AdministratorObjectId_parameters.value = $currentUserObjectId

        $cdph_BusinessUnit_parameters = $parametersEntry.Cdph_BusinessUnit
        if ($null -eq $cdph_BusinessUnit_parameters)
        {
            $parametersEntry.Cdph_BusinessUnit = $null
            $cdph_BusinessUnit_parameters = $parametersEntry.Cdph_BusinessUnit
        }
        if (-not([string]::IsNullOrWhiteSpace($Cdph_BusinessUnit)))
        {
            $cdph_BusinessUnit_parameters.value = $Cdph_BusinessUnit
        }
        $cdph_BusinessUnit_actual = $cdph_BusinessUnit_parameters.value
        if ($null -eq $cdph_BusinessUnit_actual -or [string]::IsNullOrWhiteSpace($cdph_BusinessUnit_actual))
        {
            throw 'Cdph_BusinessUnit is a required parameter. It must be specified either in the redcapAzureDeployKeyVault.parameters.json file or as a parameter to this function.'
        }

        $cdph_BusinessUnitProgram_parameters = $parametersEntry.Cdph_BusinessUnitProgram
        if ($null -eq $cdph_BusinessUnitProgram_parameters)
        {
            $parametersEntry.Cdph_BusinessUnitProgram = $null
            $cdph_BusinessUnitProgram_parameters = $parametersEntry.Cdph_BusinessUnitProgram
        }
        if (-not([string]::IsNullOrWhiteSpace($Cdph_BusinessUnitProgram)))
        {
            $cdph_BusinessUnitProgram_parameters.value = $Cdph_BusinessUnitProgram
        }
        $cdph_BusinessUnitProgram_actual = $cdph_BusinessUnitProgram_parameters.value
        if ($null -eq $cdph_BusinessUnitProgram_actual -or [string]::IsNullOrWhiteSpace($cdph_BusinessUnitProgram_actual))
        {
            throw 'Cdph_BusinessUnitProgram is a required parameter. It must be specified either in the redcapAzureDeployKeyVault.parameters.json file or as a parameter to this function.'
        }

        $cdph_Environment_parameters = $parametersEntry.Cdph_Environment
        if ($null -eq $cdph_Environment_parameters)
        {
            $parametersEntry.Cdph_Environment = $null
            $cdph_Environment_parameters = $parametersEntry.Cdph_Environment
        }
        if (-not([string]::IsNullOrWhiteSpace($Cdph_Environment)))
        {
            $cdph_Environment_parameters.value = $Cdph_Environment
        }
        $cdph_Environment_actual = $cdph_Environment_parameters.value
        if ($null -eq $cdph_Environment_actual -or [string]::IsNullOrWhiteSpace($cdph_Environment_actual))
        {
            throw 'Cdph_Environment is a required parameter. It must be specified either in the redcapAzureDeployKeyVault.parameters.json file or as a parameter to this function.'
        }

        $resourceNameArgs = @{
            Arm_ResourceProvider = $null
            Cdph_Organization = $Cdph_Organization
            Cdph_BusinessUnit = $cdph_BusinessUnit_actual
            Cdph_BusinessUnitProgram = $cdph_BusinessUnitProgram_actual
            Cdph_Environment = $cdph_Environment_actual
            Cdph_ResourceInstance = $Cdph_ResourceInstance
        }

        # Resource Group

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Resources/resourceGroups'
        $resourceGroup_Arm_ResourceName = New-CdphResourceName @resourceNameArgs

        Write-Information "Using resource group name $resourceGroup_Arm_ResourceName"

        # Resource-specific parameters

        $microsoftKeyVault_vaults = $parametersEntry['MicrosoftKeyVault_vaults']
        $keyVault_Arguments = $microsoftKeyVault_vaults.value
        if ($null -eq $keyVault_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftKeyVault_vaults.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.KeyVault/vaults'
        $keyVault_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $keyVault_Arguments['Arm_ResourceName'] = $keyVault_Arm_ResourceName

        $keyVault_byEnvironment = $keyVault_Arguments.byEnvironment
        if ($null -eq $keyVault_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftKeyVault_vaults.value.byEnvironment' property"
        }
        $keyVault_byEnvironment_thisEnvironment = $keyVault_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $keyVault_byEnvironment_thisEnvironment)
        {
            $keyVault_byEnvironment[$cdph_Environment_actual] = $null
            $keyVault_byEnvironment_thisEnvironment = $keyVault_byEnvironment[$cdph_Environment_actual]
        }
        $keyVault_byEnvironment_allEnvironments = $keyVault_byEnvironment.ALL
        if ($null -eq $keyVault_byEnvironment_allEnvironments)
        {
            $keyVault_byEnvironment.ALL = $null
            $keyVault_byEnvironment_allEnvironments = $keyVault_byEnvironment.ALL
        }

        $keyVault_Arm_Location = $keyVault_byEnvironment_thisEnvironment.Arm_Location ?? $keyVault_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($keyVault_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftKeyVault_vaults.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftKeyVault_vaults.value.byEnvironment.ALL.Arm_Location' property"
        }

        $keyVault_NetworkAcls_IpRules = keyVault_byEnvironment_thisEnvironment.NetworkAcls_IpRules ?? keyVault_byEnvironment_allEnvironments.NetworkAcls_IpRules
        if ($null -eq $keyVault_NetworkAcls_IpRules)
        {
            keyVault_byEnvironment_thisEnvironment['NetworkAcls_IpRules'] = [PSCustomObject]@(
                @{value = $null}
            )
            $keyVault_NetworkAcls_IpRules = keyVault_byEnvironment_thisEnvironment['NetworkAcls_IpRules']
        }
        if ($PSBoundParameters.ContainsKey('Cdph_ClientIPAddress') -and ![string]::IsNullOrWhiteSpace($Cdph_ClientIPAddress))
        {
            $keyVault_NetworkAcls_IpRules.Add([PSCustomObject]@{value = "$Cdph_ClientIPAddress/32"})
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Web/sites'
        $appService_Arm_ResourceName = New-CdphResourceName @resourceNameArgs

        # Deploy
        # ------

        # Make sure we're logged in. Use Connect-AzAccount if not.
        Get-AzContext -ErrorAction Stop | Out-Null

        # Start deployment
        $bicepPath = 'redcapAzureDeployKeyVault.bicep'

        $resourceGroup = Get-AzResourceGroup -Name $resourceGroup_Arm_ResourceName -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($resourceGroup))
        {
            Write-Information "Creating new resource group: $resourceGroup_Arm_ResourceName"
            $resourceGroup = New-AzResourceGroup -Name $resourceGroup_Arm_ResourceName -Location $Arm_MainSiteResourceLocation
            Write-Information "Created new resource group $resourceGroup_Arm_ResourceName."
        }
        else
        {
            Write-Information "Resource group $resourceGroup_Arm_ResourceName exists. Updating deployment"
        }

        $version = (Get-Date).ToString('yyyyMMddHHmmss')
        $deploymentName = "REDCapDeployKeyVault.$version"
        $deployArgs = @{
            ResourceGroupName       = $resourceGroup_Arm_ResourceName
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
            Write-Information "Succeeded. Outputs: $($armDeployment.Outputs)"

            Write-Information 'Setting access policy to allow App Service to read from Key Vault'
            $azureAppServiceApplicationId = 'abfa0a7c-a6b6-4736-8310-5855508787cd' # fixed value for Azure App Services (see https://learn.microsoft.com/azure/app-service/configure-ssl-certificate#authorize-app-service-to-read-from-the-vault)

            Set-AzKeyVaultAccessPolicy `
                -VaultName $keyVault_Arm_ResourceName `
                -ServicePrincipalName $azureAppServiceApplicationId `
                -PermissionsToCertificates get `
                -PermissionsToKeys get `
                -PermissionsToSecrets get

            Write-Information 'Successfully set access policy'

            $certificate = $null
            $certificate = Get-AzKeyVaultCertificate `
                -VaultName $keyVault_Arm_ResourceName `
                -Name $appService_Arm_ResourceName `
                -ErrorAction SilentlyContinue

            if ($null -eq $certificate)
            {
                Write-Information "Importing certificate $Cdph_PfxCertificatePath into Key Vault $keyVault_Arm_ResourceName"
                $certificate = Import-AzKeyVaultCertificate `
                    -VaultName $keyVault_Arm_ResourceName `
                    -Name $appService_Arm_ResourceName `
                    -FilePath $Cdph_PfxCertificatePath `
                    -Password $Cdph_PfxCertificatePassword
            }
            else
            {
                Write-Information "Certificate $appService_Arm_ResourceName already exists in Key Vault $keyVault_Arm_ResourceName"
            }
            $deploymentResult.Certificate = $certificate
        }
        else
        {
            $deploymentResult.Successful = $false
            # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSDeploymentOperation]
            $deploymentErrors = $null
            $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroup_Arm_ResourceName
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
