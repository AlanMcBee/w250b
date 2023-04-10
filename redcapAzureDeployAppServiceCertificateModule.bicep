// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Key Vault parameters
// --------------------

param MicrosoftKeyVault_vaults_Arm_ResourceName string

// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arm_ResourceName string

// App Service parameters
// ----------------------

param MicrosoftWeb_sites_Arm_ResourceName string

param MicrosoftWeb_sites_CustomFullyQualifiedDomainName string

// App Service Certificate parameters
// ----------------------------------

param MicrosoftWeb_certificates_Arm_ResourceName string

param MicrosoftWeb_certificates_Arm_Location string

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: MicrosoftKeyVault_vaults_Arm_ResourceName
}

// App Service Plan
// ----------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: MicrosoftWeb_serverfarms_Arm_ResourceName
}

// App Service
// -----------

resource appService_WebHost_Resource 'Microsoft.Web/sites@2022-03-01' existing = {
  name: MicrosoftWeb_sites_Arm_ResourceName
}

// App Service Certificates
// ------------------------

resource appService_Certificates_Resource 'Microsoft.Web/certificates@2022-03-01' = {
  name: MicrosoftWeb_certificates_Arm_ResourceName
  location: MicrosoftWeb_certificates_Arm_Location
  tags: Cdph_CommonTags
  properties: {
    hostNames: [
      MicrosoftWeb_sites_CustomFullyQualifiedDomainName
    ]
    keyVaultId: keyVault_Resource.id
    keyVaultSecretName: appService_WebHost_Resource.name
    serverFarmId: appService_Plan_Resource.id
  }
}

