// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arm_Location string

param MicrosoftWeb_serverfarms_Arm_ResourceName string

param MicrosoftWeb_serverfarms_Capacity int

param MicrosoftWeb_serverfarms_Sku string

param MicrosoftWeb_serverfarms_Tier string

// =========
// VARIABLES
// =========

// =========
// RESOURCES
// =========

// Azure App Services
// ------------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: MicrosoftWeb_serverfarms_Arm_ResourceName
  location: MicrosoftWeb_serverfarms_Arm_Location
  tags: Cdph_CommonTags
  sku: {
    tier: MicrosoftWeb_serverfarms_Tier
    name: MicrosoftWeb_serverfarms_Sku
    capacity: MicrosoftWeb_serverfarms_Capacity
  }
  kind: 'app,linux' // see https://stackoverflow.com/a/62400396/100596 for acceptable values
  properties: {
    reserved: true
  }
}

