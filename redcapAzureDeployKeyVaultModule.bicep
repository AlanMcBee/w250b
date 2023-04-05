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

@description('Arguments for the Key Vault resource.')
param MicrosoftKeyVault_vaults_Arguments object

@description('Secure settings for the Key Vault resource.')
@secure()
param MicrosoftKeyVault_vaults_SecureArguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Key Vault variables
// -------------------

var keyVault_ResourceName = MicrosoftKeyVault_vaults_Arguments.Arm_ResourceName

var keyVault_ResourceLocation = contains(MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment], 'Arm_Location') ? MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment].Arm_Location : MicrosoftKeyVault_vaults_Arguments.byEnvironment.ALL.Arm_Location

var keyVault_Arm_AdministratorObjectId = contains(MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment], 'Arm_AdministratorObjectId') ? MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment].Arm_AdministratorObjectId : MicrosoftKeyVault_vaults_Arguments.byEnvironment.ALL.Arm_AdministratorObjectId

var keyVault_NetworkAcls_IpRules = contains(MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment], 'NetworkAcls_IpRules') ? MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment].NetworkAcls_IpRules : MicrosoftKeyVault_vaults_Arguments.byEnvironment.ALL.NetworkAcls_IpRules

var MicrosoftDBforMySQLAdministratorLoginPassword = MicrosoftKeyVault_vaults_SecureArguments.MicrosoftDBforMySQLAdministratorLoginPassword

var ProjectREDCapCommunityPassword = MicrosoftKeyVault_vaults_SecureArguments.ProjectREDCapCommunityPassword

var SmtpUserPassword = MicrosoftKeyVault_vaults_SecureArguments.SmtpUserPassword

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVault_ResourceName
  location: keyVault_ResourceLocation
  tags: Cdph_CommonTags
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: keyVault_Arm_AdministratorObjectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: [
            'get'
            'list'
            'delete'
            'create'
            'import'
            'update'
            'managecontacts'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
            'manageissuers'
            'recover'
            'backup'
            'restore'
          ]
          keys: [
            'get'
            'list'
            'delete'
            'create'
            'import'
            'update'
            'encrypt'
            'decrypt'
            'wrapkey'
            'unwrapkey'
            'sign'
            'verify'
            'backup'
            'restore'
            'recover'
          ]
        }
      }    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: false
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: keyVault_NetworkAcls_IpRules
    }
    publicNetworkAccess: 'Enabled'
    sku: {
      name: 'standard'
      family: 'A'
    }
    softDeleteRetentionInDays: 90
    tenantId: subscription().tenantId
  }

  resource keyVault_Secrets_MySQL_AdministratorLoginPassword_Resource 'secrets' = {
    name: 'MicrosoftDBforMySQLAdministratorLoginPassword-Secret'
    properties: {
      value: MicrosoftDBforMySQLAdministratorLoginPassword
    }
  }

  resource keyVault_Secrets_REDCap_CommunityPassword_Resource 'secrets' = {
    name: 'ProjectREDCapCommunityPassword-Secret'
    properties: {
      value: ProjectREDCapCommunityPassword
    }
  }

  resource keyVault_Secrets_Smtp_UserPassword_Resource 'secrets' = {
    name: 'SmtpUserPassword-Secret'
    properties: {
      value: SmtpUserPassword
    }
  }
}
