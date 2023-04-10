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

class SecureArguments
{
    [securestring] $MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword
    [securestring] $MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword
    [securestring] $MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword

    SecureArguments (
        [securestring] $MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword,
        [securestring] $MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword,
        [securestring] $MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
    )
    {
        $this.MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword = $MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword
        $this.MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword = $MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword
        $this.MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword = $MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
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
        $MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword,

        # Password for the REDCap Community site account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter()]
        [securestring]
        $MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword,

        # Password for the SMTP server account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
    )

    $progressActivity = 'Deploying REDCap infrastructure to Azure'
    try
    {
        if ($ProgressPreference -eq 'Continue')
        {
            Write-Progress -Activity $progressActivity -Status 'Deploying Key Vault' -PercentComplete 10
        }

        $secureArguments = [SecureArguments]::new(
            $MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword,
            $MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword,
            $MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
        )

        $templateParametersPath = ".\redcapAzureDeployParameters.json"
        $templateParameters = Get-Content $templateParametersPath | ConvertFrom-Json -AsHashtable
        $keyVaultParametersEntry = Get-HashtableValue $templateParameters 'parameters'

        Initialize-CommonArguments `
            -ParametersEntry $keyVaultParametersEntry `
            -Cdph_BusinessUnit $Cdph_BusinessUnit `
            -Cdph_BusinessUnitProgram $Cdph_BusinessUnitProgram

        $cdph_Environment_Actual = $Cdph_Environment
        if ([string]::IsNullOrWhiteSpace($cdph_Environment_Actual))
        {
            $cdph_Environment_Actual = Get-Argument -ParametersEntry $keyVaultParametersEntry -ArgumentName 'Cdph_Environment'
        }

        $resourceDeployment = [ResourceDeployment]::new(
            $Cdph_Organization,
            $cdph_Environment_Actual,
            $Cdph_ResourceInstance
        )

        Deploy-ResourceGroup `
            -ParametersEntry $keyVaultParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-VirtualNetworkArguments `
            -ParametersEntry $keyVaultParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-KeyVaultArguments `
            -ParametersEntry $keyVaultParametersEntry `
            -ResourceDeployment $resourceDeployment `
            -Cdph_ClientIPAddress $Cdph_ClientIPAddress `
            -SecureArguments $SecureArguments

        $deploymentParameters = Compress-Arguments `
            -Template 'KeyVault' `
            -ResourceDeployment $resourceDeployment `
            -ParametersEntry $keyVaultParametersEntry `
            -SecureArguments $secureArguments

        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment] $deploymentResult = $null
        $deploymentResult = Deploy-Bicep `
            -Template 'KeyVault' `
            -ResourceDeployment $resourceDeployment `
            -ParametersEntry $deploymentParameters

        if ($deploymentResult.ProvisioningState -ne 'Succeeded')
        {
            Write-Error 'Key Vault deployment failed.'
            throw $deploymentResult
        }

        if ($ProgressPreference -eq 'Continue')
        {
            Write-Progress -Activity $progressActivity -Status 'Importing server certificate to Key Vault' -PercentComplete 20
        }

        Set-KeyVaultAppServiceAccessPolicy `
            -ParametersEntry $keyVaultParametersEntry

        Import-PfxCertificate `
            -ParametersEntry $keyVaultParametersEntry `
            -ResourceDeployment $resourceDeployment `
            -Cdph_PfxCertificatePath $Cdph_PfxCertificatePath `
            -Cdph_PfxCertificatePassword $Cdph_PfxCertificatePassword

        if ($ProgressPreference -eq 'Continue')
        {
            Write-Progress -Activity $progressActivity -Status 'Deploying MySQL, Storage Account, Web Site, and Application Insights' -PercentComplete 40
        }

        # Reset parameters
        $templateParameters = Get-Content $templateParametersPath | ConvertFrom-Json -AsHashtable
        $mainParametersEntry = Get-HashtableValue $templateParameters 'parameters'

        Initialize-CommonArguments `
            -ParametersEntry $mainParametersEntry `
            -Cdph_BusinessUnit $Cdph_BusinessUnit `
            -Cdph_BusinessUnitProgram $Cdph_BusinessUnitProgram

        Initialize-VirtualNetworkArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-KeyVaultResourceNameArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-StorageAccountArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-MySQLArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment `
            -MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword

        Initialize-AppServicePlanArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-AppServiceCertificatesArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $ResourceDeployment

        Initialize-AppServiceArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-REDCapArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-SmtpArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-LogAnalyticsArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        Initialize-AppInsightsArguments `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment

        $deploymentParameters = Compress-Arguments `
            -Template 'Main' `
            -ResourceDeployment $resourceDeployment `
            -ParametersEntry $mainParametersEntry `
            -SecureArguments $secureArguments

        $deploymentResult = Deploy-Bicep `
            -ParametersEntry $mainParametersEntry `
            -ResourceDeployment $resourceDeployment `
            -Template 'Main'

        if ($deploymentResult.ProvisioningState -ne 'Succeeded')
        {
            Write-Error 'Main resource deployments failed.'
            throw $deploymentResult
        }
    }
    finally
    {
        if ($ProgressPreference -eq 'Continue')
        {
            Write-Progress -Activity $progressActivity -Completed
        }
    }

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
    if ($VerbosePreference -eq 'Continue')
    {
        $regularParameters = @{}
        foreach ($parameterKey in $parameters.Keys)
        {
            $regularParameters[$parameterKey] = @{value = Get-HashtableValue $parameters $parameterKey}
        }
        $parametersDoc = @{
            '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
            contentVersion = '1.0.0.0'
            parameters     = $regularParameters
        }
        $parametersDoc `
        | ConvertTo-Json -Depth 10 `
        | Out-File -FilePath "deploy.$deploymentName.parameters.json" -Encoding UTF8 -Force
    }

    $outputs = New-AzResourceGroupDeployment @deployArgs `
        -Force `
        -Verbose `
        -DeploymentDebugLogLevel All `
        -ErrorAction Continue

    [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment] $armDeployment = $null
    foreach ($output in $outputs)
    {
        if ($output -is [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment])
        {
            $armDeployment = $output
        }
    }

    if ($armDeployment.ProvisioningState -ne 'Succeeded' -and $VerbosePreference -eq 'Continue')
    {
        $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
        $deploymentErrors | ConvertTo-Json -Depth 10 | Out-File -FilePath "deploy.$deploymentName.errors.json" -Encoding UTF8 -Force
    }
    else
    {
        if ($null -ne $armDeployment)
        {
            $armDeployment | ConvertTo-Json -Depth 10 | Out-File -FilePath "deploy.$deploymentName.outputs.json" -Encoding UTF8 -Force
        }
    }

    return $armDeployment
}

function Compress-Arguments
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('KeyVault', 'Main')]
        [string]
        $Template,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [SecureArguments]
        $SecureArguments
    )

    $cdphBusinessUnitParameter = Get-HashtableValue $ParametersEntry 'Cdph_BusinessUnit'
    $cdphBusinessUnit = Get-HashtableValue $cdphBusinessUnitParameter 'value'
    $cdphBusinessUnitProgramParameter = Get-HashtableValue $ParametersEntry 'Cdph_BusinessUnitProgram'
    $cdphBusinessUnitProgram = Get-HashtableValue $cdphBusinessUnitProgramParameter 'value'

    $virtualNetworkParameter = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftNetwork_virtualNetworks_Arguments'
    }
    $keyVaultParameter = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftKeyVault_vaults_Arguments'
    }

    $deploymentParameters = $null
    switch ($Template)
    {
        'KeyVault'
        {
            $keyVaultSecretsParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftKeyVault_vaults_SecureArguments'
            }
            
            $deploymentParameters = @{
                Cdph_BusinessUnit                                                               = $cdphBusinessUnit
                Cdph_BusinessUnitProgram                                                        = $cdphBusinessUnitProgram
                Cdph_Environment                                                                = $ResourceDeployment.Cdph_Environment

                MicrosoftNetwork_virtualNetworks_AddressSpace_AddressPrefixes                   = Get-Argument @virtualNetworkParameter -Name 'AddressSpace' -ByEnvironment
                MicrosoftNetwork_virtualNetworks_Arm_Location                                   = Get-Argument @virtualNetworkParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftNetwork_virtualNetworks_Arm_ResourceName                               = Get-Argument @virtualNetworkParameter -Name 'Arm_ResourceName'
                MicrosoftNetwork_virtualNetworks_DhcpOptions_DnsServers                         = Get-Argument @virtualNetworkParameter -Name 'DnsServers' -ByEnvironment

                MicrosoftKeyVault_vaults_Arm_ResourceName                                       = Get-Argument @keyVaultParameter -Name 'Arm_ResourceName'
                MicrosoftKeyVault_vaults_Arm_Location                                           = Get-Argument @keyVaultParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftKeyVault_vaults_Arm_AdministratorObjectId                              = Get-Argument @keyVaultParameter -Name 'Arm_AdministratorObjectId' -ByEnvironment
                MicrosoftKeyVault_vaults_NetworkAcls_IpRules                                    = Get-Argument @keyVaultParameter -Name 'NetworkAcls_IpRules' -ByEnvironment
                MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword = $SecureArguments.MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword
                MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword            = $SecureArguments.MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword
                MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword                              = $SecureArguments.MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
            }
        }
        'Main'
        {
            $storageAccountsParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftStorage_storageAccounts_Arguments'
            }
            $mySqlParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftDBforMySQL_flexibleServers_Arguments'
            }
            $appServicePlansParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftWeb_serverfarms_Arguments'
            }
            $appServiceParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftWeb_sites_Arguments'
            }
            $appServiceCertificatesParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftWeb_certificates_Arguments'
            }
            $applicationInsightsParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftInsights_components_Arguments'
            }
            $logAnalyticsParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'MicrosoftOperationalInsights_workspaces_Arguments'
            }
            $projectREDCapParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'ProjectREDCap_Arguments'
            }
            $smtpParameter = @{
                ParametersEntry    = $ParametersEntry
                ResourceDeployment = $ResourceDeployment
                ParameterName      = 'Smtp_Arguments'
            }
            $deploymentParameters = @{
                Cdph_BusinessUnit                                               = $cdphBusinessUnit
                Cdph_BusinessUnitProgram                                        = $cdphBusinessUnitProgram
                Cdph_Environment                                                = $ResourceDeployment.Cdph_Environment

                MicrosoftNetwork_virtualNetworks_AddressSpace_AddressPrefixes   = Get-Argument @virtualNetworkParameter -Name 'AddressSpace' -ByEnvironment
                MicrosoftNetwork_virtualNetworks_Arm_Location                   = Get-Argument @virtualNetworkParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftNetwork_virtualNetworks_Arm_ResourceName               = Get-Argument @virtualNetworkParameter -Name 'Arm_ResourceName'
                MicrosoftNetwork_virtualNetworks_DhcpOptions_DnsServers         = Get-Argument @virtualNetworkParameter -Name 'DnsServers' -ByEnvironment

                MicrosoftKeyVault_vaults_Arm_ResourceName                       = Get-Argument @keyVaultParameter -Name 'Arm_ResourceName'

                MicrosoftStorage_storageAccounts_Arm_Location                   = Get-Argument @storageAccountsParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftStorage_storageAccounts_Arm_ResourceName               = Get-Argument @storageAccountsParameter -Name 'Arm_ResourceName'
                MicrosoftStorage_storageAccounts_BlobServices_Containers_Name   = Get-Argument @storageAccountsParameter -Name 'ContainerName' -ByEnvironment
                MicrosoftStorage_storageAccounts_Sku_Name                       = Get-Argument @storageAccountsParameter -Name 'Redundancy' -ByEnvironment

                MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName      = Get-Argument @mySqlParameter -Name 'AdministratorLoginName' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword  = $SecureArguments.MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword
                MicrosoftDBforMySQL_flexibleServers_Arm_Location                = Get-Argument @mySqlParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName            = Get-Argument @mySqlParameter -Name 'Arm_ResourceName'
                MicrosoftDBforMySQL_flexibleServers_Backup_BackupRetentionDays  = Get-Argument @mySqlParameter -Name 'BackupRetentionDays' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name     = Get-Argument @mySqlParameter -Name 'DatabaseName' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_FirewallRules               = Get-Argument @mySqlParameter -Name 'FirewallRules' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_Sku_Name                    = Get-Argument @mySqlParameter -Name 'Sku' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_Sku_Tier                    = Get-Argument @mySqlParameter -Name 'Tier' -ByEnvironment
                MicrosoftDBforMySQL_flexibleServers_Storage_StorageSizeGB       = Get-Argument @mySqlParameter -Name 'StorageGB' -ByEnvironment

                MicrosoftWeb_serverfarms_Arm_Location                           = Get-Argument @appServicePlansParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftWeb_serverfarms_Arm_ResourceName                       = Get-Argument @appServicePlansParameter -Name 'Arm_ResourceName'
                MicrosoftWeb_serverfarms_Capacity                               = Get-Argument @appServicePlansParameter -Name 'Capacity' -ByEnvironment
                MicrosoftWeb_serverfarms_Sku                                    = Get-Argument @appServicePlansParameter -Name 'SkuName' -ByEnvironment
                MicrosoftWeb_serverfarms_Tier                                   = Get-Argument @appServicePlansParameter -Name 'Tier' -ByEnvironment

                MicrosoftWeb_sites_Arm_Location                                 = Get-Argument @appServiceParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftWeb_sites_Arm_ResourceName                             = Get-Argument @appServiceParameter -Name 'Arm_ResourceName'
                MicrosoftWeb_sites_CustomFullyQualifiedDomainName               = Get-Argument @appServiceParameter -Name 'CustomFullyQualifiedDomainName' -ByEnvironment
                MicrosoftWeb_sites_LinuxFxVersion                               = Get-Argument @appServiceParameter -Name 'LinuxFxVersion' -ByEnvironment
                MicrosoftWeb_sites_SourceControl_GitHubRepositoryUrl            = Get-Argument @appServiceParameter -Name 'SourceControl_GitHubRepositoryUrl' -ByEnvironment

                MicrosoftWeb_certificates_Arm_ResourceName                      = Get-Argument @appServiceCertificatesParameter -Name 'Arm_ResourceName'
                MicrosoftWeb_certificates_Arm_Location                          = Get-Argument @appServiceCertificatesParameter -Name 'Arm_Location' -ByEnvironment

                enableDeployment_ApplicationInsights                            = Get-Argument @applicationInsightsParameter -Name 'enabled' -ByEnvironment
                MicrosoftInsights_components_Arm_ResourceName                   = Get-Argument @applicationInsightsParameter -Name 'Arm_ResourceName'
                MicrosoftInsights_components_Arm_Location                       = Get-Argument @applicationInsightsParameter -Name 'Arm_Location' -ByEnvironment

                MicrosoftOperationalInsights_workspaces_Arm_Location            = Get-Argument @logAnalyticsParameter -Name 'Arm_Location' -ByEnvironment
                MicrosoftOperationalInsights_workspaces_Arm_ResourceName        = Get-Argument @logAnalyticsParameter -Name 'Arm_ResourceName'

                ProjectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion         = (Get-Argument @projectREDCapParameter -Name 'AutomaticDownloadUrlBuilder')['AppZipVersion']
                ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName     = (Get-Argument @projectREDCapParameter -Name 'AutomaticDownloadUrlBuilder')['CommunityUserName']
                ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserPassword = $SecureArguments.MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword

                Smtp_FromEmailAddress                                           = Get-Argument @smtpParameter -Name 'FromEmailAddress' -ByEnvironment
                Smtp_HostFqdn                                                   = Get-Argument @smtpParameter -Name 'HostFqdn' -ByEnvironment
                Smtp_Port                                                       = Get-Argument @smtpParameter -Name 'Port' -ByEnvironment
                Smtp_UserLogin                                                  = Get-Argument @smtpParameter -Name 'UserLogin' -ByEnvironment
                Smtp_UserPassword                                               = $SecureArguments.MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
            }
        }
        Default {}
    }
    return $deploymentParameters
}
function Initialize-VirtualNetworkArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftNetwork_virtualNetworks_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $virtualNetwork_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Network/virtualNetworks'

    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $virtualNetwork_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'DnsServers' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'AddressSpace' `
        -ByEnvironment
}

function Initialize-KeyVaultResourceNameArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftKeyVault_vaults_Arm_ResourceName'
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
        -Metadata
}

function Initialize-StorageAccountArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftStorage_storageAccounts_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $storageAccount_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Storage/storageAccounts'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $storageAccount_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'Redundancy' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'ContainerName' `
        -ByEnvironment
}

function Initialize-MySQLArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment,

        # Password for MySQL administrator account
        # Recommended: Use Get-Secret to retrieve the password from a secure store.
        [Parameter(Mandatory = $true)]
        [securestring]
        $MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftDBforMySQL_flexibleServers_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $mysql_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.DBforMySQL/flexibleServers'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $mysql_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'DatabaseName' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'AdministratorLoginName' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'Tier' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'Sku' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'StorageGB' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'BackupRetentionDays' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'FirewallRules' `
        -ByEnvironment
}

function Initialize-AppServicePlanArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftWeb_serverfarms_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $appServicePlan_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Web/serverfarms'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $appServicePlan_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'SkuName' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'Tier' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'Capacity' `
        -ByEnvironment
}

function Initialize-AppServiceCertificatesArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftWeb_certificates_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $appServiceCertificates_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Web/certificates'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $appServiceCertificates_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment
}

function Initialize-AppServiceArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftWeb_sites_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $appService_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Web/sites'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $appService_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'LinuxFxVersion' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'SourceControl_GitHubRepositoryUrl' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'CustomFullyQualifiedDomainName' `
        -ByEnvironment
}

function Initialize-AppInsightsArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftInsights_components_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $appInsights_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.Insights/components'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $appInsights_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'enabled' `
        -ByEnvironment
}

function Initialize-LogAnalyticsArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftOperationalInsights_workspaces_Arguments'
    }

    $null = Test-Argument @parameterArguments

    $logAnalytics_Arm_ResourceName = Get-CdphResourceName `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
        -Arm_ResourceProvider 'Microsoft.OperationalInsights/workspaces'
    Set-Argument @parameterArguments `
        -Name 'Arm_ResourceName' `
        -Value $logAnalytics_Arm_ResourceName

    Remove-Argument @parameterArguments `
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments `
        -Name 'Arm_Location' `
        -ByEnvironment
}

function Initialize-REDCapArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'ProjectREDCap_Arguments'
    }

    $null = Test-Argument @parameterArguments

    Remove-Argument @parameterArguments `
        -Metadata

    $null = Test-Argument @parameterArguments `
        -Name 'OverrideAutomaticDownloadUrlBuilder'

    $null = Test-Argument @parameterArguments `
        -Name 'AutomaticDownloadUrlBuilder'

    $automaticDownloadBuilderArgument = Get-Argument @parameterArguments `
        -Name 'AutomaticDownloadUrlBuilder'

    $metadata = Get-HashtableValue $automaticDownloadBuilderArgument '$metadata'
    if ($null -ne $metadata)
    {
        $automaticDownloadBuilderArgument.Remove('$metadata')
    }

    $communityUserName = Get-HashtableValue $automaticDownloadBuilderArgument 'CommunityUserName'
    if ([string]::IsNullOrWhiteSpace($communityUserName))
    {
        throw 'Deployment parameters do not contain a required value for the ''ProjectREDCap_Arguments.value.AutomaticDownloadUrlBuilder.CommunityUserName'' property'
    }

    $appZipVersion = Get-HashtableValue $automaticDownloadBuilderArgument 'AppZipVersion'
    if ([string]::IsNullOrWhiteSpace($appZipVersion))
    {
        throw 'Deployment parameters do not contain a required value for the ''ProjectREDCap_Arguments.value.AutomaticDownloadUrlBuilder.AppZipVersion'' property'
    }
}

function Initialize-SmtpArguments
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'Smtp_Arguments'
    }

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

    $null = Test-Argument @parameterArguments

    $null = Test-Argument @parameterArguments `
        -Name 'HostFqdn' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'Port' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'UserLogin' `
        -ByEnvironment

    $null = Test-Argument @parameterArguments `
        -Name 'FromEmailAddress' `
        -ByEnvironment
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

        [Parameter(Mandatory = $true)]
        [SecureArguments]
        $SecureArguments
    )

    # Initialize the plain text arguments

    $parameterArguments = @{
        ParametersEntry    = $ParametersEntry
        ResourceDeployment = $ResourceDeployment
        ParameterName      = 'MicrosoftKeyVault_vaults_Arguments'
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
        -Metadata

    Remove-Argument @parameterArguments `
        -ByEnvironmentMetadata

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
        -Name 'MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword' `
        -Value $SecureArguments.MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword

    Set-Argument @parameterArguments `
        -Name 'MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword' `
        -Value $SecureArguments.MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword

    Set-Argument @parameterArguments `
        -Name 'MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword' `
        -Value $SecureArguments.MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
}

function Set-KeyVaultAppServiceAccessPolicy
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ParametersEntry,

        [Parameter(Mandatory = $true)]
        [ResourceDeployment]
        $ResourceDeployment
    )

    Write-Information 'Setting access policy to allow App Service to read from Key Vault. It''s currently not supported to set an accessPolicy property for an applicationId without an objectId'
    $azureAppServiceApplicationId = 'abfa0a7c-a6b6-4736-8310-5855508787cd' # fixed value for Azure App Services (see https://learn.microsoft.com/azure/app-service/configure-ssl-certificate#authorize-app-service-to-read-from-the-vault)

    $keyVault_Arm_ResourceName = Get-Argument `
        -ParametersEntry $ParametersEntry `
        -ResourceDeployment $ResourceDeployment `
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
        [ResourceDeployment]
        $ResourceDeployment,

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

    $argumentEntry = Get-HashtableValue $ParametersEntry $ParameterName
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }

    $argumentValue = Get-HashtableValue $argumentEntry 'value'
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = $ResourceDeployment.Cdph_Environment

        $argumentValue_byEnvironment = Get-HashtableValue $argumentValue 'byEnvironment'
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = Get-HashtableValue $argumentValue_byEnvironment $cdphEnvironment
        if ($null -eq $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment[$cdphEnvironment] = @{}
            $argumentValue_byEnvironment_thisEnvironment = Get-HashtableValue $argumentValue_byEnvironment $cdphEnvironment
        }
        # Only replace the value if IfNotExists is false, or if IfNotExists is true and the value is null or whitespace
        if (-not $IfNotExists -or ($IfNotExists -and [string]::IsNullOrWhiteSpace((Get-HashtableValue $argumentValue_byEnvironment_thisEnvironment $Name))))
        {
            $argumentValue_byEnvironment_thisEnvironment[$Name] = $Value
        }

    }
    else
    {
        # Only replace the value if IfNotExists is false, or if IfNotExists is true and the value is null or whitespace
        if (-not $IfNotExists -or ($IfNotExists -and [string]::IsNullOrWhiteSpace((Get-HashtableValue $argumentValue $Name))))
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
        [ResourceDeployment]
        $ResourceDeployment,

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

    $argumentEntry = Get-HashtableValue $ParametersEntry $ParameterName
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }

    $argumentValue = Get-HashtableValue $argumentEntry 'value'
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = $ResourceDeployment.Cdph_Environment

        $argumentValue_byEnvironment = Get-HashtableValue $argumentValue 'byEnvironment'
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = Get-HashtableValue $argumentValue_byEnvironment $cdphEnvironment
        $foundValue = $false
        if ($null -ne $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment_thisEnvironment_value = Get-HashtableValue $argumentValue_byEnvironment_thisEnvironment $Name
            $foundValue = ($null -ne $argumentValue_byEnvironment_thisEnvironment_value)
            if ($foundValue)
            {
                return $argumentValue_byEnvironment_thisEnvironment_value
            }
        }

        if (-not $foundValue)
        {
            $argumentValue_byEnvironment_allEnvironments = Get-HashtableValue $argumentValue_byEnvironment 'ALL'
            if ($null -ne $argumentValue_byEnvironment_allEnvironments)
            {
                $argumentValue_byEnvironment_allEnvironments_value = Get-HashtableValue $argumentValue_byEnvironment_allEnvironments $Name
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
        $argumentValue_value = Get-HashtableValue $argumentValue $Name
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
        [ResourceDeployment]
        $ResourceDeployment,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter(Mandatory = $true, ParameterSetName = 'NamedArgument')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'NamedArgument')]
        [switch]
        $ByEnvironment,

        [Parameter(ParameterSetName = 'FixedArgument')]
        [switch]
        $Metadata,

        [Parameter(ParameterSetName = 'FixedArgument')]
        [switch]
        $ByEnvironmentMetadata
    )

    $argumentEntry = Get-HashtableValue $ParametersEntry $ParameterName
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }

    if ($Metadata)
    {
        $metadataEntry = Get-HashtableValue $argumentEntry 'metadata'
        if ($null -ne $metadataEntry)
        {
            $argumentEntry.Remove('metadata')
        }
    }

    $argumentValue = Get-HashtableValue $argumentEntry 'value'
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment -or $ByEnvironmentMetadata)
    {
        $cdphEnvironment = $ResourceDeployment.Cdph_Environment

        $argumentValue_byEnvironment = Get-HashtableValue $argumentValue 'byEnvironment'
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        if ($ByEnvironmentMetadata)
        {
            $argumentValue_byEnvironment_metadata = Get-HashtableValue $argumentValue_byEnvironment '$metadata'
            if ($null -ne $argumentValue_byEnvironment_metadata)
            {
                $argumentValue_byEnvironment.Remove('$metadata')
            }
        }
        else
        {
            $argumentValue_byEnvironment_thisEnvironment = Get-HashtableValue $argumentValue_byEnvironment $cdphEnvironment
            if ($null -ne $argumentValue_byEnvironment_thisEnvironment)
            {
                $argumentValue_byEnvironment_thisEnvironment.Remove($Name)
            }
            $argumentValue_byEnvironment_allEnvironments = Get-HashtableValue $argumentValue_byEnvironment 'ALL'
            if ($null -ne $argumentValue_byEnvironment_allEnvironments)
            {
                $argumentValue_byEnvironment_allEnvironments.Remove($Name)
            }
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
        [ResourceDeployment]
        $ResourceDeployment,

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

    $argumentEntry = Get-HashtableValue $ParametersEntry $ParameterName
    if ($null -eq $argumentEntry)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName' property"
    }
    if ([string]::IsNullOrWhiteSpace($Name))
    {
        return $true
    }

    $argumentValue = Get-HashtableValue $argumentEntry 'value'
    if ($null -eq $argumentValue)
    {
        throw "Deployment parameters do not contain a required value for the '$ParameterName.value' property"
    }

    if ($ByEnvironment)
    {
        $cdphEnvironment = $ResourceDeployment.Cdph_Environment

        $argumentValue_byEnvironment = Get-HashtableValue $argumentValue 'byEnvironment'
        if ($null -eq $argumentValue_byEnvironment)
        {
            throw "Deployment parameters do not contain a required value for the '$ParameterName.value.byEnvironment' property"
        }

        $argumentValue_byEnvironment_thisEnvironment = Get-HashtableValue $argumentValue_byEnvironment $cdphEnvironment
        $foundValue = $false
        if ($null -ne $argumentValue_byEnvironment_thisEnvironment)
        {
            $argumentValue_byEnvironment_thisEnvironment_value = Get-HashtableValue $argumentValue_byEnvironment_thisEnvironment $Name
            $foundValue = ($null -ne $argumentValue_byEnvironment_thisEnvironment_value)
        }

        if (-not $foundValue)
        {
            $argumentValue_byEnvironment_allEnvironments = Get-HashtableValue $argumentValue_byEnvironment 'ALL'
            if ($null -ne $argumentValue_byEnvironment_allEnvironments)
            {
                $argumentValue_byEnvironment_allEnvironments_value = Get-HashtableValue $argumentValue_byEnvironment_allEnvironments $Name
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
        $argumentValue_value = Get-HashtableValue $argumentValue $Name
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

        $cdphEnvironment = $ResourceDeployment.Cdph_Environment

        $resourceGroup_byEnvironment_thisEnvironment = Get-HashtableValue $resourceGroup_byEnvironment $cdphEnvironment
        $resourceGroup_byEnvironment_allEnvironments = $resourceGroup_byEnvironment.ALL

        $resourceGroup_Arm_Location = $null
        if ($null -ne $resourceGroup_byEnvironment_thisEnvironment)
        {
            $resourceGroup_Arm_Location = Get-HashtableValue $resourceGroup_byEnvironment_thisEnvironment 'Arm_Location'
        }
        if ($null -eq $resourceGroup_Arm_Location)
        {
            $resourceGroup_Arm_Location = Get-HashtableValue $resourceGroup_byEnvironment_allEnvironments 'Arm_Location'
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
    $cdph_Environment_actual = $ResourceDeployment.Cdph_Environment

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