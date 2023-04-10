// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Storage Account parameters
// --------------------------

param MicrosoftStorage_storageAccounts_Arm_Location string

param MicrosoftStorage_storageAccounts_Arm_ResourceName string

param MicrosoftStorage_storageAccounts_BlobServices_Containers_Name string

param MicrosoftStorage_storageAccounts_Sku_Name string

// =========
// VARIABLES
// =========

// =========
// RESOURCES
// =========

// Azure Storage Account
// ---------------------

resource storageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: MicrosoftStorage_storageAccounts_Arm_ResourceName
  location: MicrosoftStorage_storageAccounts_Arm_Location
  sku: {
    name: MicrosoftStorage_storageAccounts_Sku_Name
  }
  kind: 'StorageV2'
  tags: Cdph_CommonTags

  resource storageAccount_Blob_Resource 'blobServices' = {
    name: 'default'

    resource storageAccount_Blob_Container_Resource 'containers' = {
      name: MicrosoftStorage_storageAccounts_BlobServices_Containers_Name }
  }
}
