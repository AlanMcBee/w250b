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

param MicrosoftKeyVault_vaults_Arm_AdministratorObjectId string

param MicrosoftKeyVault_vaults_Arm_Location string

param MicrosoftKeyVault_vaults_Arm_ResourceName string

param MicrosoftKeyVault_vaults_NetworkAcls_IpRules array

// Key Vault secrets parameters
// ----------------------------

@secure()
param MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword string

@secure()
param MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword string

@secure()
param MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword string

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: MicrosoftKeyVault_vaults_Arm_ResourceName
  location: MicrosoftKeyVault_vaults_Arm_Location
  tags: Cdph_CommonTags
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: MicrosoftKeyVault_vaults_Arm_AdministratorObjectId
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
      ipRules: MicrosoftKeyVault_vaults_NetworkAcls_IpRules 
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
      value: MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword
    }
  }

  resource keyVault_Secrets_REDCap_CommunityPassword_Resource 'secrets' = {
    name: 'ProjectREDCapCommunityPassword-Secret'
    properties: {
      value: MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword
    }
  }

  resource keyVault_Secrets_Smtp_UserPassword_Resource 'secrets' = {
    name: 'SmtpUserPassword-Secret'
    properties: {
      value: MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword
    }
  }
}
