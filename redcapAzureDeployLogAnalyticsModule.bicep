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

// Application Insights parameters
// -------------------------------

param MicrosoftInsights_components_Arguments object

// Log Analytics parameters

param MicrosoftOperationalInsights_workspaces_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Application Insights variables
// ------------------------------

var thisMicrosoftInsights_components_ArgumentsEnvironment = contains(MicrosoftInsights_components_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment] : null
var allMicrosoftInsights_components_ArgumentsEnvironments = MicrosoftInsights_components_Arguments.byEnvironment.ALL

var argument_enabled = 'enabled'
var applicationInsights_Enabled = (contains(thisMicrosoftInsights_components_ArgumentsEnvironment, argument_enabled) ? thisMicrosoftInsights_components_ArgumentsEnvironment[argument_enabled] : null) ?? (contains(allMicrosoftInsights_components_ArgumentsEnvironments, argument_enabled) ? allMicrosoftInsights_components_ArgumentsEnvironments[argument_enabled] : null)

// Log Analytics variables
// -----------------------

var logAnalytics_Workspace_ResourceName = MicrosoftOperationalInsights_workspaces_Arguments.Arm_ResourceName

var thisMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment = contains(MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment[Cdph_Environment] : null
var allMicrosoftOperationalInsights_workspaces_ArgumentsEnvironments = MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var logAnalytics_Workspace_Location = (contains(thisMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment, argument_Arm_Location) ? thisMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment[argument_Arm_Location] : null) ?? (contains(allMicrosoftOperationalInsights_workspaces_ArgumentsEnvironments, argument_Arm_Location) ? allMicrosoftOperationalInsights_workspaces_ArgumentsEnvironments[argument_Arm_Location] : null)

// =========
// RESOURCES
// =========

resource logAnalytics_Workspace_Resource 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (applicationInsights_Enabled) {
  name: logAnalytics_Workspace_ResourceName
  location: logAnalytics_Workspace_Location
  tags: Cdph_CommonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}
