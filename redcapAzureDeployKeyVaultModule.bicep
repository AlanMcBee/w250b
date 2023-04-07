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

var thisEnvironment = contains(MicrosoftKeyVault_vaults_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftKeyVault_vaults_Arguments.byEnvironment[Cdph_Environment] : null
var allEnvironments = MicrosoftKeyVault_vaults_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var keyVault_ResourceLocation = (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) ?? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null)

var argument_Arm_AdministratorObjectId = 'Arm_AdministratorObjectId'
var keyVault_Arm_AdministratorObjectId = (contains(thisEnvironment, argument_Arm_AdministratorObjectId) ? thisEnvironment[argument_Arm_AdministratorObjectId] : null) ?? (contains(allEnvironments, argument_Arm_AdministratorObjectId) ? allEnvironments[argument_Arm_AdministratorObjectId] : null)

var argument_NetworkAcls_IpRules = 'NetworkAcls_IpRules'
var keyVault_NetworkAcls_IpRules = (contains(thisEnvironment, argument_NetworkAcls_IpRules) ? thisEnvironment[argument_NetworkAcls_IpRules] : null) ?? (contains(allEnvironments, argument_NetworkAcls_IpRules) ? allEnvironments[argument_NetworkAcls_IpRules] : null)


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
