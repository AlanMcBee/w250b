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

/* 
@description('Thumbprint for SSL SNI server certificate. A custom domain name is a required part of this template.')
@minLength(40)
@maxLength(40)
param Cdph_SslCertificateThumbprint string
 */

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

/* 
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
])
param Arm_StorageResourceLocation string = 'westus'
 */

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

/* 
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

@description('Subdomain name for the application (no spaces, no dashes, no special characters). Default = \'\' (empty string); If empty, a subdomain like REDCap-{CdphEnvironment}-{InstanceNumber} will be used. NOTE: This needs to be unique to the root domain cdph.ca.gov.')
param AppService_WebHost_Subdomain string = ''
// See variable appService_WebHost_SubdomainFinal for the final value

@description('Custom domain TXT DNS record verification value. Default = \'\' (empty string); If empty, a random value will be generated. This value will be used to verify ownership of the custom domain. See https://learn.microsoft.com/azure/app-service/app-service-web-tutorial-custom-domain for more information.')
param AppService_WebHost_CustomDomainDnsTxtRecordVerificationValue string = ''
// See variable appService_WebHost_CustomDomainDnsTxtRecordVerificationFinal for the final value

@description('Source control repository URL. Default = https://github.com/AlanMcBee/w250b.git')
param AppService_WebHost_SourceControl_GitHubRepositoryUri string = 'https://github.com/AlanMcBee/w250b.git'


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
 */

// Key Vault parameters
// --------------------

// No Key Vault parameters required

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

var orgLength = length(Cdph_Organization)
var unitLength = length(Cdph_BusinessUnit)
var programLength = length(Cdph_BusinessUnitProgram)
var envLength = length(Cdph_Environment)
var minBaseLength = length('kv00') + 4 // 'kv' + 2-digit instance + 4 hyphens
var maxKeyVaultNameLength = 24
var inputNameLength = orgLength + unitLength + programLength + envLength
var inputOverBaseLength = inputNameLength + minBaseLength
var isOneOverMax = (inputOverBaseLength - 1) == maxKeyVaultNameLength // if one over, will just remove the last hyphen
var isOverMax = (inputOverBaseLength - 1) > maxKeyVaultNameLength // if over, will remove the last hyphen anyway
var lastHyphen = (isOneOverMax || isOverMax) ? '-' : ''
var lengthOverMax = isOverMax ? (inputOverBaseLength - 1) - maxKeyVaultNameLength : 0 // adjust for the removed hyphen
var newProgramLength = programLength - lengthOverMax
var newProgram = substring(Cdph_BusinessUnitProgram, 0, newProgramLength)
var keyVault_ResourceName = 'kv-${Cdph_Organization}-${Cdph_BusinessUnit}-${newProgram}-${Cdph_Environment}${lastHyphen}${arm_ResourceInstance_ZeroPadded}'

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVault_ResourceName
  location: Arm_MainSiteResourceLocation
  tags: cdph_CommonTags
  properties: {
    accessPolicies: [] // required, and will be updated by redcapAzureDeployMain.bicep
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: false
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
  }
}

// =======
// OUTPUTS
// =======

output Out_KeyVault_ResourceName string = keyVault_ResourceName
