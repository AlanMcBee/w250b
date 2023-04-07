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

var thisEnvironment = contains(MicrosoftWeb_certificates_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftWeb_certificates_Arguments.byEnvironment[Cdph_Environment] : null
var allEnvironments = MicrosoftWeb_certificates_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var appService_Certificates_Location =  (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) ?? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null)

var argument_CustomFullyQualifiedDomainName = 'CustomFullyQualifiedDomainName'
var appService_WebHost_CustomFullyQualifiedDomainName =  (contains(thisEnvironment, argument_CustomFullyQualifiedDomainName) ? thisEnvironment[argument_CustomFullyQualifiedDomainName] : null) ?? (contains(allEnvironments, argument_CustomFullyQualifiedDomainName) ? allEnvironments[argument_CustomFullyQualifiedDomainName] : null)

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

