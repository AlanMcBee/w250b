// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// TODO: remove as I stop using them
param sites_redcapwebwinrxnwnphyrehrs_name string = 'redcapwebwinrxnwnphyrehrs'
param serverfarms_ASP_rgitsdessredcapdev_01_name string = 'ASP-rgitsdessredcapdev-01'

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
@maxLength(5)
@minLength(2)
param Cdph_BusinessUnitProgram string = 'RedCap'

@description('Targeted deployment environment')
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

@description('Thumbprint for SSL SNI server certificate.')
@minLength(40)
@maxLength(40)
param Cdph_SslCertificateThumbprint string

// General Azure Resource Manager parameters
// -----------------------------------------

// TODO: Add more if planning to use alternate regions for failover or redundancy
@description('Location where most resources will be deployed')
@allowed([
  'westus'
])
param Arm_ResourceGroupRegionId string = 'westus'

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

@description('Subdomain name for the application (no spaces, no dashes, no special characters). Default = \'\' (empty string); If empty, a subdomain like REDCap-{CdphEnvironment}-{targetInstancePadded} will be used. NOTE: This needs to be unique to the root domain.')
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

@description('Database for MySQL: Server name. Default = \'\' (empty string); If empty, a name like REDCap-{CdphEnvironment}-{targetInstancePadded} will be used. NOTE: This needs to be unique to the Azure Cloud to which you are deploying.')
param DatabaseForMySql_ServerName string = ''

@description('Database for MySQL: Administrator login name. Default = redcap_app')
@minLength(1)
param DatabaseForMySql_AdministratorLoginName string = 'redcap_app'

@description('Database for MySQL: Administrator password')
@minLength(8)
@secure()
param DatabaseForMySql_AdministratorLoginPassword string

@description('Azure database for MySQL SKU Size (MB). Default = 10240 (MB) = 10 GB') // Recommended: https://projectredcap.org/software/requirements/
param DatabaseForMySql_SkuSizeMB int = 10240

@description('Database for MySql server performance tier. Please review https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers and ensure your choices are available in the selected region. Default = GeneralPurpose')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param DatabaseForMySql_Tier string = 'GeneralPurpose'

@description('Database for MySql compute generation. Please review https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers and ensure your choices are available in the selected region. Default = Gen5')
@allowed([
  'Gen4'
  'Gen5'
])
param DatabaseForMySql_Family string = 'Gen5'

@description('Database for MySql vCore count. Please review https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers and ensure your choices are available in the selected region. Default = 2')
@allowed([
  1
  2
  4
  8
  16
  32
])
param DatabaseForMySql_Cores int = 2

@description('Database for MySQL version. Default = 5.7')
@allowed([
  '5.6'
  '5.7'
])
param DatabaseForMySql_Version string = '5.7'

// Azure Storage Account parameters
// --------------------------------

@description('Azure Storage Account redundancy. See https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy for more information. Default = Standard_LRS (minimum; 3 copies in one region)')
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

// Use to map region IDs to location names (if supporting more than one region)
var arm_RegionId_LocationName_map = {
  westus: 'West US'
}
var arm_ResourceGroup_LocationName = arm_RegionId_LocationName_map[Arm_ResourceGroupRegionId]

// Make instance number into a zero-prefixed string exactly 2 digits long
var arm_ResourceInstance_ZeroPadded = padLeft(Cdph_ResourceInstance, 2, '0')

// Database for MySQL variables
// ----------------------------

var databaseForMySql_Tier_Code_Map = {
  Basic: 'B'
  GeneralPurpose: 'GP'
  MemoryOptimized: 'MO'
}

var databaseForMySql_Sku = '${databaseForMySql_Tier_Code_Map[DatabaseForMySql_Tier]}_${DatabaseForMySql_Family}_${DatabaseForMySql_Cores}'

var databaseForMySql_HostName = '${DatabaseForMySql_ServerName}.mysql.database.azure.com'

// Azure Storage Account variables
// -------------------------------

var storageAccount_ResourceName = 'st${toLower(Cdph_Organization)}${toLower(Cdph_BusinessUnit)}${toLower(Cdph_BusinessUnitProgram)}${toLower(Cdph_Environment)}${arm_ResourceInstance_ZeroPadded}'

var storageAccount_ContainerName

// var storageAccount_Keys = concat(listKeys(storageAccount_ResourceName, '2015-05-01-preview').key1)
var storageAccount_Key = storageAccount_Resource.listKeys().keys[0].value

// App Service variables
// ---------------------

var appServicePlan_ResourceName = 'asp-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'
var appService_ResourceName = 'app-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

var appService_Tags = union(
  {
    displayName: 'REDCap Web App'
  },
  cdph_CommonTags
)

var appService_UniqueDefaultSubdomain = '${AppService_WebAppSubdomain}-${uniqueString(resourceGroup().id)}'
var appService_WebApp_SubdomainFinal = empty(AppService_WebAppSubdomain) ? 'REDCap-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}' : AppService_WebAppSubdomain

// This 26-character value will be the same if repeatedly deployed to the same subscription and resource group
var appService_WebApp_CustomDomainDnsTxtRecordVerificationDefault = '${uniqueString(subscription().subscriptionId)}${uniqueString(resourceGroup().id)}'
var appService_WebApp_CustomDomainDnsTxtRecordVerificationFinal - empty(AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue) ? appService_WebApp_CustomDomainDnsTxtRecordVerificationDefault : AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue

// App Service App Configuration
// -----------------------------

var appService_Config_ConnectionString_Database = 'Database=${DatabaseForMySql_DbName}'
var appService_Config_ConnectionString_DataSource = 'Data Source=${DatabaseForMySql_ServerName}.mysql.database.azure.com'
var appService_Config_ConnectionString_UserId = 'User Id=${DatabaseForMySql_AdministratorLoginName}@${DatabaseForMySql_ServerName}'
var appService_Config_ConnectionString_Password = 'Password=${DatabaseForMySql_AdministratorLoginPassword}'
var appService_Config_ConnectionString_items = [
  appService_Config_ConnectionString_Database
  appService_Config_ConnectionString_DataSource
  appService_Config_ConnectionString_UserId
  appService_Config_ConnectionString_Password 
]
var appService_Config_ConnectionString = join(appService_Config_ConnectionString_items, '; ')

// =========
// RESOURCES
// =========

// Azure Storage Account
// ---------------------

resource storageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccount_ResourceName
  location: Arm_ResourceGroupRegionId
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
  name: 'redcap' // fixed container name
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

// Azure App Services
// ------------------

resource appServicePlan_Resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlan_ResourceName
  location: Arm_ResourceGroupRegionId
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

resource webSiteAppServiceResource 'Microsoft.Web/sites@2022-03-01' = {
  name: appService_ResourceName
  location: Arm_ResourceGroupRegionId
  tags: appService_Tags
  dependsOn: [
    storageAccount_Resource
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
        name: '${AppService_WebAppSubdomain}.cdph.ca.gov'
        sslState: 'SniEnabled'
        thumbprint: Cdph_SslCertificateThumbprint
        hostType: 'Standard'
      }
      {
        name: '${appService_UniqueDefaultSubdomain}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${appService_UniqueDefaultSubdomain}.scm.azurewebsites.net'
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
    serverFarmId: appServicePlan_Resource.id
    siteConfig: {
      // acrUseManagedIdentityCreds: false
      alwaysOn: true
      // functionAppScaleLimit: 0
      // http20Enabled: false
      linuxFxVersion: AppService_LinuxFxVersion
      // minimumElasticInstanceCount: 0
      // numberOfWorkers: 1
    }
    // storageAccountRequired: false
    // vnetContentShareEnabled: false
    // vnetImagePullEnabled: false
    // vnetRouteAllEnabled: false
  }
}

resource webSiteAppServiceConfigResource 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: webSiteAppServiceResource
  name: 'web'
  properties: {
    numberOfWorkers: 1

    // defaultDocuments: [
    //   'Default.htm'
    //   'Default.html'
    //   'Default.asp'
    //   'index.htm'
    //   'index.html'
    //   'iisstart.htm'
    //   'default.aspx'
    //   'index.php'
    //   'hostingstart.html'
    // ]
    // netFrameworkVersion: 'v4.0'
    // phpVersion: '7.4'
    // requestTracingEnabled: false
    // remoteDebuggingEnabled: false
    // remoteDebuggingVersion: 'VS2019'
    // httpLoggingEnabled: false
    // acrUseManagedIdentityCreds: false
    // logsDirectorySizeLimit: 35
    // detailedErrorLoggingEnabled: false
    // publishingUsername: '$redcapwebwinrxnwnphyrehrs'
    scmType: 'None'
    // use32BitWorkerProcess: true
    // webSocketsEnabled: false
    alwaysOn: true
    // managedPipelineMode: 'Integrated'
    // virtualApplications: [
    //   {
    //     virtualPath: '/'
    //     physicalPath: 'site\\wwwroot'
    //     preloadEnabled: true
    //   }
    // ]
    // loadBalancing: 'LeastRequests'
    // experiments: {
    //   rampUpRules: []
    // }
    // // autoHealEnabled: false
    // // vnetRouteAllEnabled: false
    // // vnetPrivatePortsCount: 0
    // // localMySqlEnabled: false
    // // ipSecurityRestrictions: [
    // //   {
    // //     ipAddress: 'Any'
    // //     action: 'Allow'
    // //     priority: 2147483647
    // //     name: 'Allow all'
    // //     description: 'Allow all access'
    // //   }
    // // ]
    // // scmIpSecurityRestrictions: [
    // //   {
    // //     ipAddress: 'Any'
    // //     action: 'Allow'
    // //     priority: 2147483647
    // //     name: 'Allow all'
    // //     description: 'Allow all access'
    // //   }
    // // ]
    // scmIpSecurityRestrictionsUseMain: false
    // http20Enabled: false
    // minTlsVersion: '1.2'
    // scmMinTlsVersion: '1.2'
    // ftpsState: 'AllAllowed'
    // preWarmedInstanceCount: 0
    // functionsRuntimeScaleMonitoringEnabled: false
    // minimumElasticInstanceCount: 0
    // azureStorageAccounts: {
    // }
    connectionStrings: [
      {
        name: 'defaultConnection'
        connectionString: appService_Config_ConnectionString
        type: 'MySql'
      }
    ]
    appCommandLine: '/home/startup.sh'
    appSettings: [
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
        value:  '${administratorDatabaseForMySqlLoginName}@${serverName_var_var}'
      }
      {
        name: 'DBPassword'
        value: administratorDatabaseForMySqlLoginPassword
      }
      {
        name: 'PHP_INI_SCAN_DIR'
        value: '/usr/local/etc/php/conf.d:/home/site'
      }
      {
        name: 'from_email_address'
        value: smtpFromEmailAddress
      }
      {
        name: 'smtp_fqdn_name'
        value: smtpFQDN
      }
      {
        name: 'smtp_port'
        value: smtpPort
      }
      {
        name: 'smtp_user_name'
        value: smtpUserLoginName
      }
      {
        name: 'smtp_password'
        value: smtpUserPassword
      }
      {
        name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
        value: '1'
      }
  ]
  }
}

output CustomDomainVerification string = appService_WebApp_CustomDomainDnsTxtRecordVerificationDefault

/* ******************************************************************************************* */
/* END OF MIGRATION WORK ********************************************************************* */
/* ******************************************************************************************* */

// Template for MySQL Flexible Server

var mySqlFlexibleServerResourceName = 'mysql-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${Cdph_ResourceInstance}'

resource mySqlFlexibleServerResource 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: mySqlFlexibleServerResourceName
  location: arm_ResourceGroup_LocationName
  tags: {
    'ACCOUNTABILITY-Business Unit': ''
    'ACCOUNTABILITY-Cherwell Change Control': ''
    'ACCOUNTABILITY-Cost Center': ''
    'ACCOUNTABILITY-Date Created': '2022-12-21T08:35:48.1647006Z'
    'ACCOUNTABILITY-Owner': ''
    'ACCOUNTABILITY-Program': ''
    ENVIRONMENT: ''
    'SECURITY-Criticality': ''
    'SECURITY-Facing': ''
  }
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: 'redcap_app'
    storage: {
      storageSizeGB: 20
      iops: 360
      autoGrow: 'Enabled'
    }
    version: '8.0.21'
    availabilityZone: '1'
    maintenanceWindow: {
      customWindow: 'Disabled'
      dayOfWeek: 0
      startHour: 0
      startMinute: 0
    }
    replicationRole: 'None'
    network: {
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}


resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230112t014111_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230112t014111-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230113t014113_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230113t014113-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230113t182123_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230113t182123-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230115t190125_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230115t190125-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230116t110142_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230116t110142-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230117t110215_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230117t110215-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_daily_20230118t110246_0874f561_cad3_44bd_b8e6_191f85b769e1 'Microsoft.DBforMySQL/flexibleServers/backups@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'daily-20230118t110246-0874f561-cad3-44bd-b8e6-191f85b769e1'
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_information_schema 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'information_schema'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_mysql 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'mysql'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_0900_ai_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_performance_schema 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'performance_schema'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_0900_ai_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_redcapwebwin_db 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'redcapwebwin_db'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_sys 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'sys'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_0900_ai_ci'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_AllowAllAzureServicesAndResourcesWithinAzureIps_2022_12_21_1_39_49 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps_2022-12-21_1-39-49'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource flexibleServers_flexdb_itsd_ess_dev_01_name_ClientIPAddress_2022_12_21_0_35_9 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  parent: mySqlFlexibleServerResource
  name: 'ClientIPAddress_2022-12-21_0-35-9'
  properties: {
    startIpAddress: '108.251.136.202'
    endIpAddress: '108.251.136.202'
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_stcdphessredcapdev01_name_default 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  parent: storageAccount_Resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    protocolSettings: {
      smb: {
      }
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_storageAccounts_stcdphessredcapdev01_name_default 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  parent: storageAccount_Resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageAccounts_stcdphessredcapdev01_name_default 'Microsoft.Storage/storageAccounts/tableServices@2022-05-01' = {
  parent: storageAccount_Resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}


resource sites_redcapwebwinrxnwnphyrehrs_name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  parent: webSiteAppServiceResource
  name: 'ftp'
  location: 'West US'
  tags: {
    displayName: 'WebApp'
    'ACCOUNTABILITY-Business Unit': ''
    'ACCOUNTABILITY-Cherwell Change Control': ''
    'ACCOUNTABILITY-Cost Center': ''
    'ACCOUNTABILITY-Date Created': '2022-12-15T19:52:03.6034629Z'
    'ACCOUNTABILITY-Owner': ''
    'ACCOUNTABILITY-Program': ''
    ENVIRONMENT: ''
    'SECURITY-Criticality': ''
    'SECURITY-Facing': ''
  }
  properties: {
    allow: true
  }
}

resource sites_redcapwebwinrxnwnphyrehrs_name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  parent: webSiteAppServiceResource
  name: 'scm'
  location: 'West US'
  tags: {
    displayName: 'WebApp'
    'ACCOUNTABILITY-Business Unit': ''
    'ACCOUNTABILITY-Cherwell Change Control': ''
    'ACCOUNTABILITY-Cost Center': ''
    'ACCOUNTABILITY-Date Created': '2022-12-15T19:52:03.6034629Z'
    'ACCOUNTABILITY-Owner': ''
    'ACCOUNTABILITY-Program': ''
    ENVIRONMENT: ''
    'SECURITY-Criticality': ''
    'SECURITY-Facing': ''
  }
  properties: {
    allow: true
  }
}


resource sites_redcapwebwinrxnwnphyrehrs_name_2fd83fe423631a4a0f2909f4aefc88b8541305b5 'Microsoft.Web/sites/deployments@2022-03-01' = {
  parent: webSiteAppServiceResource
  name: '2fd83fe423631a4a0f2909f4aefc88b8541305b5'
  location: 'West US'
  properties: {
    status: 3
    author_email: 'rob.taylor@vumc.org'
    author: 'Rob Taylor'
    deployer: 'GitHub'
    message: 'Merge pull request #6 from tonyrci2/patch-1\n\nfetch PHP version from PATH instead of hard-coding it'
    start_time: '2022-12-15T19:54:15.3723778Z'
    end_time: '2022-12-15T20:12:11.5180512Z'
    active: false
  }
}

resource sites_redcapwebwinrxnwnphyrehrs_name_redcap_dev_cdph_ca_gov 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: webSiteAppServiceResource
  name: 'redcap-dev.cdph.ca.gov'
  location: 'West US'
  properties: {
    siteName: 'redcapwebwinrxnwnphyrehrs'
    hostNameType: 'Verified'
    sslState: 'SniEnabled'
    thumbprint: '203B6E0EBD2987B0F0DF532B6838D00BA68C1E3E'
  }
}

resource sites_redcapwebwinrxnwnphyrehrs_name_sites_redcapwebwinrxnwnphyrehrs_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: webSiteAppServiceResource
  name: '${sites_redcapwebwinrxnwnphyrehrs_name}.azurewebsites.net'
  location: 'West US'
  properties: {
    siteName: 'redcapwebwinrxnwnphyrehrs'
    hostNameType: 'Verified'
  }
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_20T06_14_37_6194754 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-20T06_14_37_6194754'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_20T15_14_37_9595631 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-20T15_14_37_9595631'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_20T21_14_38_1768720 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-20T21_14_38_1768720'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_21T06_14_38_5155820 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-21T06_14_38_5155820'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_21T15_14_38_8701216 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-21T15_14_38_8701216'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_21T21_14_39_3050895 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-21T21_14_39_3050895'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_22T06_14_39_4505565 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-22T06_14_39_4505565'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_22T15_14_39_8584273 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-22T15_14_39_8584273'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_22T21_14_40_0460873 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-22T21_14_40_0460873'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_23T06_14_40_4344047 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-23T06_14_40_4344047'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_23T15_14_40_7598025 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-23T15_14_40_7598025'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_23T21_14_40_9930084 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-23T21_14_40_9930084'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_24T06_14_41_3503319 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-24T06_14_41_3503319'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_24T15_14_41_7175337 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-24T15_14_41_7175337'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_24T21_14_41_9206318 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-24T21_14_41_9206318'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_25T06_14_42_2844941 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-25T06_14_42_2844941'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_25T15_14_42_6628127 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-25T15_14_42_6628127'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_25T21_14_42_8948639 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-25T21_14_42_8948639'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_26T06_14_43_2706496 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-26T06_14_43_2706496'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_26T15_14_43_6001587 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-26T15_14_43_6001587'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_26T21_14_43_8228170 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-26T21_14_43_8228170'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_27T06_14_44_1783024 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-27T06_14_44_1783024'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_27T15_14_45_0333494 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-27T15_14_45_0333494'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_27T21_14_45_2866029 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-27T21_14_45_2866029'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_28T06_14_45_6558526 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-28T06_14_45_6558526'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_28T15_14_46_0149853 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-28T15_14_46_0149853'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_28T21_14_46_2562030 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-28T21_14_46_2562030'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_29T06_14_46_6413750 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-29T06_14_46_6413750'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_29T15_14_47_0022285 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-29T15_14_47_0022285'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_29T21_14_47_2395584 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-29T21_14_47_2395584'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_30T06_14_47_6248393 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-30T06_14_47_6248393'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_30T15_14_47_9747461 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-30T15_14_47_9747461'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_30T21_14_48_2084603 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-30T21_14_48_2084603'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_31T06_14_48_5750189 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-31T06_14_48_5750189'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_31T15_14_48_9572104 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-31T15_14_48_9572104'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2022_12_31T21_14_49_1929092 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2022-12-31T21_14_49_1929092'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_01T06_14_50_4357237 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-01T06_14_50_4357237'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_01T15_14_50_7541288 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-01T15_14_50_7541288'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_01T21_14_51_0017093 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-01T21_14_51_0017093'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_02T06_14_52_2544137 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-02T06_14_52_2544137'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_02T15_14_53_1697723 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-02T15_14_53_1697723'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_02T21_14_53_3934863 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-02T21_14_53_3934863'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_03T06_14_53_7961561 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-03T06_14_53_7961561'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_03T15_14_54_1137052 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-03T15_14_54_1137052'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_03T21_14_54_3568462 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-03T21_14_54_3568462'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_04T06_14_54_7066736 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-04T06_14_54_7066736'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_04T15_14_55_0919446 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-04T15_14_55_0919446'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_04T18_14_55_2083705 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-04T18_14_55_2083705'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_04T21_14_55_3091062 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-04T21_14_55_3091062'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_05T00_14_55_4223936 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-05T00_14_55_4223936'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_05T03_14_55_5262659 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-05T03_14_55_5262659'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_05T06_14_55_6625304 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-05T06_14_55_6625304'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_05T15_14_55_9828523 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-05T15_14_55_9828523'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_05T18_14_56_0956412 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-05T18_14_56_0956412'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_05T21_14_56_2064962 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-05T21_14_56_2064962'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_06T00_14_56_3310550 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-06T00_14_56_3310550'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_06T03_14_56_4508867 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-06T03_14_56_4508867'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_06T06_14_56_5726096 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-06T06_14_56_5726096'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_06T15_14_56_9452132 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-06T15_14_56_9452132'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_06T18_14_57_0698250 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-06T18_14_57_0698250'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_06T21_14_57_1971827 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-06T21_14_57_1971827'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_07T00_14_57_3252226 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-07T00_14_57_3252226'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_07T03_14_57_4477626 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-07T03_14_57_4477626'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_07T06_14_57_5754466 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-07T06_14_57_5754466'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_07T15_14_57_9231009 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-07T15_14_57_9231009'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_07T18_14_58_0391258 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-07T18_14_58_0391258'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_07T21_14_58_1562466 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-07T21_14_58_1562466'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_08T00_14_58_2842038 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-08T00_14_58_2842038'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_08T03_14_58_4896814 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-08T03_14_58_4896814'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_08T06_14_58_5373667 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-08T06_14_58_5373667'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_08T15_14_58_8729862 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-08T15_14_58_8729862'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_08T18_14_58_9697491 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-08T18_14_58_9697491'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_08T21_14_59_0877303 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-08T21_14_59_0877303'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_09T00_14_59_2212063 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-09T00_14_59_2212063'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_09T03_14_59_3499654 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-09T03_14_59_3499654'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_09T06_14_59_4665860 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-09T06_14_59_4665860'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_09T15_14_59_8582080 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-09T15_14_59_8582080'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_09T18_14_59_9878378 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-09T18_14_59_9878378'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_09T21_15_00_1338999 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-09T21_15_00_1338999'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_10T00_15_00_2325161 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-10T00_15_00_2325161'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_10T03_15_00_3566402 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-10T03_15_00_3566402'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_10T06_15_00_4845096 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-10T06_15_00_4845096'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_10T15_15_00_9009609 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-10T15_15_00_9009609'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_10T18_15_00_9968915 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-10T18_15_00_9968915'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_10T21_15_01_1147064 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-10T21_15_01_1147064'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_11T00_15_01_2342964 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-11T00_15_01_2342964'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_11T03_15_01_3476318 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-11T03_15_01_3476318'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_11T06_15_01_4609970 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-11T06_15_01_4609970'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_11T15_15_01_8194480 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-11T15_15_01_8194480'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_11T18_15_01_9400106 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-11T18_15_01_9400106'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_11T21_15_02_0270665 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-11T21_15_02_0270665'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_12T00_15_02_1391728 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-12T00_15_02_1391728'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_12T03_15_02_2470454 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-12T03_15_02_2470454'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_12T06_15_02_3782081 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-12T06_15_02_3782081'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_12T15_15_02_7157762 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-12T15_15_02_7157762'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_12T18_15_02_8517003 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-12T18_15_02_8517003'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_12T21_15_02_9416389 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-12T21_15_02_9416389'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_13T00_15_03_0824945 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-13T00_15_03_0824945'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_13T03_15_03_2229769 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-13T03_15_03_2229769'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_13T06_15_03_2992557 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-13T06_15_03_2992557'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_13T15_15_03_7344566 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-13T15_15_03_7344566'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_13T18_15_03_8468338 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-13T18_15_03_8468338'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_13T21_15_03_9674735 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-13T21_15_03_9674735'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T00_15_04_1042535 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T00_15_04_1042535'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T03_15_04_2563588 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T03_15_04_2563588'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T06_15_04_3525169 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T06_15_04_3525169'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T13_15_05_4020071 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T13_15_05_4020071'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T14_15_05_4214896 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T14_15_05_4214896'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T15_15_05_4832808 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T15_15_05_4832808'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T16_15_05_5263131 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T16_15_05_5263131'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T17_15_05_5555862 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T17_15_05_5555862'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T18_15_05_5912578 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T18_15_05_5912578'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T19_15_05_6287153 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T19_15_05_6287153'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T20_15_05_6810243 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T20_15_05_6810243'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T21_15_05_7254994 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T21_15_05_7254994'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T22_15_05_7475594 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T22_15_05_7475594'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_14T23_15_05_8024674 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-14T23_15_05_8024674'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T00_15_05_8407381 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T00_15_05_8407381'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T01_15_05_8601526 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T01_15_05_8601526'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T02_15_05_9156685 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T02_15_05_9156685'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T03_15_05_9917300 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T03_15_05_9917300'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T04_15_05_9967812 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T04_15_05_9967812'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T05_15_06_0427779 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T05_15_06_0427779'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T06_15_06_0728503 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T06_15_06_0728503'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T07_15_06_1375540 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T07_15_06_1375540'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T08_15_06_1550732 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T08_15_06_1550732'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T09_15_06_2118147 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T09_15_06_2118147'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T10_15_06_2339571 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T10_15_06_2339571'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T11_15_06_2696214 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T11_15_06_2696214'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T12_15_06_3215655 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T12_15_06_3215655'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T13_15_06_3675938 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T13_15_06_3675938'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T14_15_06_4065222 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T14_15_06_4065222'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T15_15_06_4431923 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T15_15_06_4431923'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T16_15_06_4717075 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T16_15_06_4717075'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T17_15_06_5120861 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T17_15_06_5120861'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T18_15_06_5478869 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T18_15_06_5478869'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T19_15_06_5887368 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T19_15_06_5887368'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T20_15_06_6249649 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T20_15_06_6249649'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T21_15_06_7020564 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T21_15_06_7020564'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T22_15_06_7319931 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T22_15_06_7319931'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_15T23_15_06_7652666 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-15T23_15_06_7652666'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T00_15_06_8083674 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T00_15_06_8083674'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T01_15_06_8618450 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T01_15_06_8618450'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T02_15_06_8921001 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T02_15_06_8921001'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T03_15_06_9324373 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T03_15_06_9324373'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T04_15_06_9678609 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T04_15_06_9678609'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T05_15_07_0194126 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T05_15_07_0194126'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T06_15_07_0556709 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T06_15_07_0556709'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T07_15_07_1001689 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T07_15_07_1001689'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T08_15_07_1596138 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T08_15_07_1596138'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T09_15_07_1955926 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T09_15_07_1955926'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T10_15_07_2186099 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T10_15_07_2186099'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T11_15_07_2707513 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T11_15_07_2707513'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T12_15_07_3125434 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T12_15_07_3125434'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T13_15_07_3526342 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T13_15_07_3526342'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T14_15_07_3829257 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T14_15_07_3829257'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T15_15_07_4354545 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T15_15_07_4354545'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T16_15_07_4725096 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T16_15_07_4725096'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T17_15_07_5303666 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T17_15_07_5303666'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T18_15_07_5621232 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T18_15_07_5621232'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T19_15_07_6341906 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T19_15_07_6341906'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T20_15_07_6396747 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T20_15_07_6396747'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T21_15_07_6893164 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T21_15_07_6893164'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T22_15_07_7355075 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T22_15_07_7355075'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_16T23_15_07_7698151 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-16T23_15_07_7698151'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T00_15_08_7134981 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T00_15_08_7134981'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T01_15_08_7167336 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T01_15_08_7167336'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T02_15_08_7605071 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T02_15_08_7605071'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T03_15_08_7904320 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T03_15_08_7904320'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T04_15_08_8273353 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T04_15_08_8273353'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T05_15_08_8578205 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T05_15_08_8578205'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T06_15_08_8938572 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T06_15_08_8938572'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T07_15_08_9342006 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T07_15_08_9342006'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T08_15_08_9870664 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T08_15_08_9870664'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T09_15_09_0045958 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T09_15_09_0045958'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T10_15_09_0327978 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T10_15_09_0327978'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T11_15_09_0721367 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T11_15_09_0721367'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T12_15_09_1342947 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T12_15_09_1342947'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T13_15_09_1725339 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T13_15_09_1725339'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T14_15_09_1983297 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T14_15_09_1983297'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T15_15_09_2301292 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T15_15_09_2301292'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T16_15_09_2606613 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T16_15_09_2606613'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T17_15_09_3006543 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T17_15_09_3006543'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T18_15_09_3423279 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T18_15_09_3423279'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T19_15_09_3651368 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T19_15_09_3651368'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T20_15_09_4245497 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T20_15_09_4245497'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T21_15_09_4494532 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T21_15_09_4494532'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T22_15_09_5095977 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T22_15_09_5095977'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_17T23_15_09_5449580 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-17T23_15_09_5449580'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T00_15_09_5898824 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T00_15_09_5898824'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T01_15_09_6163326 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T01_15_09_6163326'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T02_15_09_6590084 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T02_15_09_6590084'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T03_15_09_6895571 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T03_15_09_6895571'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T04_15_09_7309293 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T04_15_09_7309293'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T05_15_09_7655313 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T05_15_09_7655313'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T06_15_09_8121000 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T06_15_09_8121000'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T07_15_09_8613225 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T07_15_09_8613225'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T08_15_09_8875507 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T08_15_09_8875507'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T09_15_09_9282309 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T09_15_09_9282309'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T10_15_09_9588574 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T10_15_09_9588574'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T11_15_10_0181418 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T11_15_10_0181418'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T12_15_10_0875431 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T12_15_10_0875431'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T13_15_10_0833264 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T13_15_10_0833264'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T14_15_10_1309673 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T14_15_10_1309673'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T15_15_10_1538293 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T15_15_10_1538293'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T16_15_10_2019266 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T16_15_10_2019266'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T17_15_10_2416422 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T17_15_10_2416422'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T18_15_10_3053744 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T18_15_10_3053744'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T19_15_10_3455794 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T19_15_10_3455794'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T20_15_10_3944629 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T20_15_10_3944629'
}

resource sites_redcapwebwinrxnwnphyrehrs_name_2023_01_18T21_15_10_4260043 'Microsoft.Web/sites/snapshots@2015-08-01' = {
  parent: webSiteAppServiceResource
  name: '2023-01-18T21_15_10_4260043'
}

