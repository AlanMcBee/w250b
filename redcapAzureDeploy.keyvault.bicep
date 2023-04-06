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

// Key Vault parameters
// --------------------

@description('Settings for the Key Vault resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftKeyVault_vaults_Arguments object

@description('Secure settings for the Key Vault resource.')
@secure()
param MicrosoftKeyVault_vaults_SecureArguments object

// Virtual Network parameters
// --------------------------
@description('Settings for the Virtual Network resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftNetwork_virtualNetworks_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

var cdph_CommonTags = Cdph.outputs.out_Cdph_CommonTags

// =========
// RESOURCES
// =========

// No-resources deployment
// -----------------------

module Cdph 'redcapAzureDeployCdphModule.bicep' = {
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

module MicrosoftKeyVault_vaults 'redcapAzureDeployKeyVaultModule.bicep' = {
  name: 'MicrosoftKeyVault_vaults'
  params: {
    Cdph_CommonTags: cdph_CommonTags
    Cdph_Environment: Cdph_Environment
    MicrosoftKeyVault_vaults_Arguments: MicrosoftKeyVault_vaults_Arguments
    MicrosoftKeyVault_vaults_SecureArguments: MicrosoftKeyVault_vaults_SecureArguments
  }
}

