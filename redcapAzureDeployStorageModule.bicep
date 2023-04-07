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

// Storage Account parameters
// --------------------------

@description('Settings for the Storage Account resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftStorage_storageAccounts_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Azure Storage Account variables
// -------------------------------

var storageAccount_ResourceName = MicrosoftStorage_storageAccounts_Arguments.Arm_ResourceName

var hasEnvironment = contains(MicrosoftStorage_storageAccounts_Arguments.byEnvironment, Cdph_Environment)
var thisEnvironment = hasEnvironment ? MicrosoftStorage_storageAccounts_Arguments.byEnvironment[Cdph_Environment] : null
var hasEnvironmentAll = contains(MicrosoftStorage_storageAccounts_Arguments.byEnvironment, 'ALL')
var allEnvironments = hasEnvironmentAll ? MicrosoftStorage_storageAccounts_Arguments.byEnvironment.ALL : null

var argument_Arm_Location = 'Arm_Location'
var storageAccount_Location = (hasEnvironment ? (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) : null) ?? (hasEnvironmentAll ? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null) : null)

var argument_Redundancy = 'Redundancy'
var storageAccount_Redundancy = (hasEnvironment ? (contains(thisEnvironment, argument_Redundancy) ? thisEnvironment[argument_Redundancy] : null) : null) ?? (hasEnvironmentAll ? (contains(allEnvironments, argument_Redundancy) ? allEnvironments[argument_Redundancy] : null) : null)

var argument_ContainerName = 'ContainerName'
var storageAccount_ContainerName = (hasEnvironment ? (contains(thisEnvironment, argument_ContainerName) ? thisEnvironment[argument_ContainerName] : null) : null) ?? (hasEnvironmentAll ? (contains(allEnvironments, argument_ContainerName) ? allEnvironments[argument_ContainerName] : null) : null)

// =========
// RESOURCES
// =========

// Azure Storage Account
// ---------------------

resource storageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccount_ResourceName
  location: storageAccount_Location
  sku: {
    name: storageAccount_Redundancy
  }
  kind: 'StorageV2'
  tags: Cdph_CommonTags

  resource storageAccount_Blob_Resource 'blobServices' = {
    name: 'default'

    resource storageAccount_Blob_Container_Resource 'containers' = {
      name: storageAccount_ContainerName }
  }
}
