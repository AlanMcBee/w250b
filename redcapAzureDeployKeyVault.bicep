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

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

// Key Vault parameters
// --------------------

// No Key Vault parameters required

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

var keyVault_ResourceName = 'kv-${Cdph_Organization}-${Cdph_BusinessUnit}-${Cdph_BusinessUnitProgram}-${Cdph_Environment}-${arm_ResourceInstance_ZeroPadded}'

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
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    enableRbacAuthorization: false
  }

// =======
// OUTPUTS
// =======

output KeyVault_ResourceName string = keyVault_ResourceName
