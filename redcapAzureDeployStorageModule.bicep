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

var storageAccount_Location = MicrosoftStorage_storageAccounts_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftStorage_storageAccounts_Arguments.byEnvironment.ALL.Arm_Location

var storageAccount_Redundancy = MicrosoftStorage_storageAccounts_Arguments.byEnvironment[Cdph_Environment].Redundancy ?? MicrosoftStorage_storageAccounts_Arguments.byEnvironment.ALL.Redundancy

var storageAccount_ContainerName = MicrosoftStorage_storageAccounts_Arguments.byEnvironment[Cdph_Environment].ContainerName ?? MicrosoftStorage_storageAccounts_Arguments.byEnvironment.ALL.ContainerName

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
