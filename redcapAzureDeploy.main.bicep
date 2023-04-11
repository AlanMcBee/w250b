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

param MicrosoftNetwork_virtualNetworks_AddressSpace_AddressPrefixes array

param MicrosoftNetwork_virtualNetworks_Arm_Location string

param MicrosoftNetwork_virtualNetworks_Arm_ResourceName string

param MicrosoftNetwork_virtualNetworks_DhcpOptions_DnsServers array

// Key Vault parameters
// --------------------

param MicrosoftKeyVault_vaults_Arm_ResourceName string

// Storage Account parameters
// --------------------------

param MicrosoftStorage_storageAccounts_Arm_Location string

param MicrosoftStorage_storageAccounts_Arm_ResourceName string

param MicrosoftStorage_storageAccounts_BlobServices_Containers_Name string

param MicrosoftStorage_storageAccounts_Sku_Name string

// Database for MySQL parameters
// -----------------------------

param MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName string

param MicrosoftDBforMySQL_flexibleServers_Arm_Location string

param MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName string

param MicrosoftDBforMySQL_flexibleServers_Backup_BackupRetentionDays int

param MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name string

param MicrosoftDBforMySQL_flexibleServers_FirewallRules object

param MicrosoftDBforMySQL_flexibleServers_Sku_Name string

param MicrosoftDBforMySQL_flexibleServers_Sku_Tier string

param MicrosoftDBforMySQL_flexibleServers_Storage_StorageSizeGB int

// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arm_Location string

param MicrosoftWeb_serverfarms_Arm_ResourceName string

param MicrosoftWeb_serverfarms_Capacity int

param MicrosoftWeb_serverfarms_Sku string

param MicrosoftWeb_serverfarms_Tier string

// App Service parameters
// ----------------------

param MicrosoftWeb_sites_Arm_Location string

param MicrosoftWeb_sites_Arm_ResourceName string

param MicrosoftWeb_sites_CustomFullyQualifiedDomainName string

param MicrosoftWeb_sites_LinuxFxVersion string

param MicrosoftWeb_sites_SourceControl_GitHubRepositoryUrl string

// App Service Certificate parameters
// ----------------------------------

param MicrosoftWeb_certificates_Arm_ResourceName string

param MicrosoftWeb_certificates_Arm_Location string

// Application Insights parameters
// -------------------------------

param enableDeployment_ApplicationInsights bool

param MicrosoftInsights_components_Arm_ResourceName string

param MicrosoftInsights_components_Arm_Location string

// Log Analytics parameters
// ------------------------

param MicrosoftOperationalInsights_workspaces_Arm_Location string

param MicrosoftOperationalInsights_workspaces_Arm_ResourceName string

// REDCap community and download parameters
// ----------------------------------------

param ProjectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion string

param ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName string

// SMTP configuration parameters
// -----------------------------

param Smtp_FromEmailAddress string

param Smtp_HostFqdn string

param Smtp_Port int

param Smtp_UserLogin string

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

var cdph_CommonTags = CdphCommon_Module.outputs.out_Cdph_CommonTags

// Database for MySQL variables
// ----------------------------

var MicrosoftDBforMySQL_flexibleServers_HostName = MicrosoftDBforMySQL_flexibleServers_Module.outputs.out_MicrosoftDBforMySQL_flexibleServers_HostName
var MicrosoftDBforMySQL_flexibleServers_ConnectionString = MicrosoftDBforMySQL_flexibleServers_Module.outputs.out_MicrosoftDBforMySQL_flexibleServers_ConnectionString

// =========
// RESOURCES
// =========

// No-resources deployment
// -----------------------

module CdphCommon_Module 'redcapAzureDeployCdphModule.bicep' = {
  name: take('${deployment().name}.Cdph_Common', 64)
  params: {
    Arm_DeploymentCreationDateTime: Arm_DeploymentCreationDateTime
    Cdph_BusinessUnit: Cdph_BusinessUnit
    Cdph_BusinessUnitProgram: Cdph_BusinessUnitProgram
    Cdph_Environment: Cdph_Environment
  }
}

// Azure Key Vault
// ---------------

resource MicrosoftKeyVault_vaults_Resource 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: MicrosoftKeyVault_vaults_Arm_ResourceName
}

resource MicrosoftKeyVault_vaults_Secrets_Resource 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: MicrosoftKeyVault_vaults_Resource
  name: 'MicrosoftDBforMySQLConnectionString-Secret'
  properties: {
    value: MicrosoftDBforMySQL_flexibleServers_ConnectionString
  }
}

// Azure Storage Account
// ---------------------

module MicrosoftStorage_storageAccounts_Module 'redcapAzureDeployStorageModule.bicep' = {
  name: take('${deployment().name}.MicrosoftStorage_storageAccounts', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftStorage_storageAccounts_Arm_ResourceName: MicrosoftStorage_storageAccounts_Arm_ResourceName
    MicrosoftStorage_storageAccounts_Arm_Location: MicrosoftStorage_storageAccounts_Arm_Location
    MicrosoftStorage_storageAccounts_Sku_Name: MicrosoftStorage_storageAccounts_Sku_Name
    MicrosoftStorage_storageAccounts_BlobServices_Containers_Name: MicrosoftStorage_storageAccounts_BlobServices_Containers_Name
  }
}

// Database for MySQL Flexible Server
// ----------------------------------

module MicrosoftDBforMySQL_flexibleServers_Module 'redcapAzureDeployMySqlModule.bicep' = {
  name: take('${deployment().name}.MicrosoftDBforMySQL_flexibleServers', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName: MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName
    MicrosoftDBforMySQL_flexibleServers_Arm_Location: MicrosoftDBforMySQL_flexibleServers_Arm_Location
    MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName
    MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword: MicrosoftKeyVault_vaults_Resource.getSecret('MicrosoftDBforMySQLAdministratorLoginPassword-Secret')
    MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name: MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name
    MicrosoftDBforMySQL_flexibleServers_Sku_Tier: MicrosoftDBforMySQL_flexibleServers_Sku_Tier
    MicrosoftDBforMySQL_flexibleServers_Sku_Name: MicrosoftDBforMySQL_flexibleServers_Sku_Name
    MicrosoftDBforMySQL_flexibleServers_Storage_StorageSizeGB: MicrosoftDBforMySQL_flexibleServers_Storage_StorageSizeGB
    MicrosoftDBforMySQL_flexibleServers_Backup_BackupRetentionDays: MicrosoftDBforMySQL_flexibleServers_Backup_BackupRetentionDays
    MicrosoftDBforMySQL_flexibleServers_FirewallRules: MicrosoftDBforMySQL_flexibleServers_FirewallRules
  }
}

// App Service Plan
// ----------------

module MicrosoftWeb_serverfarms_Module 'redcapAzureDeployAppServicePlanModule.bicep' = {
  name: take('${deployment().name}.MicrosoftWeb_serverfarms', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftWeb_serverfarms_Arm_ResourceName: MicrosoftWeb_serverfarms_Arm_ResourceName
    MicrosoftWeb_serverfarms_Arm_Location: MicrosoftWeb_serverfarms_Arm_Location
    MicrosoftWeb_serverfarms_Tier: MicrosoftWeb_serverfarms_Tier
    MicrosoftWeb_serverfarms_Sku: MicrosoftWeb_serverfarms_Sku
    MicrosoftWeb_serverfarms_Capacity: MicrosoftWeb_serverfarms_Capacity
  }
}

// App Service
// -----------

module MicrosoftWeb_sites_Module 'redcapAzureDeployAppServiceModule.bicep' = {
  name: take('${deployment().name}.MicrosoftWeb_sites', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftStorage_storageAccounts_Arm_ResourceName: MicrosoftStorage_storageAccounts_Arm_ResourceName
    MicrosoftStorage_storageAccounts_ContainerName: MicrosoftStorage_storageAccounts_BlobServices_Containers_Name
    MicrosoftDBforMySQL_flexibleServers_HostName: MicrosoftDBforMySQL_flexibleServers_HostName
    MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword: MicrosoftKeyVault_vaults_Resource.getSecret('MicrosoftDBforMySQLAdministratorLoginPassword-Secret')
    MicrosoftDBforMySQL_flexibleServers_ConnectionString: MicrosoftDBforMySQL_flexibleServers_ConnectionString
    MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName: MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName
    MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName
    MicrosoftDBforMySQL_flexibleServers_DatabaseName: MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name
    MicrosoftWeb_serverfarms_Arm_ResourceName: MicrosoftWeb_serverfarms_Arm_ResourceName
    MicrosoftWeb_certificates_Arm_ResourceName: MicrosoftWeb_certificates_Arm_ResourceName
    MicrosoftWeb_sites_Arm_ResourceName: MicrosoftWeb_sites_Arm_ResourceName
    MicrosoftWeb_sites_Arm_Location: MicrosoftWeb_sites_Arm_Location
    MicrosoftWeb_sites_LinuxFxVersion: MicrosoftWeb_sites_LinuxFxVersion
    MicrosoftWeb_sites_SourceControl_GitHubRepositoryUrl: MicrosoftWeb_sites_SourceControl_GitHubRepositoryUrl
    MicrosoftWeb_sites_CustomFullyQualifiedDomainName: MicrosoftWeb_sites_CustomFullyQualifiedDomainName
    MicrosoftInsights_components_Arm_ResourceName: MicrosoftInsights_components_Arm_ResourceName
    enableDeployment_ApplicationInsights: enableDeployment_ApplicationInsights
    ProjectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion: ProjectREDCap_AutomaticDownloadUrlBuilder_AppZipVersion
    ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName: ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserName
    ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityUserPassword: MicrosoftKeyVault_vaults_Resource.getSecret('ProjectREDCapCommunityPassword-Secret')
    Smtp_HostFqdn: Smtp_HostFqdn
    Smtp_Port: Smtp_Port
    Smtp_UserLogin: Smtp_UserLogin
    Smtp_FromEmailAddress: Smtp_FromEmailAddress
    Smtp_UserPassword: MicrosoftKeyVault_vaults_Resource.getSecret('SmtpUserPassword-Secret')
  }
  dependsOn: [
    MicrosoftWeb_serverfarms_Module
    MicrosoftWeb_certificates_Module
    MicrosoftInsights_components_Module
    MicrosoftStorage_storageAccounts_Module
  ]
}

// App Service Certificate
// -----------------------

module MicrosoftWeb_certificates_Module 'redcapAzureDeployAppServiceCertificateModule.bicep' = {
  name: take('${deployment().name}.MicrosoftWeb_certificates', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftKeyVault_vaults_Arm_ResourceName: MicrosoftKeyVault_vaults_Arm_ResourceName
    MicrosoftWeb_serverfarms_Arm_ResourceName: MicrosoftWeb_serverfarms_Arm_ResourceName
    MicrosoftWeb_sites_Arm_ResourceName: MicrosoftWeb_sites_Arm_ResourceName
    MicrosoftWeb_sites_CustomFullyQualifiedDomainName: MicrosoftWeb_sites_CustomFullyQualifiedDomainName
    MicrosoftWeb_certificates_Arm_ResourceName: MicrosoftWeb_certificates_Arm_ResourceName
    MicrosoftWeb_certificates_Arm_Location: MicrosoftWeb_certificates_Arm_Location
  }
  dependsOn: [
    MicrosoftWeb_serverfarms_Module
  ]
}

// Application Insights
// --------------------

module MicrosoftInsights_components_Module 'redcapAzureDeployApplicationInsightsModule.bicep' = {
  name: take('${deployment().name}.MicrosoftInsights_components', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftOperationalInsights_workspaces_Arm_ResourceName: MicrosoftOperationalInsights_workspaces_Arm_ResourceName
    MicrosoftInsights_components_Arm_ResourceName: MicrosoftInsights_components_Arm_ResourceName
    MicrosoftInsights_components_Arm_Location: MicrosoftInsights_components_Arm_Location
    enableDeployment_ApplicationInsights: enableDeployment_ApplicationInsights
  }
  dependsOn: [
    MicrosoftOperationalInsights_workspaces_Module
  ]
}

// Log Analytics Workspace
// -----------------------

module MicrosoftOperationalInsights_workspaces_Module 'redcapAzureDeployLogAnalyticsModule.bicep' = {
  name: take('${deployment().name}.MicrosoftOperationalInsights_workspaces', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    enableDeployment_ApplicationInsights: enableDeployment_ApplicationInsights
    MicrosoftOperationalInsights_workspaces_Arm_ResourceName: MicrosoftOperationalInsights_workspaces_Arm_ResourceName
    MicrosoftOperationalInsights_workspaces_Arm_Location: MicrosoftOperationalInsights_workspaces_Arm_Location
  }
}

// NOTE: Bicep/ARM will lowercase the initial letter for all output variable names
output out_AzAppService_CustomDomainVerification string = MicrosoftWeb_sites_Module.outputs.out_CustomDomainVerificationId

output out_WebHost_IpAddress string = MicrosoftWeb_sites_Module.outputs.out_WebHost_IpAddress
