// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

@description('Settings for the Resource Groups resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftResources_resourceGroups_Arguments object

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
param MicrosoftNetwork_virtualNetworks_Arguments object

// Key Vault parameters
// --------------------

@description('Name of the Azure Key Vault resource.')
param MicrosoftKeyVault_vaults_Arm_ResourceName object

// Storage Account parameters
// --------------------------

@description('Settings for the Storage Account resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftStorage_storageAccounts_Arguments object

// Database for MySQL parameters
// -----------------------------

@description('Settings for the Database for MySQL resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftDBforMySQL_flexibleServers_Arguments object

// App Service Plan parameters
// ---------------------------

@description('Settings for the App Service Plan resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftWeb_serverfarms_Arguments object

// App Service parameters
// ----------------------

@description('Settings for the App Service resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftWeb_sites_Arguments object

// App Service Certificate parameters
// ----------------------------------

@description('Settings for the App Service Certificate resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftWeb_certificates_Arguments object

// Application Insights parameters
// -------------------------------

@description('Settings for the Application Insights resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftInsights_components_Arguments object

@description('Settings for the Log Analytics workspace. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftOperationalInsights_workspaces_Arguments object

// REDCap community and download parameters
// ----------------------------------------

@description('Settings for the REDCap community site. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param ProjectREDCap_Arguments object

// SMTP configuration parameters
// -----------------------------

@description('Settings for the SMTP connection. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param Smtp_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

var cdph_CommonTags = CdphCommon_Module.outputs.out_Cdph_CommonTags

// Key Vault variables
// -------------------

var keyVault_ResourceName = MicrosoftKeyVault_vaults_Arm_ResourceName.Arm_ResourceName

// Database for MySQL variables
// ----------------------------

var databaseForMySql_HostName = DatabaseForMySql_FlexibleServer_Module.outputs.out_DatabaseForMySql_HostName
var databaseForMySql_ConnectionString = DatabaseForMySql_FlexibleServer_Module.outputs.out_DatabaseForMySql_ConnectionString

// =========
// RESOURCES
// =========

// No-resources deployment
// -----------------------

module CdphCommon_Module 'redcapAzureDeployCdphModule.bicep' = {
  name: 'Cdph_Common'
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
  name: keyVault_ResourceName
}

resource MicrosoftKeyVault_vaults_Secrets_Resource 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: MicrosoftKeyVault_vaults_Resource
  name: 'MicrosoftDBforMySQLConnectionString-Secret'
  properties: {
    value: databaseForMySql_ConnectionString
  }
}

// Azure Storage Account
// ---------------------

module MicrosoftStorage_storageAccounts_Module 'redcapAzureDeployStorageModule.bicep' = {
  name: 'MicrosoftStorage_storageAccounts'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftStorage_storageAccounts_Arguments: MicrosoftStorage_storageAccounts_Arguments
  }
}

// Database for MySQL Flexible Server
// ----------------------------------

module DatabaseForMySql_FlexibleServer_Module 'redcapAzureDeployMySqlModule.bicep' = {
  name: 'DatabaseForMySql_FlexibleServer'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftDBforMySQL_flexibleServers_Arguments: MicrosoftDBforMySQL_flexibleServers_Arguments
    DatabaseForMySql_AdministratorLoginPassword: MicrosoftKeyVault_vaults_Resource.getSecret('MicrosoftDBforMySQLAdministratorLoginPassword-Secret')
  }
}

// App Service Plan
// ----------------

module MicrosoftWeb_serverfarms_Module 'redcapAzureDeployAppServicePlanModule.bicep' = {
  name: 'MicrosoftWeb_serverfarms'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftWeb_serverfarms_Arguments: MicrosoftWeb_serverfarms_Arguments
  }
}

// App Service
// -----------

module MicrosoftWeb_sites_Module 'redcapAzureDeployAppServiceModule.bicep' = {
  name: 'MicrosoftWeb_sites'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftStorage_storageAccounts_Arguments: MicrosoftStorage_storageAccounts_Arguments
    MicrosoftDBforMySQL_flexibleServers_Arguments: MicrosoftDBforMySQL_flexibleServers_Arguments
    DatabaseForMySql_HostName: databaseForMySql_HostName
    DatabaseForMySql_ConnectionString: databaseForMySql_ConnectionString
    DatabaseForMySql_AdministratorLoginPassword: MicrosoftKeyVault_vaults_Resource.getSecret('MicrosoftDBforMySQLAdministratorLoginPassword-Secret')
    MicrosoftWeb_sites_Arguments: MicrosoftWeb_sites_Arguments
    MicrosoftWeb_serverfarms_Arguments: MicrosoftWeb_serverfarms_Arguments
    MicrosoftWeb_certificates_Arguments: MicrosoftWeb_certificates_Arguments
    MicrosoftInsights_components_Arguments: MicrosoftInsights_components_Arguments
    ProjectREDCap_Arguments: ProjectREDCap_Arguments
    ProjectREDCap_AutomaticDownloadUrlBuilder_CommunityPassword: MicrosoftKeyVault_vaults_Resource.getSecret('ProjectREDCapCommunityPassword-Secret') 
    Smtp_Arguments: Smtp_Arguments
    Smtp_UserPassword: MicrosoftKeyVault_vaults_Resource.getSecret('SmtpUserPassword-Secret')
  }
}

// App Service Certificate
// -----------------------

module MicrosoftWeb_certificates_Module 'redcapAzureDeployAppServiceCertificateModule.bicep' = {
  name: 'MicrosoftWeb_certificates'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    KeyVault_ResourceName: keyVault_ResourceName
    MicrosoftWeb_certificates_Arguments: MicrosoftWeb_certificates_Arguments
    MicrosoftWeb_serverfarms_Arguments: MicrosoftWeb_serverfarms_Arguments
    MicrosoftWeb_sites_Arguments: MicrosoftWeb_sites_Arguments
  }
}

// Application Insights
// --------------------

module MicrosoftInsights_components_Module 'redcapAzureDeployApplicationInsightsModule.bicep' = {
  name: 'MicrosoftInsights_components'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftInsights_components_Arguments: MicrosoftInsights_components_Arguments
    MicrosoftOperationalInsights_workspaces_Arguments: MicrosoftOperationalInsights_workspaces_Arguments
  }
}

// Log Analytics Workspace
// -----------------------

module MicrosoftOperationalInsights_workspaces_Module 'redcapAzureDeployLogAnalyticsModule.bicep' = {
  name: 'MicrosoftOperationalInsights_workspaces'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftInsights_components_Arguments: MicrosoftInsights_components_Arguments
    MicrosoftOperationalInsights_workspaces_Arguments: MicrosoftOperationalInsights_workspaces_Arguments
  }
}

// NOTE: Bicep/ARM will lowercase the initial letter for all output variable names
output out_AzAppService_CustomDomainVerification string = MicrosoftWeb_sites_Module.outputs.out_CustomDomainVerificationId

output out_WebHost_IpAddress string = MicrosoftWeb_sites_Module.outputs.out_WebHost_IpAddress
