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

    )

    $deploymentResult = [PSCustomObject]@{
        Successful       = $true
        Error            = $null
        DeploymentErrors = $null
        Certificate      = $null
    }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Web/sites'
        $appService_Arm_ResourceName = New-CdphResourceName @resourceNameArgs

        # Deploy
        # ------

        # Flatten parameters
        $parameters = @{}
        foreach ($parameterKey in $parametersEntry.Keys)
        {
            $parameters[$parameterKey] = $parametersEntry[$parameterKey].value
        }

        # Make sure we're logged in. Use Connect-AzAccount if not.
        Get-AzContext -ErrorAction Stop | Out-Null

        # Start deployment
        $bicepPath = 'redcapAzureDeployKeyVault.bicep'

        $resourceGroup = Get-AzResourceGroup -Name $resourceGroup_Arm_ResourceName -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($resourceGroup))
        {
            Write-Information "Creating new resource group: $resourceGroup_Arm_ResourceName"
            $resourceGroup = New-AzResourceGroup -Name $resourceGroup_Arm_ResourceName -Location $Arm_ResourceGroup_Location
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
            TemplateParameterObject = $parameters
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
