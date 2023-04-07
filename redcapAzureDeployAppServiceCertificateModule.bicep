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

// Key Vault parameters
// --------------------

param KeyVault_ResourceName string

// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arguments object

// App Service parameters
// ----------------------

param MicrosoftWeb_sites_Arguments object

// App Service Certificate parameters
// ----------------------------------

param MicrosoftWeb_certificates_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// App Service Plan variables
// --------------------------

var appServicePlan_ResourceName = MicrosoftWeb_serverfarms_Arguments.Arm_ResourceName

// App Service variables
// ---------------------

var appService_WebHost_ResourceName = MicrosoftWeb_sites_Arguments.Arm_ResourceName

// App Service Certificates variables
// ----------------------------------

var appService_Certificates_ResourceName = MicrosoftWeb_certificates_Arguments.Arm_ResourceName

var hasMicrosoftWeb_certificates_ArgumentsEnvironment = contains(MicrosoftWeb_certificates_Arguments.byEnvironment, Cdph_Environment)
var thisMicrosoftWeb_certificates_ArgumentsEnvironment = hasMicrosoftWeb_certificates_ArgumentsEnvironment ? MicrosoftWeb_certificates_Arguments.byEnvironment[Cdph_Environment] : null
var hasMicrosoftWeb_certificates_ArgumentsEnvironmentAll = contains(MicrosoftWeb_certificates_Arguments.byEnvironment, 'ALL')
var allMicrosoftWeb_certificates_ArgumentsEnvironments = hasMicrosoftWeb_certificates_ArgumentsEnvironmentAll ? MicrosoftWeb_certificates_Arguments.byEnvironment.ALL : null

var argument_Arm_Location = 'Arm_Location'
var appService_Certificates_Location =  (hasMicrosoftWeb_certificates_ArgumentsEnvironment ? (contains(thisMicrosoftWeb_certificates_ArgumentsEnvironment, argument_Arm_Location) ? thisMicrosoftWeb_certificates_ArgumentsEnvironment[argument_Arm_Location] : null) : null) ?? (hasMicrosoftWeb_certificates_ArgumentsEnvironmentAll ? (contains(allMicrosoftWeb_certificates_ArgumentsEnvironments, argument_Arm_Location) ? allMicrosoftWeb_certificates_ArgumentsEnvironments[argument_Arm_Location] : null) : null)

var hasMicrosoftWeb_sites_ArgumentsEnvironment = contains(MicrosoftWeb_sites_Arguments.byEnvironment, Cdph_Environment)
var thisMicrosoftWeb_sites_ArgumentsEnvironment = hasMicrosoftWeb_sites_ArgumentsEnvironment ? MicrosoftWeb_sites_Arguments.byEnvironment[Cdph_Environment] : null
var hasMicrosoftWeb_sites_ArgumentsEnvironmentAll = contains(MicrosoftWeb_sites_Arguments.byEnvironment, 'ALL')
var allMicrosoftWeb_sites_ArgumentsEnvironments = hasMicrosoftWeb_sites_ArgumentsEnvironmentAll ? MicrosoftWeb_sites_Arguments.byEnvironment.ALL : null

var argument_CustomFullyQualifiedDomainName = 'CustomFullyQualifiedDomainName'
var appService_WebHost_CustomFullyQualifiedDomainName =  (hasMicrosoftWeb_sites_ArgumentsEnvironment ? (contains(thisMicrosoftWeb_sites_ArgumentsEnvironment, argument_CustomFullyQualifiedDomainName) ? thisMicrosoftWeb_sites_ArgumentsEnvironment[argument_CustomFullyQualifiedDomainName] : null) : null) ?? (hasMicrosoftWeb_sites_ArgumentsEnvironmentAll ? (contains(allMicrosoftWeb_sites_ArgumentsEnvironments, argument_CustomFullyQualifiedDomainName) ? allMicrosoftWeb_sites_ArgumentsEnvironments[argument_CustomFullyQualifiedDomainName] : null) : null)

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: KeyVault_ResourceName
}

// App Service Plan
// ----------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appServicePlan_ResourceName
}

// App Service
// -----------

resource appService_WebHost_Resource 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appService_WebHost_ResourceName
}

// App Service Certificates
// ------------------------

resource appService_Certificates_Resource 'Microsoft.Web/certificates@2022-03-01' = {
  name: appService_Certificates_ResourceName
  location: appService_Certificates_Location
  tags: Cdph_CommonTags
  properties: {
    hostNames: [
      appService_WebHost_CustomFullyQualifiedDomainName
    ]
    keyVaultId: keyVault_Resource.id
    keyVaultSecretName: appService_WebHost_Resource.name
    serverFarmId: appService_Plan_Resource.id
  }
}

