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
param Cdph_Organization string = 'ITSD'

@description('CDPH Business Unit (numbers & digits only)')
@maxLength(5)
@minLength(2)
param Cdph_BusinessUnit string = 'ESS'

@description('CDPH Business Unit Program (numbers & digits only)')
@maxLength(7)
@minLength(2)
param Cdph_BusinessUnitProgram string = 'RedCap'

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

// General Azure Resource Manager parameters
// -----------------------------------------

/*
Get current list of all possible locations for your subscription:
  PowerShell: 
    Get-AzLocation
  AZ CLI: 
    az account list-locations

Get current list of all possible SKUs for a specific resource type in a specific location:
  PowerShell:
    Storage Account
      Get-AzS
    App Service Plan
      
    Database for MySQL Flexible Server
      

*/

@description('Location where resources will be deployed')
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

  // values for non-US in public cloud
  // 'australiacentral'
  // 'australiacentral2'
  // 'australiaeast'
  // 'australiasoutheast'
  // 'brazilsouth'
  // 'brazilsoutheast'
  // 'canadacentral'
  // 'canadaeast'
  // 'centralindia'
  // 'eastasia'
  // 'francecentral'
  // 'francesouth'
  // 'germanynorth'
  // 'germanywestcentral'
  // 'japaneast'
  // 'japanwest'
  // 'jioindiacentral'
  // 'jioindiawest'
  // 'koreacentral'
  // 'koreasouth'
  // 'northeurope'
  // 'norwayeast'
  // 'norwaywest'
  // 'qatarcentral'
  // 'southafricanorth'
  // 'southafricawest'
  // 'southeastasia'
  // 'southindia'
  // 'swedencentral'
  // 'switzerlandnorth'
  // 'switzerlandwest'
  // 'uaecentral'
  // 'uaenorth'
  // 'uksouth'
  // 'ukwest'
  // 'westeurope'
  // 'westindia'
])
param Arm_ResourceLocation string = 'westus2'

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

// Azure App Service Plan parameters
// ---------------------------------
 
@description('PHP Version. Default = php|8.2')
@allowed([
  'php|8.0'
  'php|8.1'
  'php|8.2'
])
// Web server with PHP 7.2.5 or higher (including support for PHP 8). 
param AppService_LinuxFxVersion string = 'php|8.2'

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

@description('Subdomain name for the application (no spaces, no dashes, no special characters). Default = \'\' (empty string); If empty, a subdomain like REDCap-{CdphEnvironment}-{InstanceNumber} will be used. NOTE: This needs to be unique to the root domain cdph.ca.gov.')
param AppService_WebAppSubdomain string = ''
// See variable appService_WebApp_SubdomainFinal for the final value

@description('Custom domain TXT DNS record verification value. Default = \'\' (empty string); If empty, a random value will be generated. This value will be used to verify ownership of the custom domain. See https://learn.microsoft.com/azure/app-service/app-service-web-tutorial-custom-domain for more information.')
param AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue string = ''
// See variable appService_WebApp_CustomDomainDnsTxtRecordVerificationFinal for the final value

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
  'Standard_B1s'       // vCores: 1,  RAM GiB: 1,   IOPS Max: 320,   Max connections: 171
  'Standard_B1ms'      // vCores: 1,  RAM GiB: 2,   IOPS Max: 640,   Max connections: 341
  'Standard_B2s'       // vCores: 2,  RAM GiB: 4,   IOPS Max: 1280,  Max connections: 683
  'Standard_B2ms'      // vCores: 2,  RAM GiB: 8,   IOPS Max: 1700,  Max connections: 1365
  'Standard_B4ms'      // vCores: 4,  RAM GiB: 16,  IOPS Max: 2400,  Max connections: 2731
  'Standard_B8ms'      // vCores: 8,  RAM GiB: 32,  IOPS Max: 3100,  Max connections: 5461
  'Standard_B12ms'     // vCores: 12, RAM GiB: 48,  IOPS Max: 3800,  Max connections: 8193
  'Standard_B16ms'     // vCores: 16, RAM GiB: 64,  IOPS Max: 4300,  Max connections: 10923
  'Standard_B20ms'     // vCores: 20, RAM GiB: 80,  IOPS Max: 5000,  Max connections: 13653
  
  // GeneralPurpose SKUs
  'Standard_D2ads_v5'  // vCores: 2,  RAM GiB: 8,   IOPS Max: 3200,  Max connections: 1365
  'Standard_D2ds_v4'   // vCores: 2,  RAM GiB: 8,   IOPS Max: 3200,  Max connections: 1365
  'Standard_D4ads_v5'  // vCores: 4,  RAM GiB: 16,  IOPS Max: 6400,  Max connections: 2731
  'Standard_D4ds_v4'   // vCores: 4,  RAM GiB: 16,  IOPS Max: 6400,  Max connections: 2731
  'Standard_D8ads_v5'  // vCores: 8,  RAM GiB: 32,  IOPS Max: 12800, Max connections: 5461
  'Standard_D8ds_v4'   // vCores: 8,  RAM GiB: 32,  IOPS Max: 12800, Max connections: 5461
  'Standard_D16ads_v5' // vCores: 16, RAM GiB: 64,  IOPS Max: 20000, Max connections: 10923
  'Standard_D16ds_v4'  // vCores: 16, RAM GiB: 64,  IOPS Max: 20000, Max connections: 10923
  'Standard_D32ads_v5' // vCores: 32, RAM GiB: 128, IOPS Max: 20000, Max connections: 21845
  'Standard_D32ds_v4'  // vCores: 32, RAM GiB: 128, IOPS Max: 20000, Max connections: 21845
  'Standard_D48ads_v5' // vCores: 48, RAM GiB: 192, IOPS Max: 20000, Max connections: 32768
  'Standard_D48ds_v4'  // vCores: 48, RAM GiB: 192, IOPS Max: 20000, Max connections: 32768
  'Standard_D64ads_v5' // vCores: 64, RAM GiB: 256, IOPS Max: 20000, Max connections: 43691
  'Standard_D64ds_v4'  // vCores: 64, RAM GiB: 256, IOPS Max: 20000, Max connections: 43691
  
  // BusinessCritical SKUs
  'Standard_E2ds_v4'   // vCores: 2,  RAM GiB: 16,  IOPS Max: 5000,  Max connections: 2731
  'Standard_E2ads_v5'  // vCores: 2,  RAM GiB: 16,  IOPS Max: 5000,  Max connections: 2731
  'Standard_E4ds_v4'   // vCores: 4,  RAM GiB: 32,  IOPS Max: 10000, Max connections: 5461
  'Standard_E4ads_v5'  // vCores: 4,  RAM GiB: 32,  IOPS Max: 10000, Max connections: 5461
  'Standard_E8ds_v4'   // vCores: 8,  RAM GiB: 64,  IOPS Max: 18000, Max connections: 10923
  'Standard_E8ads_v5'  // vCores: 8,  RAM GiB: 64,  IOPS Max: 18000, Max connections: 10923
  'Standard_E16ds_v4'  // vCores: 16, RAM GiB: 128, IOPS Max: 28000, Max connections: 21845
  'Standard_E16ads_v5' // vCores: 16, RAM GiB: 128, IOPS Max: 28000, Max connections: 21845
  'Standard_E32ds_v4'  // vCores: 32, RAM GiB: 256, IOPS Max: 38000, Max connections: 43691
  'Standard_E32ads_v5' // vCores: 32, RAM GiB: 256, IOPS Max: 38000, Max connections: 43691
  'Standard_E48ds_v4'  // vCores: 48, RAM GiB: 384, IOPS Max: 48000, Max connections: 65536
  'Standard_E48ads_v5' // vCores: 48, RAM GiB: 384, IOPS Max: 48000, Max connections: 65536
  'Standard_E64ds_v4'  // vCores: 64, RAM GiB: 504, IOPS Max: 48000, Max connections: 86016
  'Standard_E64ads_v5' // vCores: 64, RAM GiB: 504, IOPS Max: 48000, Max connections: 86016
  'Standard_E80ids_v4' // vCores: 80, RAM GiB: 504, IOPS Max: 48000, Max connections: 86016
  'Standard_E2ds_v5'   // vCores: 2,  RAM GiB: 16,  IOPS Max: 5000,  Max connections: 2731
  'Standard_E4ds_v5'   // vCores: 4,  RAM GiB: 32,  IOPS Max: 10000, Max connections: 5461
  'Standard_E8ds_v5'   // vCores: 8,  RAM GiB: 64,  IOPS Max: 18000, Max connections: 10923
  'Standard_E16ds_v5'  // vCores: 16, RAM GiB: 128, IOPS Max: 28000, Max connections: 21845
  'Standard_E32ds_v5'  // vCores: 32, RAM GiB: 256, IOPS Max: 38000, Max connections: 43691
  'Standard_E48ds_v5'  // vCores: 48, RAM GiB: 384, IOPS Max: 48000, Max connections: 65536
  'Standard_E64ds_v5'  // vCores: 64, RAM GiB: 512, IOPS Max: 48000, Max connections: 87383
  'Standard_E96ds_v5'  // vCores: 96, RAM GiB: 672, IOPS Max: 48000, Max connections: 100000
])
param DatabaseForMySql_Sku string = 'Standard_D4ads_v5'

@description('Database for MySql Flexible Server: Storage in GB. Default = 10 (recommended by REDCap)')
param DatabaseForMySql_StorageGB int = 10

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

@description('REDCap zip file URI')
param ProjectRedcap_DownloadAppZipUri string

@description('REDCap Community site username for downloading the REDCap zip file')
param ProjectRedcap_CommunityUsername string

@description('REDCap Community site password for downloading the REDCap zip file')
@secure()
param ProjectRedcap_CommunityPassword string

@description('REDCap zip file version to be downloaded from the REDCap Community site. Default = latest')
param ProjectRedcap_DownloadAppZipVersion string = 'latest'

// SMTP configuration parameters
// -----------------------------

@description('Email address configured as the sending address in REDCap')
param Smtp_FromEmailAddress string

@description('Fully-qualified domain name of your SMTP relay endpoint')
param Smtp_FQDN string

@description('Login name for your SMTP relay')
param Smtp_UserLogin string

@description('Login password for your SMTP relay')
@secure()
param Smtp_UserPassword string

@description('Port for your SMTP relay. Default = 587')
@minValue(0)
@maxValue(65535)
param Smtp_Port int = 587

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

// Database for MySQL variables
// ----------------------------

var databaseForMySql_ResourceName = 'mysql-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

// lowercase required: https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftdbformysql
var databaseForMySql_HostNameFinal = toLower(empty(DatabaseForMySql_ServerName) ? 'REDCap-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}' : DatabaseForMySql_ServerName) 

var databaseForMySql_HostName = '${databaseForMySql_HostNameFinal}.mysql.database.azure.com'

var databaseForMySql_AdministratorAccountName = '${DatabaseForMySql_AdministratorLoginName}@${DatabaseForMySql_ServerName}'

var databaseForMySql_PrimaryDbName = '${DatabaseForMySql_DbName}_db'

// Azure Storage Account variables
// -------------------------------

var storageAccount_ResourceName = 'st${toLower(Cdph_Organization)}${toLower(Cdph_BusinessUnit)}${toLower(Cdph_BusinessUnitProgram)}${toLower(Cdph_Environment)}${arm_ResourceInstance_ZeroPadded}'

var storageAccount_ContainerName = 'redcap' // TODO: parameterize this if the name should or could be changed

// var storageAccount_Keys = concat(listKeys(storageAccount_ResourceName, '2015-05-01-preview').key1)
var storageAccount_Key = storageAccount_Resource.listKeys().keys[0].value

// App Service variables
// ---------------------

var appService_Plan_ResourceName = 'asp-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'
var appService_WebSite_ResourceName = 'app-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

var appService_Tags = union(
  {
    displayName: 'REDCap Web App'
  },
  cdph_CommonTags
)

var appService_WebApp_UniqueSubdomainFinal = empty(AppService_WebAppSubdomain) ? 'REDCap' : AppService_WebAppSubdomain

var appService_WebApp_UniqueDefaultSubdomain = '${appService_WebApp_UniqueSubdomainFinal}-${uniqueString(resourceGroup().id)}'
var appService_WebApp_UniqueDefaultFullDomain = '${appService_WebApp_UniqueDefaultSubdomain}.azurewebsites.net'
var appService_WebApp_UniqueDefaultKuduFullDomain = '${appService_WebApp_UniqueDefaultSubdomain}.scm.azurewebsites.net'

var appService_WebApp_SubdomainFinal = empty(AppService_WebAppSubdomain) ? 'REDCap-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}' : AppService_WebAppSubdomain
var appService_WebApp_FullDomainName = '${appService_WebApp_SubdomainFinal}.cdph.ca.gov'

// This 26-character value will be the same if repeatedly deployed to the same subscription and resource group
var appService_WebApp_CustomDomainDnsTxtRecordVerificationDefault = '${uniqueString(subscription().subscriptionId)}${uniqueString(resourceGroup().id)}'
var appService_WebApp_CustomDomainDnsTxtRecordVerificationFinal = empty(AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue) ? appService_WebApp_CustomDomainDnsTxtRecordVerificationDefault : AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue

// App Service App Configuration
// -----------------------------

var appService_Config_ConnectionString_Database = 'Database=${DatabaseForMySql_DbName}'
var appService_Config_ConnectionString_DataSource = 'Data Source=${DatabaseForMySql_ServerName}.mysql.database.azure.com'
var appService_Config_ConnectionString_UserId = 'User Id=${databaseForMySql_AdministratorAccountName}'
var appService_Config_ConnectionString_Password = 'Password=${DatabaseForMySql_AdministratorLoginPassword}'
var appService_Config_ConnectionString_settings = [
  appService_Config_ConnectionString_Database
  appService_Config_ConnectionString_DataSource
  appService_Config_ConnectionString_UserId
  appService_Config_ConnectionString_Password 
]
var appService_Config_ConnectionString = join(appService_Config_ConnectionString_settings, '; ')

// =========
// RESOURCES
// =========

// Azure Storage Account
// ---------------------

resource storageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccount_ResourceName
  location: Arm_ResourceLocation
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
}

resource storageAccount_Blob_Resource 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: storageAccount_Resource
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
}

resource storageAccount_Blob_Container_Resource 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: storageAccount_Blob_Resource
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

// Database for MySQL Flexible Server
// ----------------------------------

resource databaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: databaseForMySql_ResourceName
  location: Arm_ResourceLocation
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
    highAvailability: {
      mode: 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Disabled'
      // dayOfWeek: 0
      // startHour: 0
      // startMinute: 0
    }
    // network: {
    //   delegatedSubnetResourceId: 'string'
    //   privateDnsZoneResourceId: 'string'
    // }
    replicationRole: 'None'
    storage: {
      storageSizeGB: DatabaseForMySql_StorageGB
      autoGrow: 'Enabled'
    }
    version: '8.0.21'
  }
}

resource databaseForMySql_FlexibleServer_FirewallRule_AllowAllAzure_Resource 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  parent: databaseForMySql_FlexibleServer_Resource
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource databaseForMySql_FlexibleServer_RedCapDb_Resource 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: databaseForMySql_FlexibleServer_Resource
  name: databaseForMySql_PrimaryDbName
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}


// TODO: Not sure if we'll need these

/* 
resource flexibleServers_flexdb_itsd_ess_dev_01_name_information_schema 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: databaseForMySql_FlexibleServer_Resource
  name: 'information_schema'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_mysql 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: databaseForMySql_FlexibleServer_Resource
  name: 'mysql'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_0900_ai_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_performance_schema 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: databaseForMySql_FlexibleServer_Resource
  name: 'performance_schema'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_0900_ai_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_sys 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: databaseForMySql_FlexibleServer_Resource
  name: 'sys'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_0900_ai_ci'
  }
}
*/

// Azure App Services
// ------------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appService_Plan_ResourceName
  location: Arm_ResourceLocation
  tags: cdph_CommonTags
  sku: {
    name: AppServicePlan_SkuName
    capacity: AppServicePlan_Capacity
  }
  kind: 'app,linux' // see https://stackoverflow.com/a/62400396/100596 for acceptable values
  properties: {
    // name: appServicePlanResourceName
    // perSiteScaling: false
    // elasticScaleEnabled: false
    // maximumElasticWorkerCount: 1
    // isSpot: false
    reserved: true
    // isXenon: false
    // hyperV: false
    // targetWorkerCount: 0
    // targetWorkerSizeId: 0
    // zoneRedundant: false
  }
}

resource appService_WebSite_Resource 'Microsoft.Web/sites@2022-03-01' = {
  name: appService_WebSite_ResourceName
  location: Arm_ResourceLocation
  tags: appService_Tags
  dependsOn: [
    storageAccount_Resource
    databaseForMySql_FlexibleServer_Resource
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // TODO: If this can be set to false, it can improve site availability
    // clientAffinityEnabled: true

    // clientCertEnabled: false
    // clientCertMode: 'Required'
    // containerSize: 0
    customDomainVerificationId: appService_WebApp_CustomDomainDnsTxtRecordVerificationDefault
    // dailyMemoryTimeQuota: 0
    hostNamesDisabled: false
    hostNameSslStates: [
      {
        name: appService_WebApp_FullDomainName
        sslState: 'SniEnabled'
        thumbprint: Cdph_SslCertificateThumbprint
        hostType: 'Standard'
      }
      {
        name: appService_WebApp_UniqueDefaultFullDomain
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: appService_WebApp_UniqueDefaultKuduFullDomain
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    httpsOnly: true
    // hyperV: false
    // isXenon: false
    keyVaultReferenceIdentity: 'SystemAssigned'
    // redundancyMode: 'None'
    // reserved: false
    // scmSiteAlsoStopped: false
    serverFarmId: appService_Plan_Resource.id
    siteConfig: {
      // SEE: webSiteAppServiceConfigResource for additional config
      alwaysOn: true
      linuxFxVersion: AppService_LinuxFxVersion
    }
    // storageAccountRequired: false
    // vnetContentShareEnabled: false
    // vnetImagePullEnabled: false
    // vnetRouteAllEnabled: false
  }
}

resource appService_WebSite_Config_Resource 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appService_WebSite_Resource
  name: 'web'
  properties: {
    // acrUseManagedIdentityCreds: false
    alwaysOn: true
    appCommandLine: '/home/startup.sh'
    appSettings: [
      // SCM (Kudu)
      {
        name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
        value: '1'
      }

      // PHP
      {
        name: 'PHP_INI_SCAN_DIR'
        value: '/usr/local/etc/php/conf.d:/home/site'
      }

      // REDCap
      {
        name: 'redcapAppZip'
        value: ProjectRedcap_DownloadAppZipUri
      }
      {
        name: 'redcapCommunityUsername'
        value: ProjectRedcap_CommunityUsername
      }
      {
        name: 'redcapCommunityPassword'
        value: ProjectRedcap_CommunityPassword
      }
      {
        name: 'redcapAppZipVersion'
        value: ProjectRedcap_DownloadAppZipVersion
      }

      // Azure Storage
      {
        name: 'StorageContainerName'
        value: storageAccount_ContainerName
      }
      {
        name: 'StorageAccount'
        value: storageAccount_ResourceName
      }
      {
        name: 'StorageKey'
        value: storageAccount_Key
      }

      // MySQL
      {
        name: 'DBHostName'
        value: databaseForMySql_HostName
      }
      {
        name: 'DBName'
        value: DatabaseForMySql_DbName
      }
      {
        name: 'DBUserName'
        value: databaseForMySql_AdministratorAccountName
      }
      {
        name: 'DBPassword'
        value: DatabaseForMySql_AdministratorLoginPassword
      }

      // SMTP
      {
        name: 'from_email_address'
        value: Smtp_FromEmailAddress
      }
      {
        name: 'smtp_fqdn_name'
        value: Smtp_FQDN
      }
      {
        name: 'smtp_port'
        value: '${Smtp_Port}'
      }
      {
        name: 'smtp_user_name'
        value: Smtp_UserLogin
      }
      {
        name: 'smtp_password'
        value: Smtp_UserPassword
      }
  ]
    // autoHealEnabled: false
    // azureStorageAccounts: {}
      connectionStrings: [
        {
          name: 'defaultConnection'
          connectionString: appService_Config_ConnectionString
          type: 'MySql'
        }
      ]
      // detailedErrorLoggingEnabled: false
    ftpsState: 'Disabled'
    // functionsRuntimeScaleMonitoringEnabled: false
    // http20Enabled: false
    // httpLoggingEnabled: false
    // ipSecurityRestrictions: [
    //   {
    //     ipAddress: 'Any'
    //     action: 'Allow'
    //     priority: 2147483647
    //     name: 'Allow all'
    //     description: 'Allow all access'
    //   }
    // ]
    // loadBalancing: 'LeastRequests'
    // localMySqlEnabled: false
    // logsDirectorySizeLimit: 35
    // managedPipelineMode: 'Integrated'
    // minimumElasticInstanceCount: 0
    // minTlsVersion: '1.2'
    numberOfWorkers: 1
    // preWarmedInstanceCount: 0
    // publishingUsername: ''
    // remoteDebuggingEnabled: false
    // remoteDebuggingVersion: 'VS2019'
    // requestTracingEnabled: false
    // scmIpSecurityRestrictions: [
    //   {
    //     ipAddress: 'Any'
    //     action: 'Allow'
    //     priority: 2147483647
    //     name: 'Allow all'
    //     description: 'Allow all access'
    //   }
    // ]
    // scmIpSecurityRestrictionsUseMain: false
    // scmMinTlsVersion: '1.2'
    scmType: 'None'
    // use32BitWorkerProcess: true
    // vnetPrivatePortsCount: 0
    // vnetRouteAllEnabled: false
    // webSocketsEnabled: false
    // }
  }
}

resource appService_WebSite_HostNameBinding_Resource 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: appService_WebSite_Resource
  name: appService_WebApp_FullDomainName
  properties: {
    hostNameType: 'Verified'
    sslState: 'SniEnabled'
    thumbprint: Cdph_SslCertificateThumbprint
  }
}

resource appService_WebSite_SourceControl_Resource 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: appService_WebSite_Resource
  name: 'web'
  properties: {
    branch: 'main'
    isManualIntegration: true
    repoUrl: 'https://github.com/AlanMcBee/w250b.git'
  }
}

output AzAppService_CustomDomainVerification string = appService_WebApp_CustomDomainDnsTxtRecordVerificationFinal

// Keep these output variables named the same as original until dependencies are identified and refactored
output MySQLHostName string = databaseForMySql_HostName
output MySqlUserName string = databaseForMySql_AdministratorAccountName
output webSiteFQDN string =  appService_WebApp_UniqueDefaultFullDomain
output storageAccountKey string = storageAccount_Key
output storageAccountName string = storageAccount_ResourceName
output storageContainerName string = storageAccount_ContainerName
