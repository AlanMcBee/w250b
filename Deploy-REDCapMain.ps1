<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCapMain.ps1

This .PS1 is meant to be loaded using dot-sourcing (.) or using the using module command. It is not meant to be executed directly.

#>

using namespace System.Diagnostics

#requires -Modules Az.Resources
#requires -Version 7.1

using module .\ErrorRecord.psm1
using module .\CdphNaming.psm1

<#
.SYNOPSIS
Invokes the deployment of the REDCap main site using Bicep.

.DESCRIPTION
Instead of loading the parameters from a file, this function will load the parameters from the file redcapAzureDeployKeyVault.parameters.json and then override the values with the values passed in as parameters to this function. This allows the parameters to be loaded from a file and then overridden with values passed in from the command line.
#>
function Deploy-REDCapMain
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

        # Optional CDPH environment name to allow multiple deployments to the same subscription. If not specified, the default value of 'dev' will be used.
        [Parameter()]
        [ValidateSet('dev', 'test', 'stage', 'prod')]
        [string]
        $Cdph_Environment,
        
        # Optional CDPH resource instance number to allow multiple deployments to the same subscription. If not specified, the default value of 1 will be used.
        [Parameter()]
        [int]
        $Cdph_ResourceInstance = 1,

        # Password for MySQL administrator account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $DatabaseForMySql_AdministratorLoginPassword,

        # Password for the REDCap Community site account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $ProjectRedcap_CommunityPassword,

        # Password for the SMTP server account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $Smtp_UserPassword
    )

    $deploymentResult = [PSCustomObject]@{
        Successful       = $true
        Error            = $null
        DeploymentErrors = $null
        DeploymentOutput = $null
    }

    [Stopwatch] $stopwatch = [Stopwatch]::StartNew()

    Write-Information "Beginning deployment at $((Get-Date).ToString())"

    try
    {
        Write-Information 'Making sure that all required parameters are present and have values in the file redcapAzureDeployMain.parameters.json'

        $requiredParameters = @(
            'MicrosoftNetwork_virtualNetworks',
            'MicrosoftKeyVault_vaults',
            'MicrosoftStorage_storageAccounts',
            'MicrosoftDBforMySQL_flexibleServers',
            'MicrosoftWeb_serverfarms',
            'MicrosoftWeb_sites',
            'MicrosoftWeb_certificates',
            'MicrosoftInsights_components',
            'MicrosoftOperationalInsights_workspaces',
            'ProjectREDCap',
            'Smtp'
        )
        $deployParametersPath = 'redcapAzureDeployMain.parameters.json'
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
            if (0 -eq $parametersEntry[$requiredParameter].value.Length)
            {
                throw "Deployment parameters from $deployParametersPath do not contain a required value for the '$requiredParameter' property"
            }
        }

        Write-Information 'Overriding loaded parameters from redcapAzureDeployMain.parameters.json with arguments from the command line'
        
        # Common parameters
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
        # ----------------------------

        # Virtual Network

        $microsoftNetwork_virtualNetworks = $parametersEntry['MicrosoftNetwork_virtualNetworks']

        # Key Vault

        $microsoftKeyVault_vaults = $parametersEntry['MicrosoftKeyVault_vaults']
        $keyVault_Arguments = $microsoftKeyVault_vaults.value
        if ($null -eq $keyVault_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftKeyVault_vaults.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.KeyVault/vaults'
        $keyVault_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $keyVault_Arguments['Arm_ResourceName'] = $keyVault_Arm_ResourceName

        # Storage Account

        $microsoftStorage_storageAccounts = $parametersEntry['MicrosoftStorage_storageAccounts']
        $storageAccount_Arguments = $microsoftStorage_storageAccounts.value
        if ($null -eq $storageAccount_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftStorage_storageAccounts.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Storage/storageAccounts'
        $storageAccount_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $storageAccount_Arguments['Arm_ResourceName'] = $storageAccount_Arm_ResourceName

        $storageAccount_byEnvironment = $storageAccount_Arguments.byEnvironment
        if ($null -eq $storageAccount_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftStorage_storageAccounts.value.byEnvironment' property"
        }
        $storageAccount_byEnvironment_thisEnvironment = $storageAccount_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $storageAccount_byEnvironment_thisEnvironment)
        {
            $storageAccount_byEnvironment[$cdph_Environment_actual] = $null
            $storageAccount_byEnvironment_thisEnvironment = $storageAccount_byEnvironment[$cdph_Environment_actual]
        }
        $storageAccount_byEnvironment_allEnvironments = $storageAccount_byEnvironment.ALL
        if ($null -eq $storageAccount_byEnvironment_allEnvironments)
        {
            $storageAccount_byEnvironment.ALL = $null
            $storageAccount_byEnvironment_allEnvironments = $storageAccount_byEnvironment.ALL
        }

        $storageAccount_Arm_Location = $storageAccount_byEnvironment_thisEnvironment.Arm_Location ?? $storageAccount_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($storageAccount_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftStorage_storageAccounts.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftStorage_storageAccounts.value.byEnvironment.ALL.Arm_Location' property"
        }

        $storageAccount_Redundancy = $storageAccount_byEnvironment_thisEnvironment.Redundancy ?? $storageAccount_byEnvironment_allEnvironments.Redundancy
        if ([string]::IsNullOrWhiteSpace($storageAccount_Redundancy))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftStorage_storageAccounts.value.byEnvironment.$cdph_Environment_actual.Redundancy' property or the 'MicrosoftStorage_storageAccounts.value.byEnvironment.ALL.Redundancy' property"
        }

        $storageAccount_ContainerName = $storageAccount_byEnvironment_thisEnvironment.ContainerName ?? $storageAccount_byEnvironment_allEnvironments.ContainerName
        if ([string]::IsNullOrWhiteSpace($storageAccount_ContainerName))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftStorage_storageAccounts.value.byEnvironment.$cdph_Environment_actual.ContainerName' property or the 'MicrosoftStorage_storageAccounts.value.byEnvironment.ALL.ContainerName' property"
        }

        # MySQL Database

        $microsoftDBforMySQL_flexibleServers = $parametersEntry['MicrosoftDBforMySQL_flexibleServers']
        $mysqlDatabase_Arguments = $microsoftDBforMySQL_flexibleServers.value
        if ($null -eq $mysqlDatabase_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.DBforMySQL/flexibleServers'
        $mysqlDatabase_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $mysqlDatabase_Arguments['Arm_ResourceName'] = $mysqlDatabase_Arm_ResourceName

        $mySqlDatabase_byEnvironment = $mysqlDatabase_Arguments.byEnvironment
        if ($null -eq $mySqlDatabase_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment' property"
        }
        $mySqlDatabase_byEnvironment_thisEnvironment = $mySqlDatabase_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $mySqlDatabase_byEnvironment_thisEnvironment)
        {
            $mySqlDatabase_byEnvironment[$cdph_Environment_actual] = $null
            $mySqlDatabase_byEnvironment_thisEnvironment = $mySqlDatabase_byEnvironment[$cdph_Environment_actual]
        }
        $mySqlDatabase_byEnvironment_allEnvironments = $mySqlDatabase_byEnvironment.ALL
        if ($null -eq $mySqlDatabase_byEnvironment_allEnvironments)
        {
            $mySqlDatabase_byEnvironment.ALL = $null
            $mySqlDatabase_byEnvironment_allEnvironments = $mySqlDatabase_byEnvironment.ALL
        }

        $mySqlDatabase_Arm_Location = $mySqlDatabase_byEnvironment_thisEnvironment.Arm_Location ?? $mySqlDatabase_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.Arm_Location' property"
        }

        $mySqlDatabase_Tier = $mySqlDatabase_byEnvironment_thisEnvironment.Tier ?? $mySqlDatabase_byEnvironment_allEnvironments.Tier
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_Tier))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.Tier' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.Tier' property"
        }
        $mySqlDatabase_Sku = $mySqlDatabase_byEnvironment_thisEnvironment.Sku ?? $mySqlDatabase_byEnvironment_allEnvironments.Sku
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_Sku))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.Sku' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.Sku' property"
        }
        $mySqlDatabase_StorageGB = $mySqlDatabase_byEnvironment_thisEnvironment.StorageGB ?? $mySqlDatabase_byEnvironment_allEnvironments.StorageGB
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_StorageGB))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.StorageGB' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.StorageGB' property"
        }
        $mySqlDatabase_BackupRetentionDays = $mySqlDatabase_byEnvironment_thisEnvironment.BackupRetentionDays ?? $mySqlDatabase_byEnvironment_allEnvironments.BackupRetentionDays
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_BackupRetentionDays))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.BackupRetentionDays' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.BackupRetentionDays' property"
        }
        $mySqlDatabase_DatabaseName = $mySqlDatabase_byEnvironment_thisEnvironment.DatabaseName ?? $mySqlDatabase_byEnvironment_allEnvironments.DatabaseName
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_DatabaseName))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.DatabaseName' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.DatabaseName' property"
        }
        $mySqlDatabase_AdministratorLoginName = $mySqlDatabase_byEnvironment_thisEnvironment.AdministratorLoginName ?? $mySqlDatabase_byEnvironment_allEnvironments.AdministratorLoginName
        if ([string]::IsNullOrWhiteSpace($mySqlDatabase_AdministratorLoginName))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.AdministratorLoginName' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.AdministratorLoginName' property"
        }
        $mySqlDatabase_FirewallRules = $mySqlDatabase_byEnvironment_thisEnvironment.FirewallRules ?? $mySqlDatabase_byEnvironment_allEnvironments.FirewallRules
        if ($null -eq $mySqlDatabase_FirewallRules)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.$cdph_Environment_actual.FirewallRules' property or the 'MicrosoftDBforMySQL_flexibleServers.value.byEnvironment.ALL.FirewallRules' property"
        }

        $mySqlDatabase_AdministratorLoginPassword = $parametersEntry['MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword']
        if ($null -eq $mySqlDatabase_AdministratorLoginPassword)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword' property"
        }
        $mySqlDatabase_AdministratorLoginPassword_Reference = $null -ne $mySqlDatabase_AdministratorLoginPassword.reference

        if (-not [string]::IsNullOrWhiteSpace($DatabaseForMySql_AdministratorLoginPassword)){
            if ($mySqlDatabase_AdministratorLoginPassword_Reference) {
                $mySqlDatabase_AdministratorLoginPassword.reference = $null
            }
            $mySqlDatabase_AdministratorLoginPassword.value = $DatabaseForMySql_AdministratorLoginPassword
        }
        elseif (-not $mySqlDatabase_AdministratorLoginPassword_Reference) {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword' property. The value should be a reference to a secret in the Key Vault or a secure string value."
        }

        # App Service Plan
        # ----------------

        $microsoftWeb_serverfarms = $parametersEntry['MicrosoftWeb_serverfarms']
        $appServicePlan_Arguments = $microsoftWeb_serverfarms.value
        if ($null -eq $appServicePlan_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Web/serverfarms'
        $appServicePlan_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $appServicePlan_Arguments.ARM_ResourceName = $appServicePlan_Arm_ResourceName

        $appServicePlan_byEnvironment = $appServicePlan_Arguments.byEnvironment
        if ($null -eq $appServicePlan_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value.byEnvironment' property"
        }
        $appServicePlan_byEnvironment_thisEnvironment = $appServicePlan_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $appServicePlan_byEnvironment_thisEnvironment)
        {
            $appServicePlan_byEnvironment[$cdph_Environment_actual] = $null
            $appServicePlan_byEnvironment_thisEnvironment = $appServicePlan_byEnvironment[$cdph_Environment_actual]
        }
        $appServicePlan_byEnvironment_allEnvironments = $appServicePlan_byEnvironment.ALL
        if ($null -eq $appServicePlan_byEnvironment_allEnvironments)
        {
            $appServicePlan_byEnvironment.ALL = $null
            $appServicePlan_byEnvironment_allEnvironments = $appServicePlan_byEnvironment.ALL
        }

        $appServicePlan_Arm_Location = $appServicePlan_byEnvironment_thisEnvironment.Arm_Location ?? $appServicePlan_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($appServicePlan_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftWeb_serverfarms.value.byEnvironment.ALL.Arm_Location' property"
        }

        $appServicePlan_Tier = $appServicePlan_byEnvironment_thisEnvironment.Tier ?? $appServicePlan_byEnvironment_allEnvironments.Tier
        if ([string]::IsNullOrWhiteSpace($appServicePlan_Tier))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value.byEnvironment.$cdph_Environment_actual.Tier' property or the 'MicrosoftWeb_serverfarms.value.byEnvironment.ALL.Tier' property"
        }
        $appServicePlan_SkuName = $appServicePlan_byEnvironment_thisEnvironment.SkuName ?? $appServicePlan_byEnvironment_allEnvironments.SkuName
        if ([string]::IsNullOrWhiteSpace($appServicePlan_SkuName))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value.byEnvironment.$cdph_Environment_actual.SkuName' property or the 'MicrosoftWeb_serverfarms.value.byEnvironment.ALL.SkuName' property"
        }
        $appServicePlan_Capacity = $appServicePlan_byEnvironment_thisEnvironment.Capacity ?? $appServicePlan_byEnvironment_allEnvironments.Capacity
        if ([string]::IsNullOrWhiteSpace($appServicePlan_Capacity))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value.byEnvironment.$cdph_Environment_actual.Capacity' property or the 'MicrosoftWeb_serverfarms.value.byEnvironment.ALL.Capacity' property"
        }
        $appServicePlan_LinuxFxVersion = $appServicePlan_byEnvironment_thisEnvironment.LinuxFxVersion ?? $appServicePlan_byEnvironment_allEnvironments.LinuxFxVersion
        if ([string]::IsNullOrWhiteSpace($appServicePlan_LinuxFxVersion))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_serverfarms.value.byEnvironment.$cdph_Environment_actual.LinuxFxVersion' property or the 'MicrosoftWeb_serverfarms.value.byEnvironment.ALL.LinuxFxVersion' property"
        }

        # App Service
        # -----------

        $microsoftWeb_sites = $parametersEntry['MicrosoftWeb_sites']
        $appService_Arguments = $microsoftWeb_sites.value
        if ($null -eq $appService_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_sites.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Web/sites'
        $appService_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $appService_Arguments.Arm_ResourceName = $appService_Arm_ResourceName

        $appService_byEnvironment = $appService_Arguments.byEnvironment
        if ($null -eq $appService_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_sites.value.byEnvironment' property"
        }
        $appService_byEnvironment_thisEnvironment = $appService_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $appService_byEnvironment_thisEnvironment)
        {
            $appService_byEnvironment[$cdph_Environment_actual] = $null
            $appService_byEnvironment_thisEnvironment = $appService_byEnvironment[$cdph_Environment_actual]
        }
        $appService_byEnvironment_allEnvironments = $appService_byEnvironment.ALL
        if ($null -eq $appService_byEnvironment_allEnvironments)
        {
            $appService_byEnvironment.ALL = $null
            $appService_byEnvironment_allEnvironments = $appService_byEnvironment.ALL
        }

        $appService_SourceControl_GitHubRepositoryUrl = $appService_byEnvironment_thisEnvironment.SourceControl_GitHubRepositoryUrl ?? $appService_byEnvironment_allEnvironments.SourceControl_GitHubRepositoryUrl
        if ([string]::IsNullOrWhiteSpace($appService_SourceControl_GitHubRepositoryUrl))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_sites.value.byEnvironment.$cdph_Environment_actual.SourceControl_GitHubRepositoryUrl' property or the 'MicrosoftWeb_sites.value.byEnvironment.ALL.SourceControl_GitHubRepositoryUrl' property"
        }
        $appService_CustomFullyQualifiedDomainName = $appService_byEnvironment_thisEnvironment.CustomFullyQualifiedDomainName ?? $appService_byEnvironment_allEnvironments.CustomFullyQualifiedDomainName
        if ([string]::IsNullOrWhiteSpace($appService_CustomFullyQualifiedDomainName))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_sites.value.byEnvironment.$cdph_Environment_actual.CustomFullyQualifiedDomainName' property or the 'MicrosoftWeb_sites.value.byEnvironment.ALL.CustomFullyQualifiedDomainName' property"
        }

        # App Service Certificates
        # ------------------------
        
        $microsoftWeb_certificates = $parametersEntry['MicrosoftWeb_certificates']
        $appServiceCertificate_Arguments = $microsoftWeb_certificates.value
        if ($null -eq $appServiceCertificate_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_certificates.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Web/certificates'
        $appServiceCertificate_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $appServiceCertificate_Arguments.Arm_ResourceName = $appServiceCertificate_Arm_ResourceName

        $appServiceCertificate_byEnvironment = $appServiceCertificate_Arguments.byEnvironment
        if ($null -eq $appServiceCertificate_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_certificates.value.byEnvironment' property"
        }
        $appServiceCertificate_byEnvironment_thisEnvironment = $appServiceCertificate_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $appServiceCertificate_byEnvironment_thisEnvironment)
        {
            $appServiceCertificate_byEnvironment[$cdph_Environment_actual] = $null
            $appServiceCertificate_byEnvironment_thisEnvironment = $appServiceCertificate_byEnvironment[$cdph_Environment_actual]
        }
        $appServiceCertificate_byEnvironment_allEnvironments = $appServiceCertificate_byEnvironment.ALL
        if ($null -eq $appServiceCertificate_byEnvironment_allEnvironments)
        {
            $appServiceCertificate_byEnvironment.ALL = $null
            $appServiceCertificate_byEnvironment_allEnvironments = $appServiceCertificate_byEnvironment.ALL
        }

        $appServiceCertificate_Arm_Location = $appServiceCertificate_byEnvironment_thisEnvironment.Arm_Location ?? $appServiceCertificate_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($appServiceCertificate_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftWeb_certificates.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftWeb_certificates.value.byEnvironment.ALL.Arm_Location' property"
        }

        # App Insights
        # ------------

        $microsoftInsights_components = $parametersEntry['MicrosoftInsights_components']
        $appInsights_Arguments = $microsoftInsights_components.value
        if ($null -eq $appInsights_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftInsights_components.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.Insights/components'
        $appInsights_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $appInsights_Arguments.Arm_ResourceName = $appInsights_Arm_ResourceName

        $appInsights_byEnvironment = $appInsights_Arguments.byEnvironment
        if ($null -eq $appInsights_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftInsights_components.value.byEnvironment' property"
        }
        $appInsights_byEnvironment_thisEnvironment = $appInsights_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $appInsights_byEnvironment_thisEnvironment)
        {
            $appInsights_byEnvironment[$cdph_Environment_actual] = $null
            $appInsights_byEnvironment_thisEnvironment = $appInsights_byEnvironment[$cdph_Environment_actual]
        }
        $appInsights_byEnvironment_allEnvironments = $appInsights_byEnvironment.ALL
        if ($null -eq $appInsights_byEnvironment_allEnvironments)
        {
            $appInsights_byEnvironment.ALL = $null
            $appInsights_byEnvironment_allEnvironments = $appInsights_byEnvironment.ALL
        }

        $appInsights_Arm_Location = $appInsights_byEnvironment_thisEnvironment.Arm_Location ?? $appInsights_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($appInsights_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftInsights_components.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftInsights_components.value.byEnvironment.ALL.Arm_Location' property"
        }

        $appInsights_Enabled = $appInsights_byEnvironment_thisEnvironment.enabled ?? $appInsights_byEnvironment_allEnvironments.enabled
        if ($null -eq $appInsights_Enabled)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftInsights_components.value.byEnvironment.$cdph_Environment_actual.enabled' property or the 'MicrosoftInsights_components.value.byEnvironment.ALL.enabled' property"
        }

        # Operational Insights (Log Analytics)
        # ------------------------------------

        $microsoftOperationalInsights_workspaces = $parametersEntry['MicrosoftOperationalInsights_workspaces']
        $operationalInsights_Arguments = $microsoftOperationalInsights_workspaces.value
        if ($null -eq $operationalInsights_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftOperationalInsights_workspaces.value' property"
        }

        $resourceNameArgs.Arm_ResourceProvider = 'Microsoft.OperationalInsights/workspaces'
        $operationalInsights_Arm_ResourceName = New-CdphResourceName @resourceNameArgs
        $operationalInsights_Arguments.Arm_ResourceName = $operationalInsights_Arm_ResourceName

        $operationalInsights_byEnvironment = $operationalInsights_Arguments.byEnvironment
        if ($null -eq $operationalInsights_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftOperationalInsights_workspaces.value.byEnvironment' property"
        }
        $operationalInsights_byEnvironment_thisEnvironment = $operationalInsights_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $operationalInsights_byEnvironment_thisEnvironment)
        {
            $operationalInsights_byEnvironment[$cdph_Environment_actual] = $null
            $operationalInsights_byEnvironment_thisEnvironment = $operationalInsights_byEnvironment[$cdph_Environment_actual]
        }
        $operationalInsights_byEnvironment_allEnvironments = $operationalInsights_byEnvironment.ALL
        if ($null -eq $operationalInsights_byEnvironment_allEnvironments)
        {
            $operationalInsights_byEnvironment.ALL = $null
            $operationalInsights_byEnvironment_allEnvironments = $operationalInsights_byEnvironment.ALL
        }

        $operationalInsights_Arm_Location = $operationalInsights_byEnvironment_thisEnvironment.Arm_Location ?? $operationalInsights_byEnvironment_allEnvironments.Arm_Location
        if ([string]::IsNullOrWhiteSpace($operationalInsights_Arm_Location))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'MicrosoftOperationalInsights_workspaces.value.byEnvironment.$cdph_Environment_actual.Arm_Location' property or the 'MicrosoftOperationalInsights_workspaces.value.byEnvironment.ALL.Arm_Location' property"
        }

        # Project REDCap
        # --------------

        $projectREDCap = $parametersEntry['ProjectREDCap']
        $projectREDCap_Arguments = $projectREDCap.value
        if ($null -eq $projectREDCap_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'ProjectREDCap.value' property"
        }

        $projectREDCap_OverrideAutomaticDownloadUrlBuilder = $projectREDCap_Arguments.OverrideAutomaticDownloadUrlBuilder
        if ($null -eq $projectREDCap_OverrideAutomaticDownloadUrlBuilder)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'ProjectREDCap.value.OverrideAutomaticDownloadUrlBuilder' property"
        }

        $projectREDCap_CommunityPassword = $parametersEntry['ProjectREDCap_CommunityPassword']
        if ($null -eq $projectREDCap_CommunityPassword)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'ProjectREDCap_CommunityPassword' property"
        }
        $projectREDCap_CommunityPassword_Reference = $null -ne $projectREDCap_CommunityPassword.reference

        if (-not [string]::IsNullOrWhiteSpace($ProjectRedcap_CommunityPassword)){
            if ($projectREDCap_CommunityPassword_Reference) {
                $projectREDCap_CommunityPassword.reference = $null
            }
            $projectREDCap_CommunityPassword.value = $ProjectRedcap_CommunityPassword
        }
        elseif (-not $projectREDCap_CommunityPassword_Reference) {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'ProjectREDCap_CommunityPassword' property. The value should be a reference to a secret in the Key Vault or a secure string value."
        }

        # SMTP
        # ----

        $smtp = $parametersEntry['Smtp']
        $smtp_Arguments = $smtp.value
        if ($null -eq $smtp_Arguments)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp.value' property"
        }

        $smtp_byEnvironment = $smtp_Arguments.byEnvironment
        if ($null -eq $smtp_byEnvironment)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp.value.byEnvironment' property"
        }
        $smtp_byEnvironment_thisEnvironment = $smtp_byEnvironment[$cdph_Environment_actual]
        if ($null -eq $smtp_byEnvironment_thisEnvironment)
        {
            $smtp_byEnvironment[$cdph_Environment_actual] = $null
            $smtp_byEnvironment_thisEnvironment = $smtp_byEnvironment[$cdph_Environment_actual]
        }
        $smtp_byEnvironment_allEnvironments = $smtp_byEnvironment.ALL
        if ($null -eq $smtp_byEnvironment_allEnvironments)
        {
            $smtp_byEnvironment.ALL = $null
            $smtp_byEnvironment_allEnvironments = $smtp_byEnvironment.ALL
        }

        $smtp_HostFqdn = $smtp_byEnvironment_thisEnvironment.HostFqdn ?? $smtp_byEnvironment_allEnvironments.HostFqdn
        if ([string]::IsNullOrWhiteSpace($smtp_HostFqdn))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp.value.byEnvironment.$cdph_Environment_actual.HostFqdn' property or the 'Smtp.value.byEnvironment.ALL.HostFqdn' property"
        }
        $smtp_Port = $smtp_byEnvironment_thisEnvironment.Port ?? $smtp_byEnvironment_allEnvironments.Port
        if ($null -eq $smtp_Port)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp.value.byEnvironment.$cdph_Environment_actual.Port' property or the 'Smtp.value.byEnvironment.ALL.Port' property"
        }
        $smtp_UserLogin = $smtp_byEnvironment_thisEnvironment.UserLogin ?? $smtp_byEnvironment_allEnvironments.UserLogin
        if ([string]::IsNullOrWhiteSpace($smtp_UserLogin))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp.value.byEnvironment.$cdph_Environment_actual.UserLogin' property or the 'Smtp.value.byEnvironment.ALL.UserLogin' property"
        }
        $smtp_FromEmailAddress = $smtp_byEnvironment_thisEnvironment.FromEmailAddress ?? $smtp_byEnvironment_allEnvironments.FromEmailAddress
        if ([string]::IsNullOrWhiteSpace($smtp_FromEmailAddress))
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp.value.byEnvironment.$cdph_Environment_actual.FromEmailAddress' property or the 'Smtp.value.byEnvironment.ALL.FromEmailAddress' property"
        }

        $smtp_UserPassword = $parametersEntry['Smtp_UserPassword']
        if ($null -eq $smtp_UserPassword)
        {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp_UserPassword' property"
        }
        $smtp_UserPassword_Reference = $null -ne $smtp_UserPassword.reference

        if (-not [string]::IsNullOrWhiteSpace($Smtp_UserPassword)){
            if ($smtp_UserPassword_Reference) {
                $smtp_UserPassword.reference = $null
            }
            $smtp_UserPassword.value = $Smtp_UserPassword
        }
        elseif (-not $smtp_UserPassword_Reference) {
            throw "Deployment parameters from $deployParametersPath do not contain a required value for the 'Smtp_UserPassword' property. The value should be a reference to a secret in the Key Vault or a secure string value."
        }

        # Deploy
        # ------

        # Make sure we're logged in. Use Connect-AzAccount if not.
        Get-AzContext -ErrorAction Stop | Out-Null

        # Start deployment
        $bicepPath = 'redcapAzureDeployMain.bicep'

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
        $deploymentName = "REDCapDeployMain.$version"
        $deployArgs = @{
            ResourceGroupName       = $resourceGroupName
            TemplateFile            = $bicepPath
            Name                    = $deploymentName
            TemplateParameterObject = $templateParameters
        }
        # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment]
        $armDeployment = $null
        $armDeployment = New-AzResourceGroupDeployment @deployArgs -Force -Verbose -DeploymentDebugLogLevel ResponseContent -ErrorAction Continue | Select-Object -First 1
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
            $deploymentResult.DeploymentOutput = $armDeployment.Outputs

            Start-Process "https://$($appService_CustomFullyQualifiedDomainName)/AzDeployStatus.php"
        }
        else
        {
            $deploymentResult.Successful = $false
            # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSDeploymentOperation]
            $deploymentErrors = $null
            $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
            $e = $deploymentErrors | ConvertTo-Json -Depth 5
            $deploymentResult.Error = $e
            $deploymentResult.DeploymentErrors = $deploymentErrors
        }
    }
    catch
    {
        $x = $_
        Write-CaughtErrorRecord -CaughtError $x -ErrorLevel Error -IncludeStackTrace
        $deploymentResult.Error = $x
        $deploymentResult.Successful = $false
    }
    finally
    {
        # Stop timer
        $stopwatch.Stop()
        $measured = $stopwatch.Elapsed
    
        Write-Information "Total Main Deployment time: $($measured.ToString())"
        
    }
    return $deploymentResult
}