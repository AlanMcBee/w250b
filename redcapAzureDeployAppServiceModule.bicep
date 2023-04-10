// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Storage Account parameters
// --------------------------

param MicrosoftStorage_storageAccounts_Arm_ResourceName string

param MicrosoftStorage_storageAccounts_ContainerName string

// MySQL parameters
// ----------------

param MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName string

@secure()
param MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword string

param MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName string

@secure()
param MicrosoftDBforMySQL_flexibleServers_ConnectionString string

param MicrosoftDBforMySQL_flexibleServers_DatabaseName string

param MicrosoftDBforMySQL_flexibleServers_HostName string


// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arm_ResourceName string

// App Service Certificate parameters
// ----------------------------------

param MicrosoftWeb_certificates_Arm_ResourceName string

// App Service parameters
// ----------------------

param MicrosoftWeb_sites_Arm_Location string

param MicrosoftWeb_sites_Arm_ResourceName string

param MicrosoftWeb_sites_CustomFullyQualifiedDomainName string

param MicrosoftWeb_sites_LinuxFxVersion string

param MicrosoftWeb_sites_SourceControl_GitHubRepositoryUrl string

// Application Insights parameters
// -------------------------------

param enableDeployment_ApplicationInsights bool

param MicrosoftInsights_components_Arm_ResourceName string

// Project REDCap parameters
// -------------------------

param ProjectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion string

param ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName string

@secure()
param ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserPassword string

// SMTP parameters
// ---------------

param Smtp_FromEmailAddress string

param Smtp_HostFqdn string

param Smtp_Port int

param Smtp_UserLogin string

@secure()
param Smtp_UserPassword string

// =========
// VARIABLES
// =========

// Storage Account variables
// -------------------------

var microsoftStorage_storageAccounts_PrimaryKey = StorageAccount_Resource.listKeys().keys[0].value

// App Service variables
// ---------------------

var appService_Tags = union(
  {
    displayName: 'REDCap Web App'
  },
  Cdph_CommonTags
)

// =========
// RESOURCES
// =========

resource StorageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: MicrosoftStorage_storageAccounts_Arm_ResourceName
}

resource DatabaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' existing = {
  name: MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName
}

resource AppServicePlan_Resource 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: MicrosoftWeb_serverfarms_Arm_ResourceName
}

resource AppService_Certificates_Resource 'Microsoft.Web/certificates@2022-03-01' existing = {
  name: MicrosoftWeb_certificates_Arm_ResourceName
}

resource AppInsights_Resource 'Microsoft.Insights/components@2020-02-02' existing = if (enableDeployment_ApplicationInsights) {
  name: MicrosoftInsights_components_Arm_ResourceName
}

resource appService_WebHost_Resource 'Microsoft.Web/sites@2022-03-01' = {
  name: MicrosoftWeb_sites_Arm_ResourceName
  location: MicrosoftWeb_sites_Arm_Location
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
      linuxFxVersion: MicrosoftWeb_sites_LinuxFxVersion
    }
  }

  resource appService_WebHost_HostNameBindings 'hostNameBindings' = {
    name: MicrosoftWeb_sites_CustomFullyQualifiedDomainName
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
          connectionString: MicrosoftDBforMySQL_flexibleServers_ConnectionString
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
      APPINSIGHTS_INSTRUMENTATIONKEY: enableDeployment_ApplicationInsights ? AppInsights_Resource.properties.InstrumentationKey : ''
      APPINSIGHTS_PROFILERFEATURE_VERSION: enableDeployment_ApplicationInsights ? '1.0.0' : ''
      APPINSIGHTS_SNAPSHOTFEATURE_VERSION: enableDeployment_ApplicationInsights ? '1.0.0' : ''
      APPLICATIONINSIGHTS_CONNECTION_STRING: enableDeployment_ApplicationInsights ? AppInsights_Resource.properties.ConnectionString : ''
      ApplicationInsightsAgent_EXTENSION_VERSION: enableDeployment_ApplicationInsights ? '~2' : ''
      DiagnosticServices_EXTENSION_VERSION: enableDeployment_ApplicationInsights ? '~3' : ''
      InstrumentationEngine_EXTENSION_VERSION: enableDeployment_ApplicationInsights ? 'disabled' : ''
      SnapshotDebugger_EXTENSION_VERSION: enableDeployment_ApplicationInsights ? 'disabled' : ''
      XDT_MicrosoftApplicationInsights_BaseExtensions: enableDeployment_ApplicationInsights ? 'disabled' : ''
      XDT_MicrosoftApplicationInsights_Mode: enableDeployment_ApplicationInsights ? 'recommended' : ''
      XDT_MicrosoftApplicationInsights_PreemptSdk: enableDeployment_ApplicationInsights ? 'disabled' : ''

      // PHP
      PHP_INI_SCAN_DIR: '/usr/local/etc/php/conf.d:/home/site'

      // REDCap
      zipUsername: ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName
      zipPassword: ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserPassword
      zipVersion: ProjectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion

      // Azure Storage
      StorageAccount: MicrosoftStorage_storageAccounts_Arm_ResourceName
      StorageKey: microsoftStorage_storageAccounts_PrimaryKey
      StorageContainerName: MicrosoftStorage_storageAccounts_ContainerName

      // MySQL
      DBHostName: MicrosoftDBforMySQL_flexibleServers_HostName
      DBName: MicrosoftDBforMySQL_flexibleServers_DatabaseName
      DBUserName: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName
      DBPassword: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword

      // SMTP
      fromEmailAddress: Smtp_FromEmailAddress
      smtpFqdn: Smtp_HostFqdn
      smtpPort: '${Smtp_Port}'
      smtp_user_name: Smtp_UserLogin
      smtp_password: Smtp_UserPassword
    }
  }

  resource appService_WebHost_SourceControl_Resource 'sourcecontrols' = {
    name: 'web'
    properties: {
      branch: 'main'
      isManualIntegration: true
      repoUrl: MicrosoftWeb_sites_SourceControl_GitHubRepositoryUrl
    }
  }

}

output out_CustomDomainVerificationId string = appService_WebHost_Resource.properties.customDomainVerificationId

output out_WebHost_IpAddress string = appService_WebHost_Resource.properties.inboundIpAddress // Ignore this warning: "The property 'inboundIpAddress' does not exist on type 'SiteConfigResource'. Make sure to only use property names that are defined by the type."
