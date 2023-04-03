// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

// CDPH-specific parameters
// ------------------------

@description('CDPH Business Unit (numbers & digits only)')
@maxLength(5)
@minLength(2)
param Cdph_BusinessUnit string

@description('CDPH Business Unit Program (numbers & digits only)')
@maxLength(7)
@minLength(2)
param Cdph_BusinessUnitProgram string

@description('Targeted deployment environment')
@allowed([
  'dev'
  'test'
  'stage'
  'prod'
])
param Cdph_Environment string

// Virtual Network parameters
// --------------------------
@description('Settings for the Virtual Network resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftNetwork_virtualNetworks object

// Key Vault parameters
// --------------------

@description('Settings for the Key Vault resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftKeyVault_vaults object

// Storage Account parameters
// --------------------------

@description('Settings for the Storage Account resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftStorage_storageAccounts object

// Database for MySQL parameters
// -----------------------------

@description('Settings for the Database for MySQL resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftDBforMySQL_flexibleServers object

// App Service Plan parameters
// ---------------------------

@description('Settings for the App Service Plan resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftWeb_serverfarms object

// App Service parameters
// ----------------------

@description('Settings for the App Service resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftWeb_sites object

// App Service Certificate parameters
// ----------------------------------

@description('Settings for the App Service Certificate resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftWeb_certificates object

// Application Insights parameters
// -------------------------------

@description('Settings for the Application Insights resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftInsights_components object

@description('Settings for the Log Analytics workspace. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftOperationalInsights_workspaces object

// REDCap community and download parameters
// ----------------------------------------

@description('Settings for the REDCap community site. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param ProjectREDCap object

// SMTP configuration parameters
// -----------------------------

@description('Settings for the SMTP connection. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param Smtp object

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

// Virtual Network variables
// -------------------------

var virtualNetwork_ResourceName = MicrosoftNetwork_virtualNetworks.Arm_ResourceName

var virtualNetwork_Location = MicrosoftNetwork_virtualNetworks.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftNetwork_virtualNetworks.byEnvironment.ALL.Arm_Location

var virtualNetwork_DnsServers = MicrosoftNetwork_virtualNetworks.byEnvironment[Cdph_Environment].DnsServers ?? MicrosoftNetwork_virtualNetworks.byEnvironment.ALL.DnsServers

var virtualNetwork_AddressSpace = MicrosoftNetwork_virtualNetworks.byEnvironment[Cdph_Environment].AddressSpace ?? MicrosoftNetwork_virtualNetworks.byEnvironment.ALL.AddressSpace

// Key Vault variables
// -------------------

var keyVault_ResourceName = MicrosoftKeyVault_vaults.Arm_ResourceName

// Azure Storage Account variables
// -------------------------------

var storageAccount_ResourceName = MicrosoftStorage_storageAccounts.Arm_ResourceName

var storageAccount_Location = MicrosoftStorage_storageAccounts.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftStorage_storageAccounts.byEnvironment.ALL.Arm_Location

var storageAccount_Redundancy = MicrosoftStorage_storageAccounts.byEnvironment[Cdph_Environment].Redundancy ?? MicrosoftStorage_storageAccounts.byEnvironment.ALL.Redundancy

var storageAccount_ContainerName = MicrosoftStorage_storageAccounts.byEnvironment[Cdph_Environment].ContainerName ?? MicrosoftStorage_storageAccounts.byEnvironment.ALL.ContainerName

var storageAccount_PrimaryKey = storageAccount_Resource.listKeys().keys[0].value

// Database for MySQL variables
// ----------------------------

var databaseForMySql_ResourceName = MicrosoftDBforMySQL_flexibleServers.Arm_ResourceName

var databaseForMySql_HostName = '${databaseForMySql_ResourceName}.mysql.database.azure.com'

var databaseForMySql_Location = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.Arm_Location

var databaseForMySql_AdministratorLoginName = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].AdministratorLoginName ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.AdministratorLoginName

var databaseForMySql_DatabaseName = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].DatabaseName ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.DatabaseName

var databaseForMySql_Tier = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].Tier ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.Tier

var databaseForMySql_Sku = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].Sku ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.Sku

var databaseForMySql_StorageGB = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].StorageGB ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.StorageGB

var databaseForMySQL_BackupRetentionDays = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].BackupRetentionDays ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.BackupRetentionDays

var databaseForMySql_FirewallRules = MicrosoftDBforMySQL_flexibleServers.byEnvironment[Cdph_Environment].FirewallRules ?? MicrosoftDBforMySQL_flexibleServers.byEnvironment.ALL.FirewallRules

var databaseForMySql_AdministratorLoginPassword = keyVault_Resource.getSecret('MicrosoftDBforMySQL-flexibleServers-AdministratorLoginPassword-Secret')

// App Service Plan variables
// --------------------------

var appServicePlan_ResourceName = MicrosoftWeb_serverfarms.Arm_ResourceName

var appServicePlan_Location = MicrosoftWeb_serverfarms.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftWeb_serverfarms.byEnvironment.ALL.Arm_Location

var appServicePlan_LinuxFxVersion = MicrosoftWeb_serverfarms.byEnvironment[Cdph_Environment].LinuxFxVersion ?? MicrosoftWeb_serverfarms.byEnvironment.ALL.LinuxFxVersion

var appServicePlan_Tier = MicrosoftWeb_serverfarms.byEnvironment[Cdph_Environment].Tier ?? MicrosoftWeb_serverfarms.byEnvironment.ALL.Tier

var appServicePlan_SkuName = MicrosoftWeb_serverfarms.byEnvironment[Cdph_Environment].SkuName ?? MicrosoftWeb_serverfarms.byEnvironment.ALL.SkuName

var appServicePlan_Capacity = MicrosoftWeb_serverfarms.byEnvironment[Cdph_Environment].Capacity ?? MicrosoftWeb_serverfarms.byEnvironment.ALL.Capacity

// App Service variables
// ---------------------

var appService_Tags = union(
  {
    displayName: 'REDCap Web App'
  },
  cdph_CommonTags
)

var appService_WebHost_ResourceName = MicrosoftWeb_sites.Arm_ResourceName

var appService_WebHost_Location = MicrosoftWeb_sites.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftWeb_sites.byEnvironment.ALL.Arm_Location

var appService_WebHost_SourceControl_GitHubRepositoryUrl = MicrosoftWeb_sites.byEnvironment[Cdph_Environment].SourceControl_GitHubRepositoryUrl ?? MicrosoftWeb_sites.byEnvironment.ALL.SourceControl_GitHubRepositoryUrl

var appService_WebHost_CustomFullyQualifiedDomainName = MicrosoftWeb_sites.byEnvironment[Cdph_Environment].CustomFullyQualifiedDomainName ?? MicrosoftWeb_sites.byEnvironment.ALL.CustomFullyQualifiedDomainName

// App Service Certificates variables
// ----------------------------------

var appService_Certificates_ResourceName = MicrosoftWeb_certificates.Arm_ResourceName

var appService_Certificates_Location = MicrosoftWeb_certificates.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftWeb_certificates.byEnvironment.ALL.Arm_Location

// App Service App Configuration
// -----------------------------

var appService_Config_ConnectionString_settings = [
  'Database=${databaseForMySql_DatabaseName}'
  'Data Source=${databaseForMySql_HostName}'
  'User Id=${databaseForMySql_AdministratorLoginName}'
  'Password=${databaseForMySql_AdministratorLoginPassword}'
]
var appService_Config_ConnectionString = join(appService_Config_ConnectionString_settings, '; ')

// Application Insights variables
// ------------------------------

var applicationInsights_ResourceName = MicrosoftInsights_components.Arm_ResourceName

var applicationInsights_Location = MicrosoftInsights_components.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftInsights_components.byEnvironment.ALL.Arm_Location

var applicationInsights_Enabled = MicrosoftInsights_components.byEnvironment[Cdph_Environment].enabled ?? MicrosoftInsights_components.byEnvironment.ALL.enabled

var logAnalytics_Workspace_ResourceName = MicrosoftOperationalInsights_workspaces.Arm_ResourceName

var logAnalytics_Workspace_Location = MicrosoftOperationalInsights_workspaces.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftOperationalInsights_workspaces.byEnvironment.ALL.Arm_Location

// Project REDCap variables
// ------------------------

var projectREDCap_OverrideAutomaticDownloadUrlBuilder = ProjectREDCap.OverrideAutomaticDownloadUrlBuilder

var projectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName = ProjectREDCap.AutomaticDownloadUrlBuilder.CommunityUserName

var projectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion = ProjectREDCap.AutomaticDownloadUrlBuilder.AppZipVersion

// SMTP variables
// --------------

var smtp_HostFqdn = Smtp.byEnvironment[Cdph_Environment].HostFqdn ?? Smtp.byEnvironment.ALL.HostFqdn

var smtp_Port = Smtp.byEnvironment[Cdph_Environment].Port ?? Smtp.byEnvironment.ALL.Port

var smtp_UserLogin = Smtp.byEnvironment[Cdph_Environment].UserLogin ?? Smtp.byEnvironment.ALL.UserLogin

var smtp_FromEmailAddress = Smtp.byEnvironment[Cdph_Environment].FromEmailAddress ?? Smtp.byEnvironment.ALL.FromEmailAddress

// =========
// RESOURCES
// =========

// Azure Storage Account
// ---------------------

resource storageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccount_ResourceName
  location: storageAccount_Location
  sku: {
    name: storageAccount_Redundancy
  }
  kind: 'StorageV2'
  tags: cdph_CommonTags

  resource storageAccount_Blob_Resource 'blobServices' = {
    name: 'default'

    resource storageAccount_Blob_Container_Resource 'containers' = {
      name: storageAccount_ContainerName     }
  }
}

// Database for MySQL Flexible Server
// ----------------------------------

resource databaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: databaseForMySql_ResourceName
  location: databaseForMySql_Location
  tags: cdph_CommonTags
  sku: {
    name: databaseForMySql_Sku
    tier: databaseForMySql_Tier
  }
  properties: {
    administratorLogin: databaseForMySql_AdministratorLoginName
    administratorLoginPassword: databaseForMySql_AdministratorLoginPassword
    backup: {
      backupRetentionDays: databaseForMySQL_BackupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    replicationRole: 'None'
    storage: {
      storageSizeGB: databaseForMySql_StorageGB
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
    name: databaseForMySql_DatabaseName
    properties: {
      charset: 'utf8'
      collation: 'utf8_general_ci'
    }
  }

}

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVault_ResourceName
}

module keyVault_Secrets 'redcapAzureDeployMainSecrets.bicep' = {
  name: 'redcapAzureDeployKeyVaultSecrets'
  scope: resourceGroup()
  params: {
    KeyVault_ResourceName: keyVault_ResourceName
    MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword: keyVault_Resource.getSecret('MicrosoftDBforMySQL-flexibleServers-AdministratorLoginPassword-Secret')
    ProjectREDCap_CommunityPassword: keyVault_Resource.getSecret('ProjectREDCap-CommunityPassword-Secret')
    Smtp_UserPassword: keyVault_Resource.getSecret('Smtp-UserPassword-Secret')
  }
}

// Azure App Services
// ------------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlan_ResourceName
  location: appServicePlan_Location
  tags: cdph_CommonTags
  sku: {
    tier: appServicePlan_Tier
    name: appServicePlan_SkuName
    capacity: appServicePlan_Capacity
  }
  kind: 'app,linux' // see https://stackoverflow.com/a/62400396/100596 for acceptable values
  properties: {
    reserved: true
  }
}

resource appService_WebHost_Resource 'Microsoft.Web/sites@2022-03-01' = {
  name: appService_WebHost_ResourceName
  location: appService_WebHost_Location
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
      linuxFxVersion: appServicePlan_LinuxFxVersion
    }
  }

  resource appService_WebHost_HostNameBindings 'hostNameBindings' = {
    name: appService_WebHost_CustomFullyQualifiedDomainName
    properties: {
      sslState: 'SniEnabled'
      thumbprint: appService_Certificates_Resource.properties.thumbprint
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
        'index.php'
        'index.html'
        'default.html'
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
      APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights_Enabled ? appInsights_Resource.properties.InstrumentationKey : ''
      APPINSIGHTS_PROFILERFEATURE_VERSION: applicationInsights_Enabled ? '1.0.0' : ''
      APPINSIGHTS_SNAPSHOTFEATURE_VERSION: applicationInsights_Enabled ? '1.0.0' : ''
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights_Enabled ? appInsights_Resource.properties.ConnectionString : ''
      ApplicationInsightsAgent_EXTENSION_VERSION: applicationInsights_Enabled ? '~2' : ''
      DiagnosticServices_EXTENSION_VERSION: applicationInsights_Enabled ? '~3' : ''
      InstrumentationEngine_EXTENSION_VERSION: applicationInsights_Enabled ? 'disabled' : ''
      SnapshotDebugger_EXTENSION_VERSION: applicationInsights_Enabled ? 'disabled' : ''
      XDT_MicrosoftApplicationInsights_BaseExtensions: applicationInsights_Enabled ? 'disabled' : ''
      XDT_MicrosoftApplicationInsights_Mode: applicationInsights_Enabled ? 'recommended' : ''
      XDT_MicrosoftApplicationInsights_PreemptSdk: applicationInsights_Enabled ? 'disabled' : ''
    
      // PHP
      PHP_INI_SCAN_DIR: '/usr/local/etc/php/conf.d:/home/site'

      // REDCap
      zipUsername: projectREDCap_OverrideAutomaticDownloadUrlBuilder ? '' : projectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName
      zipPassword: projectREDCap_OverrideAutomaticDownloadUrlBuilder ? '' : ProjectREDCap_CommunityPassword
      zipVersion: projectREDCap_OverrideAutomaticDownloadUrlBuilder ? '' : projectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion

      // Azure Storage
      StorageAccount: storageAccount_ResourceName
      StorageKey: storageAccount_PrimaryKey
      StorageContainerName: storageAccount_ContainerName

      // MySQL
      DBHostName: databaseForMySql_HostName
      DBName: databaseForMySql_DatabaseName
      DBUserName: databaseForMySql_AdministratorLoginName
      DBPassword: databaseForMySql_AdministratorLoginPassword

      // SMTP
      fromEmailAddress: smtp_FromEmailAddress
      smtpFqdn: smtp_HostFqdn
      smtpPort: '${smtp_Port}'
      smtp_user_name: smtp_UserLogin
      smtp_password: Smtp_UserPassword
    }
  }

 resource appService_WebHost_SourceControl_Resource 'sourcecontrols' = {
    name: 'web'
    properties: {
      branch: 'main'
      isManualIntegration: true
      repoUrl: appService_WebHost_SourceControl_GitHubRepositoryUrl
    }
  }

}

resource appService_Certificates_Resource 'Microsoft.Web/certificates@2022-03-01' = {
  name: appService_Certificates_ResourceName
  location: appService_Certificates_Location
  tags: cdph_CommonTags
  properties: {
    hostNames: [
      appService_WebHost_CustomFullyQualifiedDomainName
    ]
    keyVaultId: keyVault_Resource.id
    keyVaultSecretName: appService_WebHost_Resource.name
    serverFarmId: appService_Plan_Resource.id
  }
}

resource appInsights_Resource 'Microsoft.Insights/components@2020-02-02' = if (applicationInsights_Enabled) {
  name: applicationInsights_ResourceName
  location: applicationInsights_Location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics_Workspace_Resource.id
  }
}

resource logAnalytics_Workspace_Resource 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (applicationInsights_Enabled) {
  name: logAnalytics_Workspace_ResourceName
  location: logAnalytics_Workspace_Location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// NOTE: Bicep/ARM will lowercase the initial letter for all output variable names
output out_AzAppService_CustomDomainVerification string = appService_WebHost_Resource.properties.customDomainVerificationId
//output out_AzAppService_CustomDomainVerification string = 'disabled'

// Keep these output variables named the same as original until dependencies are identified and refactored
output out_MySQLHostName string = databaseForMySql_HostName
output out_MySqlUserName string = databaseForMySql_AdministratorLoginName
output out_StorageAccountKey string = storageAccount_PrimaryKey
output out_StorageAccountName string = storageAccount_ResourceName
output out_StorageContainerName string = storageAccount_ContainerName
output out_WebHost_IpAddress string = appService_WebHost_Resource.properties.inboundIpAddress // Ignore this warning: "The property 'inboundIpAddress' does not exist on type 'SiteConfigResource'. Make sure to only use property names that are defined by the type."
