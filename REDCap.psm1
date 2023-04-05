#requires -Modules Az.Resources, Az.KeyVault
#requires -Version 7.1

using module .\ErrorRecord.psm1
using module .\CdphNaming.psm1
using module .\Hashtable.psm1

Set-StrictMode -Version Latest

class ResourceDeployment
{
    [string] $Cdph_Organization
    [string] $Cdph_Environment
    [int] $Cdph_ResourceInstance

    ResourceDeployment (
        [string] $Cdph_Organization,
        [string] $Cdph_Environment,
        [int] $Cdph_ResourceInstance
    )
    {
        $this.Cdph_Organization = $Cdph_Organization
        $this.Cdph_Environment = $Cdph_Environment
        $this.Cdph_ResourceInstance = $Cdph_ResourceInstance
    }
}

function Deploy-AzureREDCap
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
        $Cdph_ClientIPAddress,

        # Password for MySQL administrator account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword,

        # Password for the REDCap Community site account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter()]
        [securestring]
        $ProjectREDCap_CommunityPassword,

        # Password for the SMTP server account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $Smtp_UserPassword
    )

    $progressActivity = 'Deploying REDCap infrastructure to Azure'
    Write-Progress -Activity $progressActivity -Status 'Deploying Key Vault'
    
    $resourceDeployment = [ResourceDeployment]::new(
        $Cdph_Organization,
        $Cdph_Environment,
        $Cdph_ResourceInstance
    )

    $keyVaultParametersEntry = Get-Parameters `
        -Template 'KeyVault'
    
    Initialize-CommonArguments `
        -ParametersEntry $keyVaultParametersEntry `
        -Cdph_BusinessUnit $Cdph_BusinessUnit `
        -Cdph_BusinessUnitProgram $Cdph_BusinessUnitProgram

    Deploy-ResourceGroup `
        -ParametersEntry $keyVaultParametersEntry `
        -ResourceDeployment $resourceDeployment

    Initialize-KeyVaultArguments `
        -ParametersEntry $keyVaultParametersEntry `
        -ResourceDeployment $resourceDeployment `
        -Cdph_ClientIPAddress $Cdph_ClientIPAddress `
        -MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword `
        -ProjectREDCap_CommunityPassword $ProjectREDCap_CommunityPassword `
        -Smtp_UserPassword $Smtp_UserPassword

    [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment] $deploymentResult = Deploy-Bicep `
        -Template 'KeyVault' `
        -ResourceDeployment $resourceDeployment `
        -ParametersEntry $keyVaultParametersEntry 

    if ($deploymentResult.ProvisioningState -ne 'Succeeded')
    {
        Write-Error 'Key Vault deployment failed.'
        throw $deploymentResult
    }

    Write-Progress -Activity $progressActivity -Status 'Importing server certificate to Key Vault'

    Set-KeyVaultAppServiceAccessPolicy `
        -ParametersEntry $keyVaultParametersEntry

    Import-PfxCertificate `
        -ParametersEntry $keyVaultParametersEntry `
        -ResourceDeployment $resourceDeployment `
        -Cdph_PfxCertificatePath $Cdph_PfxCertificatePath `
        -Cdph_PfxCertificatePassword $Cdph_PfxCertificatePassword

    Write-Progress -Activity $progressActivity -Status 'Deploying MySQL, Storage Account, Web Site, and Application Insights'
        
    $mainParametersEntry = Get-Parameters `
        -Template 'Main'

    Initialize-VirtualNetworkArguments `
        -ParametersEntry $parametersEntry

    Initialize-StorageAccountArguments `
        -ParametersEntry $parametersEntry

    Initialize-MySQLArguments `
        -ParametersEntry $parametersEntry `
        -MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword

    Initialize-AppServiceArguments `
        -ParametersEntry $parametersEntry `
        -Cdph_PfxCertificatePath $Cdph_PfxCertificatePath `
        -Cdph_PfxCertificatePassword $Cdph_PfxCertificatePassword

    Initialize-REDCapArguments `
        -ParametersEntry $parametersEntry `
        -ProjectREDCap_CommunityPassword $ProjectREDCap_CommunityPassword

    Initialize-SmtpArguments `
        -ParametersEntry $parametersEntry `
        -Smtp_UserPassword $Smtp_UserPassword

    Deploy-Bicep `
        -ParametersEntry $parametersEntry `
        -Template 'Main'

}
Export-ModuleMember -Function 'Deploy-AzureREDCap'

function Deploy-Bicep
{
    [OutputType([Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment,

        [Parameter(Mandatory = $true)]
        [ValidateSet('KeyVault', 'Main')]
        [string]
        $Template
    )

    # Flatten the ParametersEntry hashtable by pulling up the value property of the nested hashtables and removing the metadata (or any other top-level) property
    $parameters = @{}
    $parametersArray = $ParametersEntry.Keys | ForEach-Object {
        $key = $_
        $value = $ParametersEntry[$key].value
        $parameters[$key] = $value
    }

    $resourceGroupName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Resources/resourceGroups'

    $bicepPath = switch ($Template)
    {
        'KeyVault' { 'redcapAzureDeploy.keyVault.bicep' }
        'Main' { 'redcapAzureDeploy.main.bicep' }
        Default { throw "Invalid template name: $Template"}
    }

    $version = (Get-Date).ToString('yyyyMMddHHmmss')
    $deploymentName = "REDCapDeploy$Template.$version"
    
    $deployArgs = @{
        ResourceGroupName       = $resourceGroupName
        TemplateFile            = $bicepPath
        Name                    = $deploymentName
        TemplateParameterObject = $parameters
    }

    $outputs = New-AzResourceGroupDeployment @deployArgs `
        -Force `
        -Verbose `
        -DeploymentDebugLogLevel ResponseContent `
        -ErrorAction Continue

    foreach ($output in $outputs)
    {
        if ($output -is [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment])
        {
            [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment] $armDeployment = $output
        }
    }

    return $armDeployment
}

function Initialize-KeyVaultArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')]
        [string]
        $Cdph_ClientIPAddress,

        # Password for MySQL administrator account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword,

        # Password for the REDCap Community site account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $ProjectREDCap_CommunityPassword,

        # Password for the SMTP server account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $Smtp_UserPassword
    )
    
    # Initialize the plain text arguments

    $parameterArguments = @{
        ParametersEntry = $ParametersEntry
        ParameterName   = 'MicrosoftKeyVault_vaults_Arguments'
    }

    $null = Test-Argument @parameterArguments
    
    $keyVault_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.KeyVault/vaults'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $keyVault_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Name '$metadata'

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $currentUserObjectId = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id
    Set-Argument @parameterArguments `
        -Name 'Arm_AdministratorObjectId' `
        -Value $currentUserObjectId `
        -ByEnvironment `
        -IfNotExists

    $null = Test-Argument @parameterArguments `
        -Name 'NetworkAcls_IpRules' `
        -ByEnvironment

    $networkAcls_IpRules = Get-Argument @parameterArguments `
        -Name 'NetworkAcls_IpRules' `
        -ByEnvironment
    if ($null -eq $networkAcls_IpRules)
    {
        if ($PSBoundParameters.ContainsKey('Cdph_ClientIPAddress') -and ![string]::IsNullOrWhiteSpace($Cdph_ClientIPAddress))
        {
            Set-Argument @parameterArguments `
                -Name 'NetworkAcls_IpRules' `
                -Value @([PSCustomObject]@{value = "$Cdph_ClientIPAddress/32"}) `
                -ByEnvironment
        }        
    }
    elseif ($PSBoundParameters.ContainsKey('Cdph_ClientIPAddress') -and ![string]::IsNullOrWhiteSpace($Cdph_ClientIPAddress))
    {
        $combinedIpRules = [System.Collections.ArrayList]::new()
        $null = $combinedIpRules.Add([ordered]@{value = "$Cdph_ClientIPAddress/32"})
        foreach ($ipRule in $networkAcls_IpRules)
        {
            if ($null -ne $ipRule.value)
            {
                $combinedIpRules.Add($ipRule)
            }
        }
        $combinedIpRulesArray = $combinedIpRules.ToArray()
        Set-Argument @parameterArguments `
            -Name 'NetworkAcls_IpRules' `
            -Value $combinedIpRulesArray `
            -ByEnvironment
    }

    # Initialize the secure arguments

    $parameterArguments['ParameterName'] = 'MicrosoftKeyVault_vaults_SecureArguments'

    $null = Test-Argument @parameterArguments

    Set-Argument @parameterArguments `
        -Name 'MicrosoftDBforMySQLAdministratorLoginPassword' `
        -Value $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword

    Set-Argument @parameterArguments `
        -Name 'ProjectREDCapCommunityPassword' `
        -Value $ProjectREDCap_CommunityPassword

    Set-Argument @parameterArguments `
        -Name 'SmtpUserPassword' `
        -Value $Smtp_UserPassword
}

function Set-KeyVaultAppServiceAccessPolicy
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry
    )

    Write-Information 'Setting access policy to allow App Service to read from Key Vault. It''s currently not supported to set an accessPolicy property for an applicationId without an objectId'
    $azureAppServiceApplicationId = 'abfa0a7c-a6b6-4736-8310-5855508787cd' # fixed value for Azure App Services (see https://learn.microsoft.com/azure/app-service/configure-ssl-certificate#authorize-app-service-to-read-from-the-vault)
        
    $keyVault_Arm_ResourceName = Get-Argument `
        -ParametersEntry $ParametersEntry `
        -ParameterName 'MicrosoftKeyVault_vaults_Arguments' `
        -Name 'Arm_ResourceName'

    Set-AzKeyVaultAccessPolicy `
        -VaultName $keyVault_Arm_ResourceName `
        -ServicePrincipalName $azureAppServiceApplicationId `
        -PermissionsToCertificates get `
        -PermissionsToKeys get `
        -PermissionsToSecrets get
        
}

function Import-PfxCertificate
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        [string]
        $Cdph_PfxCertificatePath,

        [Parameter(Mandatory = $true)]
        [securestring]
        $Cdph_PfxCertificatePassword
    )

    $keyVault_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.KeyVault/vaults'

    $appService_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Web/sites'
    
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
}

function Set-Argument
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [object]
        $Value,

        [Parameter()]
        [switch]
        $ByEnvironment,

        [Parameter()]
        [switch]
        $IfNotExists
    )

    $argumentEntry = $ParametersEntry[$ParameterName]
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }

    $argumentValue = $argumentEntry['value']
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = Get-CdphEnvironment -ParametersEntry $ParametersEntry

        $argumentValue_byEnvironment = $argumentValue['byEnvironment']
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = $argumentValue_byEnvironment[$cdphEnvironment]
        if ($null -eq $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment[$cdphEnvironment] = @{}
            $argumentValue_byEnvironment_thisEnvironment = $argumentValue_byEnvironment[$cdphEnvironment]
        }
        # Only replace the value if IfNotExists is false, or if IfNotExists is true and the value is null or whitespace
        if (-not $IfNotExists -or ($IfNotExists -and [string]::IsNullOrWhiteSpace($argumentValue_byEnvironment_thisEnvironment[$Name])))
        {
            $argumentValue_byEnvironment_thisEnvironment[$Name] = $Value
        }
        
    }
    else
    {
        # Only replace the value if IfNotExists is false, or if IfNotExists is true and the value is null or whitespace
        if (-not $IfNotExists -or ($IfNotExists -and [string]::IsNullOrWhiteSpace($argumentValue[$Name])))
        {
            $argumentValue[$Name] = $Value
        }
    }
}

function Get-Argument
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [switch]
        $ByEnvironment
    )

    $argumentEntry = $ParametersEntry[$ParameterName]
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }

    $argumentValue = $argumentEntry['value']
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = Get-CdphEnvironment -ParametersEntry $ParametersEntry

        $argumentValue_byEnvironment = $argumentValue['byEnvironment']
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = $argumentValue_byEnvironment[$cdphEnvironment]
        $foundValue = $false
        if ($null -ne $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment_thisEnvironment_value = $argumentValue_byEnvironment_thisEnvironment[$Name]
            $foundValue = ($null -ne $argumentValue_byEnvironment_thisEnvironment_value)
            if ($foundValue)
            {
                return $argumentValue_byEnvironment_thisEnvironment_value
            }
        }

        if (-not $foundValue)
        {
            $argumentValue_byEnvironment_allEnvironments = $argumentValue_byEnvironment['ALL']
            if ($null -ne $argumentValue_byEnvironment_allEnvironments)
            {
                $argumentValue_byEnvironment_allEnvironments_value = $argumentValue_byEnvironment_allEnvironments[$Name]
                $foundValue = ($null -ne $argumentValue_byEnvironment_allEnvironments_value)
                if ($foundValue)
                {
                    return $argumentValue_byEnvironment_allEnvironments_value
                }
            }
        }

        if (-not $foundValue)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment.$cdphEnvironment.$Name' property or the '$ParameterName.value.byEnvironment.ALL.$Name' property"
        }
    }
    else
    {
        $argumentValue_value = $argumentValue[$Name]
        return $argumentValue_value
    }
    throw "Deployment parameters do not contain a required value for the '$ParameterName.value.$Name' property"
}

function Remove-Argument
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [switch]
        $ByEnvironment
    )

    $argumentEntry = $ParametersEntry[$ParameterName]
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }

    $argumentValue = $argumentEntry['value']
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = Get-CdphEnvironment -ParametersEntry $ParametersEntry

        $argumentValue_byEnvironment = $argumentValue['byEnvironment']
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = $argumentValue_byEnvironment[$cdphEnvironment]
        if ($null -ne $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment_thisEnvironment.Remove($Name)
        }
    }
    else
    {
        $argumentValue.Remove($Name)
    }
}

function Test-Argument
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [switch]
        $ByEnvironment
    )

    $argumentEntry = $ParametersEntry[$ParameterName]
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }
    if ([string]::IsNullOrWhiteSpace($Name))
    {
        return $true
    }

    $argumentValue = $argumentEntry['value']
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = Get-CdphEnvironment -ParametersEntry $ParametersEntry

        $argumentValue_byEnvironment = $argumentValue['byEnvironment']
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = $argumentValue_byEnvironment[$cdphEnvironment]
        $foundValue = $false
        if ($null -ne $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment_thisEnvironment_value = $argumentValue_byEnvironment_thisEnvironment[$Name]
            $foundValue = ($null -ne $argumentValue_byEnvironment_thisEnvironment_value)
        }

        if (-not $foundValue)
        {
            $argumentValue_byEnvironment_allEnvironments = $argumentValue_byEnvironment['ALL']
            if ($null -ne $argumentValue_byEnvironment_allEnvironments)
            {
                $argumentValue_byEnvironment_allEnvironments_value = $argumentValue_byEnvironment_allEnvironments[$Name]
                $foundValue = ($null -ne $argumentValue_byEnvironment_allEnvironments_value)
            }
        }

        if (-not $foundValue)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment.$cdphEnvironment.$Name' property or the '$ParameterName.value.byEnvironment.ALL.$Name' property"
        }
    }
    else
    {
        $argumentValue_value = $argumentValue[$Name]
        if ($null -eq $argumentValue_value)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.$Name' property"
        }
    }
    return $true
}

function Initialize-CommonArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter()]
        [string]
        $Cdph_BusinessUnit,

        [Parameter()]
        [string]
        $Cdph_BusinessUnitProgram
    )

    Write-Information 'Overriding loaded parameters with arguments from the command line'

    $cdph_BusinessUnit_parameters = $ParametersEntry.Cdph_BusinessUnit
    if ($null -eq $cdph_BusinessUnit_parameters)
    {
        $ParametersEntry.Cdph_BusinessUnit = @{value = $Cdph_BusinessUnit}
        $cdph_BusinessUnit_parameters = $ParametersEntry.Cdph_BusinessUnit
    }
    $cdph_BusinessUnit_actual = $cdph_BusinessUnit_parameters.value
    if ($null -eq $cdph_BusinessUnit_actual -or [string]::IsNullOrWhiteSpace($cdph_BusinessUnit_actual))
    {
        throw 'Cdph_BusinessUnit is a required parameter. It must be specified either in the parameters.json file or as a parameter to this function.'
    }

    $cdph_BusinessUnitProgram_parameters = $ParametersEntry.Cdph_BusinessUnitProgram
    if ($null -eq $cdph_BusinessUnitProgram_parameters)
    {
        $ParametersEntry.Cdph_BusinessUnitProgram = @{value = $Cdph_BusinessUnitProgram}
        $cdph_BusinessUnitProgram_parameters = $ParametersEntry.Cdph_BusinessUnitProgram
    }
    $cdph_BusinessUnitProgram_actual = $cdph_BusinessUnitProgram_parameters.value
    if ($null -eq $cdph_BusinessUnitProgram_actual -or [string]::IsNullOrWhiteSpace($cdph_BusinessUnitProgram_actual))
    {
        throw 'Cdph_BusinessUnitProgram is a required parameter. It must be specified either in the parameters.json file or as a parameter to this function.'
    }

    $cdph_Environment_parameters = $ParametersEntry.Cdph_Environment
    if ($null -eq $cdph_Environment_parameters)
    {
        $ParametersEntry.Cdph_Environment = @{value = $Cdph_Environment}
        $cdph_Environment_parameters = $ParametersEntry.Cdph_Environment
    }
    $cdph_Environment_actual = $cdph_Environment_parameters.value
    if ($null -eq $cdph_Environment_actual -or [string]::IsNullOrWhiteSpace($cdph_Environment_actual))
    {
        throw 'Cdph_Environment is a required parameter. It must be specified either in the parameters.json file or as a parameter to this function.'
    }

    # These parameters are not expected to be in the Parameters file
    # TODO[x]: need these?
    # $ParametersEntry.Cdph_Organization = @{value = $Cdph_Organization}
    # $ParametersEntry.Cdph_ResourceInstance = @{value = $Cdph_ResourceInstance}
}

function Get-Parameters
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('KeyVault', 'Main')]
        [string]
        $Template
    )

    $commonParametersPath = '.\redcapAzureDeploy.parameters.common.json'
    $commonParameters = Get-Content $commonParametersPath | ConvertFrom-Json -AsHashtable
    if ($null -eq $commonParameters)
    {
        throw "Unable to load common deployment parameters from $commonParametersPath"
    }
    if (-not $commonParameters.ContainsKey('parameters'))
    {
        throw "Common deployment parameters from $commonParametersPath do not contain a 'parameters' property"
    }
    $commonParametersEntry = $commonParameters['parameters']

    $templateParametersPath = ".\redcapAzureDeploy.parameters.$($Template.ToLower()).json"
    $templateParameters = Get-Content $templateParametersPath | ConvertFrom-Json -AsHashtable
    if ($null -eq $templateParameters)
    {
        throw "Unable to load template deployment parameters from $templateParametersPath"
    }
    if (-not $templateParameters.ContainsKey('parameters'))
    {
        throw "Template deployment parameters from $templateParametersPath do not contain a 'parameters' property"
    }
    $templateParametersEntry = $templateParameters['parameters']

    $mergedParameters = Merge-Hashtables -Hashtables @($commonParametersEntry, $templateParametersEntry)

    return $mergedParameters
}

function Get-ArmAdministratorObjectId
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry
    )

    $arm_AdministratorObjectId_parameters = $ParametersEntry.Arm_AdministratorObjectId
    if ($null -eq $arm_AdministratorObjectId_parameters)
    {
        throw 'Arm_AdministratorObjectId is a required parameter. It must be specified either in the redcapAzureDeploy.parameters.json file or as a parameter to this function.'
    }
    $arm_AdministratorObjectId_actual = $arm_AdministratorObjectId_parameters.value
    if ($null -eq $arm_AdministratorObjectId_actual -or [string]::IsNullOrWhiteSpace($arm_AdministratorObjectId_actual))
    {
        throw 'Arm_AdministratorObjectId is a required parameter. It must be specified either in the redcapAzureDeploy.parameters.json file or as a parameter to this function.'
    }

    return $arm_AdministratorObjectId_actual
}

function Get-CdphEnvironment
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry
    )

    $cdph_Environment_parameters = $ParametersEntry.Cdph_Environment
    if ($null -eq $cdph_Environment_parameters)
    {
        throw 'Cdph_Environment is a required parameter. It must be specified either in the redcapAzureDeploy.parameters.json file or as a parameter to this function.'
    }
    $cdph_Environment_actual = $cdph_Environment_parameters.value
    if ($null -eq $cdph_Environment_actual -or [string]::IsNullOrWhiteSpace($cdph_Environment_actual))
    {
        throw 'Cdph_Environment is a required parameter. It must be specified either in the redcapAzureDeploy.parameters.json file or as a parameter to this function.'
    }

    return $cdph_Environment_actual
}

function Deploy-ResourceGroup
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    Write-Information 'Initializing Resource Group'

    $microsoftResources_resourceGroups_Arguments = $ParametersEntry.MicrosoftResources_resourceGroups_Arguments.value
    $resourceGroupName = $microsoftResources_resourceGroups_Arguments.Arm_ResourceName
    if ($null -eq $resourceGroupName -or [string]::IsNullOrWhiteSpace($resourceGroupName))
    {
        $resourceGroupName = Get-CdphResourceName `
            -ParametersEntry $ParametersEntry `
            -ResourceDeployment $ResourceDeployment `
            -Arm_ResourceProvider 'Microsoft.Resources/resourceGroups'
    }

    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($null -eq $resourceGroup)
    {
        $resourceGroup_byEnvironment = $microsoftResources_resourceGroups_Arguments.byEnvironment
        if ($null -eq $resourceGroup_byEnvironment)
        {
            throw 'byEnvironment is a required parameter of MicrosoftResources_resourceGroups_Arguments.value. It must be specified in the redcapAzureDeploy.parameters.json file.'
        }
        
        $cdphEnvironment = Get-CdphEnvironment -ParametersEntry $ParametersEntry
    
        $resourceGroup_byEnvironment_thisEnvironment = $resourceGroup_byEnvironment[$cdphEnvironment]
        $resourceGroup_byEnvironment_allEnvironments = $resourceGroup_byEnvironment.ALL
    
        $resourceGroup_Arm_Location = $null
        if ($null -ne $resourceGroup_byEnvironment_thisEnvironment)
        {
            $resourceGroup_Arm_Location = $resourceGroup_byEnvironment_thisEnvironment['Arm_Location']
        }
        if ($null -eq $resourceGroup_Arm_Location)
        {
            $resourceGroup_Arm_Location = $resourceGroup_byEnvironment_allEnvironments['Arm_Location']
        }
        if ($null -eq $resourceGroup_Arm_Location)
        {
            throw 'Arm_Location is a required parameter of MicrosoftResources_resourceGroups_Arguments.value.byEnvironment. It must be specified in the redcapAzureDeploy.parameters.json file.'
        }
        
        Write-Information "Creating Resource Group $resourceGroupName in $resourceGroup_Arm_Location"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroup_Arm_Location
    }
    else
    {
        $resourceGroup_Arm_Location = $resourceGroup.Location
        Write-Information "Using existing Resource Group $resourceGroupName in $resourceGroup_Arm_Location"
    }
}

function Get-CdphResourceName
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment,

        # Resource Provider Name
        [Parameter(Mandatory = $true)]
        [string]
        $Arm_ResourceProvider
    )

    $cdph_BusinessUnit_actual = $ParametersEntry.Cdph_BusinessUnit.value
    $cdph_BusinessUnitProgram_actual = $ParametersEntry.Cdph_BusinessUnitProgram.value
    $cdph_Environment_actual = $ParametersEntry.Cdph_Environment.value

    $resourceNameArgs = @{
        Arm_ResourceProvider     = $Arm_ResourceProvider
        Cdph_Organization        = $ResourceDeployment.Cdph_Organization
        Cdph_BusinessUnit        = $cdph_BusinessUnit_actual
        Cdph_BusinessUnitProgram = $cdph_BusinessUnitProgram_actual
        Cdph_Environment         = $cdph_Environment_actual
        Cdph_ResourceInstance    = $ResourceDeployment.Cdph_ResourceInstance
    }

    $resourceName = New-CdphResourceName @resourceNameArgs
    return $resourceName
}