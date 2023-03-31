// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

@description('Administrator object ID (GUID) for the Azure Active Directory user or group that will be granted access to the Key Vault. Default = current user')
param Arm_AdministratorObjectId string

// CDPH-specific parameters
// ------------------------
@description('CDPH Business Unit (numbers & digits only)')
@minLength(2)
@maxLength(5)
param Cdph_BusinessUnit string

@description('CDPH Business Unit Program (numbers & digits only)')
@minLength(2)
@maxLength(7)
param Cdph_BusinessUnitProgram string

@description('Targeted deployment environment')
@maxLength(5)
@minLength(1)
@allowed([
  'dev'
  'test'
  'stage'
  'prod'
])
param Cdph_Environment string = 'dev'

// Key Vault parameters
// --------------------

@description('Settings for the Key Vault resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftKeyVault_vaults object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

var cdph_CommonTags = {
  'ACCOUNTABILITY-Business Unit': Cdph_BusinessUnit
  'ACCOUNTABILITY-Cherwell Change Control': '' // TODO: parameterize or remove?
  'ACCOUNTABILITY-Cost Center': '' // TODO: parameterize or remove?
  'ACCOUNTABILITY-Date Created': Arm_DeploymentCreationDateTime
  'ACCOUNTABILITY-Owner': Cdph_BusinessUnit
  'ACCOUNTABILITY-Program': Cdph_BusinessUnitProgram
  'SECURITY-Criticality': '' // TODO: parameterize or remove?
  'SECURITY-Facing': '' // TODO: parameterize or remove?
  ENVIRONMENT: Cdph_Environment
}

// Key Vault variables

var keyVault_ResourceName = MicrosoftKeyVault_vaults.Arm_ResourceName

var keyVault_ResourceLocation = MicrosoftKeyVault_vaults.byEnvironment[Cdph_Environment].Arm_ResourceLocation ?? MicrosoftKeyVault_vaults.byEnvironment.ALL.Arm_ResourceLocation

var keyVault_NetworkAcls_IpRules = MicrosoftKeyVault_vaults.byEnvironment[Cdph_Environment].NetworkAcls_IpRules ?? MicrosoftKeyVault_vaults.byEnvironment.ALL.NetworkAcls_IpRules

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVault_ResourceName
  location: keyVault_ResourceLocation
  tags: cdph_CommonTags
  properties: {
    accessPolicies: [] // required, and will be updated by redcapAzureDeployMain.bicep
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
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

  resource keyVault_AccessPolicies_SystemAdministratorAllPermissions_Resource 'accessPolicies' = {
    name: 'add'
    properties: {
      accessPolicies: [
        {
          tenantId: subscription().tenantId
          objectId: Arm_AdministratorObjectId
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
        }
      ]
    }
  }
}
