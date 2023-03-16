// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

@description('CDPH Owner')
@allowed([
  'ITSD'
  'CDPH'
])
param Cdph_Organization string

@description('CDPH Business Unit (numbers & digits only)')
@maxLength(5)
@minLength(2)
param Cdph_BusinessUnit string

@description('CDPH Business Unit Program (numbers & digits only)')
@maxLength(7)
@minLength(2)
param Cdph_BusinessUnitProgram string

@description('Targeted deployment environment')
@maxLength(4)
@minLength(1)
@allowed([
  'Dev'
  'Test'
  'Prod'
])
param Cdph_Environment string = 'Dev'

@description('Instance number (when deploying multiple instances of this template into one environment)')
@minValue(1)
@maxValue(99)
param Cdph_ResourceInstance int = 1

@description('Thumbprint for SSL SNI server certificate. A custom domain name is a required part of this template.')
@minLength(40)
@maxLength(40)
param Cdph_SslCertificateThumbprint string

@description('Key Vault resource name (must be globally unique). Use the CdphNaming.psm1 PowerShell module to generate a unique name.')
@minLength(3)
@maxLength(24)
param Cdph_KeyVaultResourceName string

// General Azure Resource Manager parameters
// -----------------------------------------

/*
Get current list of all possible locations for your subscription:
  PowerShell: 
    $locations = Get-AzLocation -ExtendedLocation:$true
    $locations | ? RegionType -eq 'Physical' | ? PhysicalLocation | ft
  AZ CLI: 
    az account list-locations

Get current list of all possible SKUs for a specific resource type in a specific location:
  PowerShell:
    Storage Account
    App Service Plan
    Database for MySQL Flexible Server
      
Locations list for public cloud, non-US locations reference:
  'australiacentral'
  'australiacentral2'
  'australiaeast'
  'australiasoutheast'
  'brazilsouth'
  'brazilsoutheast'
  'canadacentral'
  'canadaeast'
  'centralindia'
  'eastasia'
  'francecentral'
  'francesouth'
  'germanynorth'
  'germanywestcentral'
  'japaneast'
  'japanwest'
  'jioindiacentral'
  'jioindiawest'
  'koreacentral'
  'koreasouth'
  'northeurope'
  'norwayeast'
  'norwaywest'
  'qatarcentral'
  'southafricanorth'
  'southafricawest'
  'southeastasia'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'switzerlandwest'
  'uaecentral'
  'uaenorth'
  'uksouth'
  'ukwest'
  'westeurope'
  'westindia'

*/

@description('Location where most resources (website, database) will be deployed')
@allowed([
  // values for US in public cloud
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
  'westus3'
])
param Arm_MainSiteResourceLocation string = 'eastus'

@description('Location where resources will be deployed, as a display name (e.g. "East US"). This must match the value of Arm_MainSiteResourceLocation. Use Get-AzLocation to get the display name.')
@allowed([
  // values for US in public cloud
  'Central US'
  'East US'
  'East US 2'
  'North Central US'
  'South Central US'
  'West Central US'
  'West US'
  'West US 2'
  'West US 3'
])
param Arm_MainSiteResourceLocationDisplayName string = 'East US'

@description('Location where storage resources will be deployed')
@allowed([
  // values for US in public cloud
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
  'westus3'
])
param Arm_StorageResourceLocation string = 'westus'

@description('Location where storage resources will be deployed, as a display name (e.g. "West US"). This must match the value of Arm_StorageResourceLocation. Use Get-AzLocation to get the display name.')
@allowed([
  // values for US in public cloud
  'Central US'
  'East US'
  'East US 2'
  'North Central US'
  'South Central US'
  'West Central US'
  'West US'
  'West US 2'
  'West US 3'
])
param Arm_StorageResourceLocationDisplayName string = 'West US'

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

// Azure App Service Plan parameters
// ---------------------------------

@description('App Service Plan\'s pricing tier and capacity. Note: this can be changed after deployment. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/. Default = S1')
@allowed([
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param AppServicePlan_SkuName string = 'S1'

@description('App Service Plan\'s instance count. How many running, distinct web servers will be deployed in the farm? This can be changed after deployment. Default = 1')
@minValue(1)
param AppServicePlan_Capacity int = 1

// Azure App Service parameters
// ----------------------------

@description('PHP Version. Default = php|8.2')
@allowed([
  'php|8.0'
  'php|8.1'
  'php|8.2'
])
// Web server with PHP 7.2.5 or higher (including support for PHP 8). 
param AppService_LinuxFxVersion string = 'php|8.2'

@description('Subdomain name for the application (no spaces, no dashes, no special characters). Default = \'\' (empty string); If empty, a subdomain like REDCap-{CdphBusinessUnit}-{CdphEnvironment}-{InstanceNumber} will be used. NOTE: This needs to be unique to the root domain cdph.ca.gov, so it must vary by business unit and environment. For example, if the business unit is \'ESS\' and the environment is \'DEV\', then the subdomain name you provide could be \'REDCap01-ess-dev\' or anything else, so long as it is globally unique under the root domain cdph.ca.gov.')
param AppService_WebHost_Subdomain string = ''
// See variable appService_WebHost_SubdomainFinal for the final value

// @description('Custom domain TXT DNS record verification value. Default = \'\' (empty string); If empty, a random value will be generated. This value will be used to verify ownership of the custom domain. See https://learn.microsoft.com/azure/app-service/app-service-web-tutorial-custom-domain for more information.')
// param AppService_WebHost_CustomDomainDnsTxtRecordVerificationValue string = ''
// // See variable appService_WebHost_CustomDomainDnsTxtRecordVerificationFinal for the final value

@description('Source control repository URL.')
param AppService_WebHost_SourceControl_GitHubRepositoryUri string

// Azure Database for MySQL parameters
// -----------------------------------

@description('Database for MySQL: Database name. Default = redcap. The suffix \'_db\' will be added to this name')
@minLength(1)
param DatabaseForMySql_DbName string = 'redcap'

@description('Database for MySQL: Server name. Default = \'\' (empty string); If empty, a name like REDCap-{Environment}-{Instance} will be used. NOTE: This needs to be unique to the Azure Cloud (world-wide) to which you are deploying.')
param DatabaseForMySql_ServerName string = ''

@description('Database for MySQL: Administrator login name. Default = redcap_app')
@minLength(1)
param DatabaseForMySql_AdministratorLoginName string = 'redcap_app'

@description('Database for MySQL: Administrator password')
@minLength(8)
@secure()
param DatabaseForMySql_AdministratorLoginPassword string

@description('Database for MySql Flexible Server: performance tier. Default = GeneralPurpose. Please review https://learn.microsoft.com/azure/mysql/flexible-server/concepts-service-tiers-storage, and also ensure your choices are available in the selected region.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'BusinessCritical'
])
param DatabaseForMySql_Tier string = 'GeneralPurpose'

@description('Database for MySql Flexible Server: SKU. Default = Standard_D4ads_v5 = vCores: 4, RAM GiB: 16, IOPS Max: 16, Max connections: 16. Please review https://learn.microsoft.com/azure/mysql/flexible-server/concepts-service-tiers-storage, and also ensure your choices are available in the selected region. General recommendation from REDCap is 10GB initially')
@allowed([
  // Burstable SKUs
  'Standard_B1s' // vCores: 1,  RAM GiB: 1,   IOPS Max: 320,   Max connections: 171
  'Standard_B1ms' // vCores: 1,  RAM GiB: 2,   IOPS Max: 640,   Max connections: 341
  'Standard_B2s' // vCores: 2,  RAM GiB: 4,   IOPS Max: 1280,  Max connections: 683
  'Standard_B2ms' // vCores: 2,  RAM GiB: 8,   IOPS Max: 1700,  Max connections: 1365
  'Standard_B4ms' // vCores: 4,  RAM GiB: 16,  IOPS Max: 2400,  Max connections: 2731
  'Standard_B8ms' // vCores: 8,  RAM GiB: 32,  IOPS Max: 3100,  Max connections: 5461
  'Standard_B12ms' // vCores: 12, RAM GiB: 48,  IOPS Max: 3800,  Max connections: 8193
  'Standard_B16ms' // vCores: 16, RAM GiB: 64,  IOPS Max: 4300,  Max connections: 10923
  'Standard_B20ms' // vCores: 20, RAM GiB: 80,  IOPS Max: 5000,  Max connections: 13653

  // GeneralPurpose SKUs
  'Standard_D2ads_v5' // vCores: 2,  RAM GiB: 8,   IOPS Max: 3200,  Max connections: 1365
  'Standard_D2ds_v4' // vCores: 2,  RAM GiB: 8,   IOPS Max: 3200,  Max connections: 1365
  'Standard_D4ads_v5' // vCores: 4,  RAM GiB: 16,  IOPS Max: 6400,  Max connections: 2731
  'Standard_D4ds_v4' // vCores: 4,  RAM GiB: 16,  IOPS Max: 6400,  Max connections: 2731
  'Standard_D8ads_v5' // vCores: 8,  RAM GiB: 32,  IOPS Max: 12800, Max connections: 5461
  'Standard_D8ds_v4' // vCores: 8,  RAM GiB: 32,  IOPS Max: 12800, Max connections: 5461
  'Standard_D16ads_v5' // vCores: 16, RAM GiB: 64,  IOPS Max: 20000, Max connections: 10923
  'Standard_D16ds_v4' // vCores: 16, RAM GiB: 64,  IOPS Max: 20000, Max connections: 10923
  'Standard_D32ads_v5' // vCores: 32, RAM GiB: 128, IOPS Max: 20000, Max connections: 21845
  'Standard_D32ds_v4' // vCores: 32, RAM GiB: 128, IOPS Max: 20000, Max connections: 21845
  'Standard_D48ads_v5' // vCores: 48, RAM GiB: 192, IOPS Max: 20000, Max connections: 32768
  'Standard_D48ds_v4' // vCores: 48, RAM GiB: 192, IOPS Max: 20000, Max connections: 32768
  'Standard_D64ads_v5' // vCores: 64, RAM GiB: 256, IOPS Max: 20000, Max connections: 43691
  'Standard_D64ds_v4' // vCores: 64, RAM GiB: 256, IOPS Max: 20000, Max connections: 43691

  // BusinessCritical SKUs
  'Standard_E2ds_v4' // vCores: 2,  RAM GiB: 16,  IOPS Max: 5000,  Max connections: 2731
  'Standard_E2ads_v5' // vCores: 2,  RAM GiB: 16,  IOPS Max: 5000,  Max connections: 2731
  'Standard_E4ds_v4' // vCores: 4,  RAM GiB: 32,  IOPS Max: 10000, Max connections: 5461
  'Standard_E4ads_v5' // vCores: 4,  RAM GiB: 32,  IOPS Max: 10000, Max connections: 5461
  'Standard_E8ds_v4' // vCores: 8,  RAM GiB: 64,  IOPS Max: 18000, Max connections: 10923
  'Standard_E8ads_v5' // vCores: 8,  RAM GiB: 64,  IOPS Max: 18000, Max connections: 10923
  'Standard_E16ds_v4' // vCores: 16, RAM GiB: 128, IOPS Max: 28000, Max connections: 21845
  'Standard_E16ads_v5' // vCores: 16, RAM GiB: 128, IOPS Max: 28000, Max connections: 21845
  'Standard_E32ds_v4' // vCores: 32, RAM GiB: 256, IOPS Max: 38000, Max connections: 43691
  'Standard_E32ads_v5' // vCores: 32, RAM GiB: 256, IOPS Max: 38000, Max connections: 43691
  'Standard_E48ds_v4' // vCores: 48, RAM GiB: 384, IOPS Max: 48000, Max connections: 65536
  'Standard_E48ads_v5' // vCores: 48, RAM GiB: 384, IOPS Max: 48000, Max connections: 65536
  'Standard_E64ds_v4' // vCores: 64, RAM GiB: 504, IOPS Max: 48000, Max connections: 86016
  'Standard_E64ads_v5' // vCores: 64, RAM GiB: 504, IOPS Max: 48000, Max connections: 86016
  'Standard_E80ids_v4' // vCores: 80, RAM GiB: 504, IOPS Max: 48000, Max connections: 86016
  'Standard_E2ds_v5' // vCores: 2,  RAM GiB: 16,  IOPS Max: 5000,  Max connections: 2731
  'Standard_E4ds_v5' // vCores: 4,  RAM GiB: 32,  IOPS Max: 10000, Max connections: 5461
  'Standard_E8ds_v5' // vCores: 8,  RAM GiB: 64,  IOPS Max: 18000, Max connections: 10923
  'Standard_E16ds_v5' // vCores: 16, RAM GiB: 128, IOPS Max: 28000, Max connections: 21845
  'Standard_E32ds_v5' // vCores: 32, RAM GiB: 256, IOPS Max: 38000, Max connections: 43691
  'Standard_E48ds_v5' // vCores: 48, RAM GiB: 384, IOPS Max: 48000, Max connections: 65536
  'Standard_E64ds_v5' // vCores: 64, RAM GiB: 512, IOPS Max: 48000, Max connections: 87383
  'Standard_E96ds_v5' // vCores: 96, RAM GiB: 672, IOPS Max: 48000, Max connections: 100000
])
param DatabaseForMySql_Sku string = 'Standard_D4ads_v5'

@description('Database for MySql Flexible Server: Storage in GB. Default = 20 (10 GB is recommended by REDCap; 20 GB is the default minimum in Azure)')
param DatabaseForMySql_StorageGB int = 20

@description('Database for MySQL Flexible Server: Backup Retention Days. Default = 7')
param DatabaseForMySql_BackupRetentionDays int = 7

// Azure Storage Account parameters
// --------------------------------

@description('Azure Storage Account redundancy. Default = Standard_LRS (this is the minimum level, with 3 copies in one region). See https://learn.microsoft.com/azure/storage/common/storage-redundancy.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
param StorageAccount_Redundancy string = 'Standard_LRS'

// REDCap community and download parameters
// ----------------------------------------

@description('REDCap Community site username for downloading the REDCap zip file')
param ProjectRedcap_CommunityUsername string

@description('REDCap Community site password for downloading the REDCap zip file')
@secure()
param ProjectRedcap_CommunityPassword string

@description('REDCap zip file URI')
param ProjectRedcap_DownloadAppZipUri string

@description('REDCap zip file version to be downloaded from the REDCap Community site. Default = latest')
param ProjectRedcap_DownloadAppZipVersion string = 'latest'

// SMTP configuration parameters
// -----------------------------

@description('Fully-qualified domain name of your SMTP relay endpoint')
param Smtp_FQDN string

@description('Port for your SMTP relay. Default = 587')
@minValue(0)
@maxValue(65535)
param Smtp_Port int = 587

@description('Login name for your SMTP relay')
param Smtp_UserLogin string

@description('Login password for your SMTP relay')
@secure()
param Smtp_UserPassword string

@description('Email address configured as the sending address in REDCap')
param Smtp_FromEmailAddress string

// Azure Monitor Application Insights parameters
// ---------------------------------------------
@description('Enable Azure Monitor Application Insights deployment. Default = true')
param Monitor_ApplicationInsights bool = true

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

var cdph_CommonTags = {
  'ACCOUNTABILITY-Business Unit': Cdph_BusinessUnit
  'ACCOUNTABILITY-Cherwell Change Control': '' // TODO: parameterize or remove?
  'ACCOUNTABILITY-Cost Center': '' // TODO: parameterize or remove?
  'ACCOUNTABILITY-Date Created': Arm_DeploymentCreationDateTime
  'ACCOUNTABILITY-Owner': Cdph_BusinessUnit
  'ACCOUNTABILITY-Program': Cdph_BusinessUnitProgram
  'SECURITY-Criticality': '' // TODO: parameterize or remove?
  'SECURITY-Facing': '' // TODO: parameterize or remove?
  ENVIRONMENT: Cdph_Environment
}

// ARM variables
// -------------

// Make instance number into a zero-prefixed string exactly 2 digits long
var arm_ResourceInstance_ZeroPadded = padLeft(Cdph_ResourceInstance, 2, '0')

// Key Vault variables
// -------------------

// var keyVault_CertKey_ResourceName = toLower('certkey-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}')

// Database for MySQL variables
// ----------------------------

// lowercase required: https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftdbformysql
var databaseForMySql_ResourceName = toLower('mysql-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}')

var databaseForMySql_HostNameFinal = !empty(DatabaseForMySql_ServerName) ? DatabaseForMySql_ServerName : 'REDCap-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

var databaseForMySql_HostName = '${databaseForMySql_HostNameFinal}.mysql.database.azure.com'

var databaseForMySql_AdministratorAccountName = '${DatabaseForMySql_AdministratorLoginName}@${DatabaseForMySql_ServerName}'

var databaseForMySql_PrimaryDbName = '${DatabaseForMySql_DbName}_db'

var databaseForMySql_FirewallRules = {
  AllowAllAzureServicesAndResourcesWithinAzureIps: {
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '0.0.0.0'
  }
}

// Azure Storage Account variables
// -------------------------------

var storageAccount_ResourceName = toLower('st${Cdph_Organization}${Cdph_BusinessUnit}${Cdph_BusinessUnitProgram}${Cdph_Environment}${arm_ResourceInstance_ZeroPadded}')

var storageAccount_ContainerName = 'redcap' // TODO: parameterize this if the name should or could be changed

// var storageAccount_Keys = concat(listKeys(storageAccount_ResourceName, '2015-05-01-preview').key1)
var storageAccount_Key = storageAccount_Resource.listKeys().keys[0].value

// App Service variables
// ---------------------

var appService_Plan_ResourceName = 'asp-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'
var appService_Certificate_ResourceName = 'cert-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'
var appService_WebHost_ResourceName = 'app-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

var appService_Tags = union(
  {
    displayName: 'REDCap Web App'
  },
  cdph_CommonTags
)

// var appService_WebHost_UniqueSubdomainFinal = !empty(AppService_WebHost_Subdomain) ? AppService_WebHost_Subdomain : 'REDCap'

var appService_WebHost_SubdomainFinal = !empty(AppService_WebHost_Subdomain) ? AppService_WebHost_Subdomain : 'REDCap-${Cdph_BusinessUnit}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'
// var appService_WebHost_UniqueDefaultFullDomain = '${appService_WebHost_UniqueDefaultSubdomain}.azurewebsites.net'
var appService_WebHost_UniqueDefaultFullDomain = '${appService_WebHost_ResourceName}.azurewebsites.net'
var appService_WebHost_UniqueDefaultKuduFullDomain = '${appService_WebHost_ResourceName}.scm.azurewebsites.net'
var appService_WebHost_FullCustomDomainName = '${appService_WebHost_SubdomainFinal}.cdph.ca.gov'

// var appService_WebHost_Certificate_Redcap_ResourceName = 'redcap'

// // This 26-character value will be the same if repeatedly deployed to the same subscription and resource group
// var appService_WebHost_CustomDomainDnsTxtRecordVerificationDefault = '${uniqueString(subscription().subscriptionId)}${uniqueString(resourceGroup().id)}'
// var appService_WebHost_CustomDomainDnsTxtRecordVerificationFinal = !empty(AppService_WebHost_CustomDomainDnsTxtRecordVerificationValue) ? AppService_WebHost_CustomDomainDnsTxtRecordVerificationValue : appService_WebHost_CustomDomainDnsTxtRecordVerificationDefault

// App Service App Configuration
// -----------------------------

var appService_Config_ConnectionString_Database = 'Database=${databaseForMySql_PrimaryDbName}'
var appService_Config_ConnectionString_DataSource = 'Data Source=${databaseForMySql_HostName}'
var appService_Config_ConnectionString_UserId = 'User Id=${databaseForMySql_AdministratorAccountName}'
var appService_Config_ConnectionString_Password = 'Password=${DatabaseForMySql_AdministratorLoginPassword}'
var appService_Config_ConnectionString_settings = [
  appService_Config_ConnectionString_Database
  appService_Config_ConnectionString_DataSource
  appService_Config_ConnectionString_UserId
  appService_Config_ConnectionString_Password
]
var appService_Config_ConnectionString = join(appService_Config_ConnectionString_settings, '; ')

// Application Insights variables
// ------------------------------

var appInsights_ResourceName = 'appi-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

// Log Analytics variables
// -----------------------

var logAnalytics_Workspace_ResourceName = 'log-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

// =========
// RESOURCES
// =========

// Azure Storage Account
// ---------------------

resource storageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccount_ResourceName
  location: Arm_StorageResourceLocation
  sku: {
    name: StorageAccount_Redundancy
  }
  kind: 'StorageV2'
  tags: cdph_CommonTags
  // properties: {
  //   dnsEndpointType: 'Standard'
  //   allowedCopyScope: 'AAD'
  //   defaultToOAuthAuthentication: true
  //   publicNetworkAccess: 'Enabled' // TODO: parameterize or remove?
  //   allowCrossTenantReplication: true // TODO: parameterize or remove or change?
  //   minimumTlsVersion: 'TLS1_2'
  //   allowBlobPublicAccess: false
  //   allowSharedKeyAccess: true
  //   largeFileSharesState: 'Enabled'
  //   networkAcls: {
  //     bypass: 'AzureServices'
  //     virtualNetworkRules: [] // TODO: might want to lock this down?
  //     ipRules: []
  //     defaultAction: 'Deny'
  //   }
  //   supportsHttpsTrafficOnly: true
  //   encryption: {
  //     requireInfrastructureEncryption: false
  //     services: {
  //       file: {
  //         keyType: 'Account'
  //         enabled: true
  //       }
  //       blob: {
  //         keyType: 'Account'
  //         enabled: true
  //       }
  //     }
  //     keySource: 'Microsoft.Storage' // TODO: Use Key Vault instead?
  //   }
  //   accessTier: 'Hot'
  // }

  resource storageAccount_Blob_Resource 'blobServices' = {
    name: 'default'
    // properties: {
    //   changeFeed: {
    //     enabled: false
    //   }
    //   restorePolicy: {
    //     enabled: false
    //   }
    //   containerDeleteRetentionPolicy: {
    //     enabled: true
    //     days: 7
    //   }
    //   cors: {
    //     corsRules: []
    //   }
    //   deleteRetentionPolicy: {
    //     allowPermanentDelete: false
    //     enabled: true
    //     days: 7
    //   }
    //   isVersioningEnabled: false
    // }

    resource storageAccount_Blob_Container_Resource 'containers' = {
      name: storageAccount_ContainerName // fixed container name
      // properties: {
      //   immutableStorageWithVersioning: {
      //     enabled: false
      //   }
      //   defaultEncryptionScope: '$account-encryption-key'
      //   denyEncryptionScopeOverride: false
      //   publicAccess: 'None'
      // }
      // dependsOn: [

      //   storageAccountResource
      // ]
    }
  }
}

// Database for MySQL Flexible Server
// ----------------------------------

resource databaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: databaseForMySql_ResourceName
  location: Arm_MainSiteResourceLocation
  tags: cdph_CommonTags
  sku: {
    name: DatabaseForMySql_Sku
    tier: DatabaseForMySql_Tier
  }
  properties: {
    administratorLogin: DatabaseForMySql_AdministratorLoginName
    administratorLoginPassword: DatabaseForMySql_AdministratorLoginPassword
    backup: {
      backupRetentionDays: DatabaseForMySql_BackupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    replicationRole: 'None'
    storage: {
      storageSizeGB: DatabaseForMySql_StorageGB
    }
    version: '8.0.21'
  }

  resource databaseForMySql_FlexibleServer_FirewallRule_Resource 'firewallRules' = [for (firewallRule, index) in items(databaseForMySql_FirewallRules): {
    name: firewallRule.key
    properties: {
      startIpAddress: firewallRule.value.StartIpAddress
      endIpAddress: firewallRule.value.EndIpAddress
    }
  }]

  resource databaseForMySql_FlexibleServer_RedCapDb_Resource 'databases' = {
    name: databaseForMySql_PrimaryDbName
    properties: {
      charset: 'utf8'
      collation: 'utf8_general_ci'
    }
  }

}

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: Cdph_KeyVaultResourceName
}

// Azure App Services
// ------------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appService_Plan_ResourceName
  location: Arm_MainSiteResourceLocation
  tags: cdph_CommonTags
  sku: {
    name: AppServicePlan_SkuName
    capacity: AppServicePlan_Capacity
  }
  kind: 'app,linux' // see https://stackoverflow.com/a/62400396/100596 for acceptable values
  properties: {
    reserved: true
  }
}

resource appService_WebHost_Resource 'Microsoft.Web/sites@2022-03-01' = {
  name: appService_WebHost_ResourceName
  location: Arm_MainSiteResourceLocation
  tags: appService_Tags
  dependsOn: [
    storageAccount_Resource
    databaseForMySql_FlexibleServer_Resource
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientAffinityEnabled: false
    httpsOnly: true
    serverFarmId: appService_Plan_Resource.id
    siteConfig: {
      alwaysOn: true
      linuxFxVersion: AppService_LinuxFxVersion
    }
  }

  resource appService_WebHost_HostNameBindings 'hostNameBindings' = {
    name: appService_WebHost_FullCustomDomainName
    properties: {
      sslState: 'SniEnabled'
      thumbprint: appService_Certificate_Resource.properties.thumbprint
    }
  }

   resource appService_WebHost_Config_Resource 'config' = {
    name: 'web'
    properties: {
      alwaysOn: true
      appCommandLine: '/home/startup.sh'
      connectionStrings: [
        {
          name: 'defaultConnection'
          connectionString: appService_Config_ConnectionString
          type: 'MySql'
        }
      ]
      defaultDocuments: [
        'index.html'
        'default.html'
        'index.php'
        'hostingstart.html'
      ]
      ftpsState: 'Disabled'
      loadBalancing: 'LeastRequests'
      numberOfWorkers: 1
      scmType: 'None'
    }
  }

  resource appService_WebHost_Config_AppSettings_Resource 'config' = {
    name: 'appsettings'
    properties: {
      // SCM (Kudu)
      SCM_DO_BUILD_DURING_DEPLOYMENT: '1'

      // Application Insights
      APPINSIGHTS_INSTRUMENTATIONKEY: Monitor_ApplicationInsights ? appInsights_Resource.properties.InstrumentationKey : ''
      APPINSIGHTS_PROFILERFEATURE_VERSION: Monitor_ApplicationInsights ? '1.0.0' : ''
      APPINSIGHTS_SNAPSHOTFEATURE_VERSION: Monitor_ApplicationInsights ? '1.0.0' : ''
      APPLICATIONINSIGHTS_CONNECTION_STRING: Monitor_ApplicationInsights ? appInsights_Resource.properties.ConnectionString : ''
      ApplicationInsightsAgent_EXTENSION_VERSION: Monitor_ApplicationInsights ? '~2' : ''
      DiagnosticServices_EXTENSION_VERSION: Monitor_ApplicationInsights ? '~3' : ''
      InstrumentationEngine_EXTENSION_VERSION: Monitor_ApplicationInsights ? 'disabled' : ''
      SnapshotDebugger_EXTENSION_VERSION: Monitor_ApplicationInsights ? 'disabled' : ''
      XDT_MicrosoftApplicationInsights_BaseExtensions: Monitor_ApplicationInsights ? 'disabled' : ''
      XDT_MicrosoftApplicationInsights_Mode: Monitor_ApplicationInsights ? 'recommended' : ''
      XDT_MicrosoftApplicationInsights_PreemptSdk: Monitor_ApplicationInsights ? 'disabled' : ''
    
      // PHP
      PHP_INI_SCAN_DIR: '/usr/local/etc/php/conf.d:/home/site'

      // REDCap
      redcapAppZip: ProjectRedcap_DownloadAppZipUri
      redcapCommunityUsername: ProjectRedcap_CommunityUsername
      redcapCommunityPassword: ProjectRedcap_CommunityPassword
      redcapAppZipVersion: ProjectRedcap_DownloadAppZipVersion

      // Azure Storage
      StorageContainerName: storageAccount_ContainerName
      StorageAccount: storageAccount_ResourceName
      StorageKey: storageAccount_Key

      // MySQL
      DBHostName: databaseForMySql_HostName
      DBName: DatabaseForMySql_DbName
      DBUserName: databaseForMySql_AdministratorAccountName
      DBPassword: DatabaseForMySql_AdministratorLoginPassword

      // SMTP
      from_email_address: Smtp_FromEmailAddress
      smtp_fqdn_name: Smtp_FQDN
      smtp_port: '${Smtp_Port}'
      smtp_user_name: Smtp_UserLogin
      smtp_password: Smtp_UserPassword
    }
  }

  // resource appService_WebHost_Certificates_Resource 'publicCertificates' = {
  //   name: appService_WebHost_Certificate_Redcap_ResourceName
  //   properties: {
  //     publicCertificateLocation: 'KeyVault'
  //     keyVaultId: keyVault_Resource.id
  //     keyVaultSecretName: appService_WebHost_ResourceName
  //   }
  // }

 resource appService_WebHost_SourceControl_Resource 'sourcecontrols' = {
    name: 'web'
    properties: {
      branch: 'main'
      isManualIntegration: true
      repoUrl: AppService_WebHost_SourceControl_GitHubRepositoryUri
    }
  }

}

resource appService_Certificate_Resource 'Microsoft.Web/certificates@2022-03-01' = {
  name: appService_Certificate_ResourceName
  location: Arm_MainSiteResourceLocation
  tags: cdph_CommonTags
  properties: {
    hostNames: [
      appService_WebHost_FullCustomDomainName
    ]
    keyVaultId: keyVault_Resource.id
    keyVaultSecretName: appService_WebHost_Resource.name
    serverFarmId: appService_Plan_Resource.id
  }
}

/*
resource appService_WebHost_BasicPublishingCredentialsPolicies_Scm_Resource 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  name: 'scm'
  parent: appService_WebHost_Resource
  location: Arm_MainSiteResourceLocationDisplayName
  properties: {
    allow: true
  }
}

resource appService_WebHost_BasicPublishingCredentialsPolicies_Ftp_Resource 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  name: 'ftp'
  parent: appService_WebHost_Resource
  location: Arm_MainSiteResourceLocationDisplayName
  properties: {
    allow: false
  }
}
*/

resource appInsights_Resource 'Microsoft.Insights/components@2020-02-02' = if (Monitor_ApplicationInsights) {
  name: appInsights_ResourceName
  location: Arm_MainSiteResourceLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics_Workspace_Resource.id
  }
}

resource logAnalytics_Workspace_Resource 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (Monitor_ApplicationInsights) {
  name: logAnalytics_Workspace_ResourceName
  location: Arm_MainSiteResourceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// NOTE: Bicep/ARM will lowercase the initial letter for all output
output out_AzAppService_CustomDomainVerification string = appService_WebHost_Resource.properties.customDomainVerificationId
//output out_AzAppService_CustomDomainVerification string = 'disabled'

// Keep these output variables named the same as original until dependencies are identified and refactored
output out_MySQLHostName string = databaseForMySql_HostName
output out_MySqlUserName string = databaseForMySql_AdministratorAccountName
output out_WebSiteFQDN string = appService_WebHost_UniqueDefaultFullDomain
output out_StorageAccountKey string = storageAccount_Key
output out_StorageAccountName string = storageAccount_ResourceName
output out_StorageContainerName string = storageAccount_ContainerName
output out_WebHost_IpAddress string = appService_WebHost_Resource.properties.inboundIpAddress // Ignore this warning: "The property 'inboundIpAddress' does not exist on type 'SiteConfigResource'. Make sure to only use property names that are defined by the type."
