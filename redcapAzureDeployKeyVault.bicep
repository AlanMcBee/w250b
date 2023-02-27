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
@maxLength(5)
@minLength(2)
param Cdph_BusinessUnit string = 'ESS'

@description('CDPH Business Unit Program (numbers & digits only)')
@maxLength(7)
@minLength(2)
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

// ARM variables
// -------------

// Make instance number into a zero-prefixed string exactly 2 digits long
var arm_ResourceInstance_ZeroPadded = padLeft(Cdph_ResourceInstance, 2, '0')

// Key Vault variables
// -------------------

var orgLength = length(Cdph_Organization)
var unitLength = length(Cdph_BusinessUnit)
var programLength = length(Cdph_BusinessUnitProgram)
var envLength = length(Cdph_Environment)
var minBaseLength = length('kv00') + 4 // 'kv' + 2-digit instance + 4 hyphens
var maxKeyVaultNameLength = 24
var inputNameLength = orgLength + unitLength + programLength + envLength
var inputOverBaseLength = inputNameLength + minBaseLength
var isOneOverMax = (inputOverBaseLength - 1) == maxKeyVaultNameLength // if one over, will just remove the last hyphen
var isOverMax = (inputOverBaseLength - 1) > maxKeyVaultNameLength // if over, will remove the last hyphen anyway
var lastHyphen = (isOneOverMax || isOverMax) ? '-' : ''
var lengthOverMax = isOverMax ? (inputOverBaseLength - 1) - maxKeyVaultNameLength : 0 // adjust for the removed hyphen
var newProgramLength = programLength - lengthOverMax
var newProgram = substring(Cdph_BusinessUnitProgram, 0, newProgramLength)
var keyVault_ResourceName = 'kv-${Cdph_Organization}-${Cdph_BusinessUnit}-${newProgram}-${Cdph_Environment}${lastHyphen}${arm_ResourceInstance_ZeroPadded}'

// =========
// RESOURCES
// =========

// Azure Key Vault
// ---------------

resource keyVault_Resource 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVault_ResourceName
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
          value: Cdph_ClientIPAddress
        }
      ]
    }
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
  }

  resource keyVault_AccessPolicies_Resource 'accessPolicies' = {
    name: 'add'
    properties: {
      accessPolicies: [
        {
          tenantId: subscription().tenantId
          applicationId: '1950a258-227b-4e31-a9cf-717495945fc2'
          objectId: '887235fb-6466-474f-a7f8-d3e55b4466d1'
          permissions: {
            certificates: [
              'import'
            ]
          }
        }
      ]
    }
  }
}

// =======
// OUTPUTS
// =======

output Out_KeyVault_ResourceName string = keyVault_ResourceName
