// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------
@description('CDPH Owner')
@allowed([
  'ITSD'
  'CDPH'
])
param Cdph_Organization string = 'ITSD'

@description('CDPH Business Unit (numbers & digits only)')
@minLength(2)
@maxLength(5)
param Cdph_BusinessUnit string = 'ESS'

@description('CDPH Business Unit Program (numbers & digits only)')
@minLength(2)
@maxLength(7)
param Cdph_BusinessUnitProgram string = 'RedCap'

@description('Targeted deployment environment')
@maxLength(4)
@minLength(1)
@allowed([
  'Dev'
  'Test'
  'Prod'
])
param Cdph_Environment string = 'Dev'

@description('Instance number (when deploying multiple instances of this template into one environment)')
@minValue(1)
@maxValue(99)
param Cdph_ResourceInstance int = 1

// @description('Client IP address (IPv4 or IPv6) to allow access to the application. Default = \'\' (empty string); If empty, access will be allowed from anywhere. NOTE: This needs to be a valid IP address. If you want to allow access from anywhere, use \'*\' (asterisk).')
@description('Client IP address (IPv4 or IPv6) to allow access to the application for this script.')
@minLength(7)
@maxLength(45)
param Cdph_ClientIPAddress string

@description('Key Vault resource name (must be globally unique). Use the CdphNaming.psm1 PowerShell module to generate a unique name.')
@minLength(3)
@maxLength(24)
param Cdph_KeyVaultResourceName string

/* 
@description('Thumbprint for SSL SNI server certificate. A custom domain name is a required part of this template.')
@minLength(40)
@maxLength(40)
param Cdph_SslCertificateThumbprint string
 */

// General Azure Resource Manager parameters
// -----------------------------------------

/*
Get current list of all possible locations for your subscription:
  PowerShell: 
    $locations = Get-AzLocation -ExtendedLocation:$true
    $locations | ? RegionType -eq 'Physical' | ? PhysicalLocation | ft
  AZ CLI: 
    az account list-locations

Get current list of all possible SKUs for a specific resource type in a specific location:
  PowerShell:
    Storage Account
    App Service Plan
    Database for MySQL Flexible Server
      
Locations list for public cloud, non-US locations reference:
  'australiacentral'
  'australiacentral2'
  'australiaeast'
  'australiasoutheast'
  'brazilsouth'
  'brazilsoutheast'
  'canadacentral'
  'canadaeast'
  'centralindia'
  'eastasia'
  'francecentral'
  'francesouth'
  'germanynorth'
  'germanywestcentral'
  'japaneast'
  'japanwest'
  'jioindiacentral'
  'jioindiawest'
  'koreacentral'
  'koreasouth'
  'northeurope'
  'norwayeast'
  'norwaywest'
  'qatarcentral'
  'southafricanorth'
  'southafricawest'
  'southeastasia'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'switzerlandwest'
  'uaecentral'
  'uaenorth'
  'uksouth'
  'ukwest'
  'westeurope'
  'westindia'

*/

@description('Location where most resources (website, database) will be deployed')
@allowed([
  // values for US in public cloud
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
  'westus3'
])
param Arm_MainSiteResourceLocation string = 'eastus'

/* 
@description('Location where resources will be deployed')
@allowed([
  // values for US in public cloud
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
  'westus3'
])
param Arm_StorageResourceLocation string = 'westus'
 */

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

@description('Administrator object ID (GUID) for the Azure Active Directory user or group that will be granted access to the Key Vault. Default = current user')
param Arm_AdministratorObjectId string


// =========
// VARIABLES
// =========

var clientIpAddressCidr = Cdph_ClientIPAddress == '' ? '' : '${Cdph_ClientIPAddress}/32'

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

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: Cdph_KeyVaultResourceName
  location: Arm_MainSiteResourceLocation
  tags: cdph_CommonTags
  properties: {
    accessPolicies: [] // required, and will be updated by redcapAzureDeployMain.bicep
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: false
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: clientIpAddressCidr
        }
      ]
    }
    sku: {
      name: 'standard'
      family: 'A'
    }
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
