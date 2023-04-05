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

// App Service Plan parameters
// ---------------------------

param MicrosoftWeb_serverfarms_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// App Service Plan variables
// --------------------------

var appServicePlan_ResourceName = MicrosoftWeb_serverfarms_Arguments.Arm_ResourceName

var appServicePlan_Location = MicrosoftWeb_serverfarms_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftWeb_serverfarms_Arguments.byEnvironment.ALL.Arm_Location

var appServicePlan_Tier = MicrosoftWeb_serverfarms_Arguments.byEnvironment[Cdph_Environment].Tier ?? MicrosoftWeb_serverfarms_Arguments.byEnvironment.ALL.Tier

var appServicePlan_SkuName = MicrosoftWeb_serverfarms_Arguments.byEnvironment[Cdph_Environment].SkuName ?? MicrosoftWeb_serverfarms_Arguments.byEnvironment.ALL.SkuName

var appServicePlan_Capacity = MicrosoftWeb_serverfarms_Arguments.byEnvironment[Cdph_Environment].Capacity ?? MicrosoftWeb_serverfarms_Arguments.byEnvironment.ALL.Capacity


// =========
// RESOURCES
// =========

// Azure App Services
// ------------------

resource appService_Plan_Resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlan_ResourceName
  location: appServicePlan_Location
  tags: Cdph_CommonTags
  sku: {
    tier: appServicePlan_Tier
    name: appServicePlan_SkuName
    capacity: appServicePlan_Capacity
  }
  kind: 'app,linux' // see https://stackoverflow.com/a/62400396/100596 for acceptable values
  properties: {
    reserved: true
  }
}

