// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

// @description('Settings for the Resource Groups resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
// param MicrosoftResources_resourceGroups_Arguments object

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

param MicrosoftKeyVault_vaults_Arm_Location string

param MicrosoftKeyVault_vaults_Arm_AdministratorObjectId string

param MicrosoftKeyVault_vaults_NetworkAcls_IpRules array

// Key Vault secrets parameters
// ----------------------------

@secure()
param MicrosoftKeyVault_vaults_secrets_AdministratorLoginPassword string

@secure()
param MicrosoftKeyVault_vaults_secrets_ProjectREDCapCommunityPassword string

@secure()
param MicrosoftKeyVault_vaults_secrets_SmtpUserPassword string

// Key Vault parameters
// --------------------

// @description('Settings for the Key Vault resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
// param MicrosoftKeyVault_vaults_Arguments object

// @description('Secure settings for the Key Vault resource.')
// @secure()
// param MicrosoftKeyVault_vaults_SecureArguments object

// Virtual Network parameters
// --------------------------
// @description('Settings for the Virtual Network resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
// param MicrosoftNetwork_virtualNetworks_Arguments object

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

module MicrosoftKeyVault_vaults 'redcapAzureDeployKeyVaultModule.bicep' = {
  name: take('${deployment().name}.MicrosoftKeyVault_vaults', 64)
  params: {
    Cdph_CommonTags: cdph_CommonTags
    MicrosoftKeyVault_vaults_Arm_ResourceName: MicrosoftKeyVault_vaults_Arm_ResourceName
    MicrosoftKeyVault_vaults_Arm_Location: MicrosoftKeyVault_vaults_Arm_Location
    MicrosoftKeyVault_vaults_Arm_AdministratorObjectId: MicrosoftKeyVault_vaults_Arm_AdministratorObjectId
    MicrosoftKeyVault_vaults_NetworkAcls_IpRules: MicrosoftKeyVault_vaults_NetworkAcls_IpRules
    MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword: MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword
    MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword: MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword
    MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword: MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
  }
}
