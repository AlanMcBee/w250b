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

var thisEnvironment = contains(MicrosoftWeb_serverfarms_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftWeb_serverfarms_Arguments.byEnvironment[Cdph_Environment] : null
var allEnvironments = MicrosoftWeb_serverfarms_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var appServicePlan_Location = (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) ?? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null)

var argument_Tier = 'Tier'
var appServicePlan_Tier = (contains(thisEnvironment, argument_Tier) ? thisEnvironment[argument_Tier] : null) ?? (contains(allEnvironments, argument_Tier) ? allEnvironments[argument_Tier] : null)

var argument_SkuName = 'SkuName'
var appServicePlan_SkuName = (contains(thisEnvironment, argument_SkuName) ? thisEnvironment[argument_SkuName] : null) ?? (contains(allEnvironments, argument_SkuName) ? allEnvironments[argument_SkuName] : null)

var argument_Capacity = 'Capacity'
var appServicePlan_Capacity = (contains(thisEnvironment, argument_Capacity) ? thisEnvironment[argument_Capacity] : null) ?? (contains(allEnvironments, argument_Capacity) ? allEnvironments[argument_Capacity] : null)



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

