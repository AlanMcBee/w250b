// Converted from azuredeploy.json in https://github.com/microsoft/azure-redcap-paas
// Names renamed for refactoring

@description('Name of azure web app')
param siteName string

@description('Stack settings')
param linuxFxVersion string = 'php|7.4'

@description('Database administrator login name')
@minLength(1)
param administratorDatabaseForMySqlLoginName string = 'redcap_app'

@description('Database administrator password')
@minLength(8)
@secure()
param administratorDatabaseForMySqlLoginPassword string

@description('REDCap zip file URI.')
param redcapDownloadAppZipUri string = ''

@description('REDCap Community site username for downloading the REDCap zip file.')
param redcapCommunityUsername string

@description('REDCap Community site password for downloading the REDCap zip file.')
@secure()
param redcapCommunityPassword string

@description('REDCap zip file version to be downloaded from the REDCap Community site.')
param redcapDownloadAppZipVersion string = 'latest'

@description('Email address configured as the sending address in REDCap')
param smtpFromEmailAddress string

@description('Fully-qualified domain name of your SMTP relay endpoint')
param smtpFQDN string

@description('Login name for your SMTP relay')
param smtpUserLoginName string

@description('Login password for your SMTP relay')
@secure()
param smtpUserPassword string

@description('Port for your SMTP relay')
param smtpPort string = '587'

@description('Describes plan\'s pricing tier and capacity - this can be changed after deployment. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
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
param appServicePlanSkuName string = 'S1'

@description('Describes plan\'s instance count (how many distinct web servers will be deployed in the farm) - this can be changed after deployment')
@minValue(1)
param appServicePlanCapacity int = 1

@description('Azure database for MySQL sku Size ')
param databaseForMySqlSkuSizeMB int = 5120

@description('Select MySql server performance tier. Please review https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers and ensure your choices are available in the selected region.')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseForMySqlTier string = 'GeneralPurpose'

@description('Select MySql compute generation. Please review https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers and ensure your choices are available in the selected region.')
@allowed([
  'Gen4'
  'Gen5'
])
param databaseForMySqlFamily string = 'Gen5'

@description('Select MySql vCore count. Please review https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers and ensure your choices are available in the selected region.')
@allowed([
  1
  2
  4
  8
  16
  32
])
param databaseForMySqlCores int = 2

@description('MySQL version')
@allowed([
  '5.6'
  '5.7'
])
param databaseForMySqlVersion string = '5.7'

@description('The default selected is \'Locally Redundant Storage\' (3 copies in one region). See https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy for more information.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
param storageAccountRedundancy string = 'Standard_LRS'

@description('Name of the container used to store backing files in the new storage account. This container is created automatically during deployment.')
param XstorageContainerName string = 'redcap'

@description('The path to the deployment source files on GitHub')
param XrepoURL string = 'https://github.com/microsoft/azure-redcap-paas.git'

@description('The main branch of the application repo')
param Xbranch string = 'main'

var siteName_var = replace(siteName, ' ', '')
var XdatabaseName = '${siteName_var}_db'
var XserverName_var_var = '${siteName_var}${uniqueString(resourceGroup().id)}'
var XhostingPlanName_var_var = '${siteName_var}_serviceplan'
var webSiteName_var_var = '${siteName_var}${uniqueString(resourceGroup().id)}'
var XtierSymbol = {
  Basic: 'B'
  GeneralPurpose: 'GP'
  MemoryOptimized: 'MO'
}
var databaseForMySqlSku = '${tierSymbol[databaseForMySqlTier]}_${databaseForMySqlFamily}_${databaseForMySqlCores}'
var storageName_var_var = 'storage${uniqueString(resourceGroup().id)}'
var storageAccountId = '${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageName_var_var}'

resource storageName_var 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageName_var_var
  location: resourceGroup().location
  sku: {
    name: storageAccountRedundancy
  }
  tags: {
    displayName: 'BackingStorage'
  }
  kind: 'Storage'
}

resource storageName_var_default 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageName_var
  name: 'default'
}

resource storageName_var_default_storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  parent: storageName_var_default
  name: storageContainerName
}

resource hostingPlanName_var 'Microsoft.Web/serverfarms@2016-09-01' = {
  name: hostingPlanName_var_var
  location: resourceGroup().location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: appServicePlanSkuName
    capacity: appServicePlanCapacity
  }
  kind: 'linux'
  properties: {
    name: hostingPlanName_var_var
    reserved: true
  }
}

resource webSiteName_var 'Microsoft.Web/sites@2016-08-01' = {
  name: webSiteName_var_var
  location: resourceGroup().location
  tags: {
    displayName: 'WebApp'
  }
  properties: {
    name: webSiteName_var_var
    serverFarmId: hostingPlanName_var_var
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
      connectionStrings: [
        {
          name: 'defaultConnection'
          connectionString: 'Database=${databaseName};Data Source=${serverName_var_var}.mysql.database.azure.com;User Id=${administratorDatabaseForMySqlLoginName}@${serverName_var_var};Password=${administratorDatabaseForMySqlLoginPassword}'
          type: 'MySql'
        }
      ]
      appCommandLine: '/home/startup.sh'
      appSettings: [
        {
          name: 'StorageContainerName'
          value: storageContainerName
        }
        {
          name: 'StorageAccount'
          value: storageName_var_var
        }
        {
          name: 'StorageKey'
          value: concat(listKeys(storageAccountId, '2015-05-01-preview').key1)
        }
        {
          name: 'redcapAppZip'
          value: redcapDownloadAppZipUri
        }
        {
          name: 'redcapCommunityUsername'
          value: redcapCommunityUsername
        }
        {
          name: 'redcapCommunityPassword'
          value: redcapCommunityPassword
        }
        {
          name: 'redcapAppZipVersion'
          value: redcapDownloadAppZipVersion
        }
        {
          name: 'DBHostName'
          value: '${serverName_var_var}.mysql.database.azure.com'
        }
        {
          name: 'DBName'
          value: databaseName
        }
        {
          name: 'DBUserName'
          value: '${administratorDatabaseForMySqlLoginName}@${serverName_var_var}'
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
  dependsOn: [
    hostingPlanName_var
    storageName_var
  ]
}

resource webSiteName_var_web 'Microsoft.Web/sites/sourcecontrols@2015-08-01' = {
  parent: webSiteName_var
  name: 'web'
  location: resourceGroup().location
  tags: {
    displayName: 'CodeDeploy'
  }
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
  dependsOn: [
    serverName_var

  ]
}

resource serverName_var 'Microsoft.DBforMySQL/servers@2017-12-01-preview' = {
  name: serverName_var_var
  location: resourceGroup().location
  tags: {
    displayName: 'MySQLAzure'
  }
  properties: {
    version: databaseForMySqlVersion
    administratorLogin: administratorDatabaseForMySqlLoginName
    administratorLoginPassword: administratorDatabaseForMySqlLoginPassword
    storageProfile: {
      storageMB: databaseForMySqlSkuSizeMB
      backupRetentionDays: '7'
      geoRedundantBackup: 'Disabled'
    }
    sslEnforcement: 'Disabled'
  }
  sku: {
    name: databaseForMySqlSku
  }
}

resource serverName_var_AllowAzureIPs 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01-preview' = {
  parent: serverName_var
  name: 'AllowAzureIPs'
  location: resourceGroup().location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [

    serverName_var_database
  ]
}

resource serverName_var_database 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  parent: serverName_var
  name: '${databaseName}'
  tags: {
    displayName: 'DB'
  }
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

output MySQLHostName string = '${serverName_var_var}.mysql.database.azure.com'
output MySqlUserName string = '${administratorDatabaseForMySqlLoginName}@${serverName_var_var}'
output webSiteFQDN string = '${webSiteName_var_var}.azurewebsites.net'
output storageAccountKey string = concat(listKeys(storageAccountId, '2015-05-01-preview').key1)
output storageAccountName string = storageName_var_var
output storageContainerName string = storageContainerName
