// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_Environment string

param Cdph_CommonTags object

// Storage Account parameters
// --------------------------

param MicrosoftStorage_storageAccounts_Arguments object

// MySQL parameters
// ----------------

param MicrosoftDBforMySQL_flexibleServers_Arguments object

param DatabaseForMySql_HostName string

@secure()
param DatabaseForMySql_AdministratorLoginPassword string

@secure()
param DatabaseForMySql_ConnectionString string

// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arguments object

// App Service Certificate parameters
// ----------------------------------

param MicrosoftWeb_certificates_Arguments object

// App Service parameters
// ----------------------

param MicrosoftWeb_sites_Arguments object

// Application Insights parameters
// -------------------------------

param MicrosoftInsights_components_Arguments object

// Project REDCap parameters
// -------------------------

param ProjectREDCap_Arguments object

@secure()
param ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityPassword string

// SMTP parameters
// ---------------

param Smtp_Arguments object

@description('')
@secure()
param Smtp_UserPassword string

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Storage Account variables
// -------------------------

var storageAccount_ResourceName = MicrosoftStorage_storageAccounts_Arguments.Arm_ResourceName

var storageAccount_PrimaryKey = StorageAccount_Resource.listKeys().keys[0].value

var storageAccount_ContainerName = MicrosoftStorage_storageAccounts_Arguments.byEnvironment[Cdph_Environment].ContainerName ?? MicrosoftStorage_storageAccounts_Arguments.byEnvironment.ALL.ContainerName

// MySQL variables
// ---------------

var databaseForMySql_FlexibleServer_ResourceName = MicrosoftDBforMySQL_flexibleServers_Arguments.Arm_ResourceName

var databaseForMySql_AdministratorLoginName = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].AdministratorLoginName ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.AdministratorLoginName

var databaseForMySql_DatabaseName = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].DatabaseName ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.DatabaseName

// App Service Plan variables
// --------------------------

var AppServicePlan_ResourceName = MicrosoftWeb_serverfarms_Arguments.Arm_ResourceName

// App Service Certificate variables
// ---------------------------------

var AppService_Certificates_ResourceName = MicrosoftWeb_certificates_Arguments.Arm_ResourceName

// Application Insights variables
// ------------------------------

var ApplicationInsights_ResourceName = MicrosoftInsights_components_Arguments.Arm_ResourceName

var applicationInsights_Enabled = MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment].enabled ?? MicrosoftInsights_components_Arguments.byEnvironment.ALL.enabled

// Project REDCap variables
// ------------------------

var projectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName = ProjectREDCap_Arguments.AutomaticDownloadUrlBuilder.CommunityUserName

var projectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion = ProjectREDCap_Arguments.AutomaticDownloadUrlBuilder.AppZipVersion

// SMTP variables
// --------------

var smtp_HostFqdn = Smtp_Arguments.byEnvironment[Cdph_Environment].HostFqdn ?? Smtp_Arguments.byEnvironment.ALL.HostFqdn

var smtp_Port = Smtp_Arguments.byEnvironment[Cdph_Environment].Port ?? Smtp_Arguments.byEnvironment.ALL.Port

var smtp_UserLogin = Smtp_Arguments.byEnvironment[Cdph_Environment].UserLogin ?? Smtp_Arguments.byEnvironment.ALL.UserLogin

var smtp_FromEmailAddress = Smtp_Arguments.byEnvironment[Cdph_Environment].FromEmailAddress ?? Smtp_Arguments.byEnvironment.ALL.FromEmailAddress

// App Service variables
// ---------------------

var appService_Tags = union(
  {
    displayName: 'REDCap Web App'
  },  
  Cdph_CommonTags
  )  
  
var appService_WebHost_ResourceName = MicrosoftWeb_sites_Arguments.Arm_ResourceName

var appService_WebHost_Location = MicrosoftWeb_sites_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftWeb_sites_Arguments.byEnvironment.ALL.Arm_Location

var appService_LinuxFxVersion = MicrosoftWeb_sites_Arguments.byEnvironment[Cdph_Environment].AppService_LinuxFxVersion ?? MicrosoftWeb_sites_Arguments.byEnvironment.ALL.AppService_LinuxFxVersion

var appService_WebHost_SourceControl_GitHubRepositoryUrl = MicrosoftWeb_sites_Arguments.byEnvironment[Cdph_Environment].SourceControl_GitHubRepositoryUrl ?? MicrosoftWeb_sites_Arguments.byEnvironment.ALL.SourceControl_GitHubRepositoryUrl

var appService_WebHost_CustomFullyQualifiedDomainName = MicrosoftWeb_sites_Arguments.byEnvironment[Cdph_Environment].CustomFullyQualifiedDomainName ?? MicrosoftWeb_sites_Arguments.byEnvironment.ALL.CustomFullyQualifiedDomainName

// =========
// RESOURCES
// =========

resource StorageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccount_ResourceName
}

resource DatabaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' existing = {
  name: databaseForMySql_FlexibleServer_ResourceName
}

resource AppServicePlan_Resource 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: AppServicePlan_ResourceName
}    

resource AppService_Certificates_Resource 'Microsoft.Web/certificates@2022-03-01' existing = {
  name: AppService_Certificates_ResourceName
}

resource AppInsights_Resource 'Microsoft.Insights/components@2020-02-02' existing = if (applicationInsights_Enabled) {
  name: ApplicationInsights_ResourceName
}

resource appService_WebHost_Resource 'Microsoft.Web/sites@2022-03-01' = {
  name: appService_WebHost_ResourceName
  location: appService_WebHost_Location
  tags: appService_Tags
  dependsOn: [
    StorageAccount_Resource
    DatabaseForMySql_FlexibleServer_Resource
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientAffinityEnabled: false
    httpsOnly: true
    serverFarmId: AppServicePlan_Resource.id
    siteConfig: {
      alwaysOn: true
      linuxFxVersion: appService_LinuxFxVersion
    }
  }

  resource appService_WebHost_HostNameBindings 'hostNameBindings' = {
    name: appService_WebHost_CustomFullyQualifiedDomainName
    properties: {
      sslState: 'SniEnabled'
      thumbprint: AppService_Certificates_Resource.properties.thumbprint
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
          connectionString: DatabaseForMySql_ConnectionString
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
      APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights_Enabled ? AppInsights_Resource.properties.InstrumentationKey : ''
      APPINSIGHTS_PROFILERFEATURE_VERSION: applicationInsights_Enabled ? '1.0.0' : ''
      APPINSIGHTS_SNAPSHOTFEATURE_VERSION: applicationInsights_Enabled ? '1.0.0' : ''
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights_Enabled ? AppInsights_Resource.properties.ConnectionString : ''
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
      zipUsername: projectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName
      zipPassword: ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityPassword
      zipVersion: projectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion

      // Azure Storage
      StorageAccount: storageAccount_ResourceName
      StorageKey: storageAccount_PrimaryKey
      StorageContainerName: storageAccount_ContainerName

      // MySQL
      DBHostName: DatabaseForMySql_HostName
      DBName: databaseForMySql_DatabaseName
      DBUserName: databaseForMySql_AdministratorLoginName
      DBPassword: DatabaseForMySql_AdministratorLoginPassword

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

output out_CustomDomainVerificationId string = appService_WebHost_Resource.properties.customDomainVerificationId

output out_WebHost_IpAddress string = appService_WebHost_Resource.properties.inboundIpAddress // Ignore this warning: "The property 'inboundIpAddress' does not exist on type 'SiteConfigResource'. Make sure to only use property names that are defined by the type."
