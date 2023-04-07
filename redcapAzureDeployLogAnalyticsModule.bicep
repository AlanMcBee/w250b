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

var hasMicrosoftInsights_components_ArgumentsEnvironment = contains(MicrosoftInsights_components_Arguments.byEnvironment, Cdph_Environment)
var thisMicrosoftInsights_components_ArgumentsEnvironment = hasMicrosoftInsights_components_ArgumentsEnvironment ? MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment] : null
var hasMicrosoftInsights_components_ArgumentsEnvironmentAll = contains(MicrosoftInsights_components_Arguments.byEnvironment, 'ALL')
var allMicrosoftInsights_components_ArgumentsEnvironments = hasMicrosoftInsights_components_ArgumentsEnvironmentAll ? MicrosoftInsights_components_Arguments.byEnvironment.ALL : null

var argument_enabled = 'enabled'
var applicationInsights_Enabled = (hasMicrosoftInsights_components_ArgumentsEnvironment ? thisMicrosoftInsights_components_ArgumentsEnvironment[argument_enabled] : null) ?? (hasMicrosoftInsights_components_ArgumentsEnvironmentAll ? allMicrosoftInsights_components_ArgumentsEnvironments[argument_enabled] : null)

// Log Analytics variables
// -----------------------

var logAnalytics_Workspace_ResourceName = MicrosoftOperationalInsights_workspaces_Arguments.Arm_ResourceName

var hasMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment = contains(MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment, Cdph_Environment)
var thisMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment = hasMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment ? MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment[Cdph_Environment] : null
var hasMicrosoftOperationalInsights_workspaces_ArgumentsEnvironmentAll = contains(MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment, 'ALL')
var allMicrosoftOperationalInsights_workspaces_ArgumentsEnvironments = hasMicrosoftOperationalInsights_workspaces_ArgumentsEnvironmentAll ? MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment.ALL : null

var argument_Arm_Location = 'Arm_Location'
var logAnalytics_Workspace_Location = (hasMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment ? thisMicrosoftOperationalInsights_workspaces_ArgumentsEnvironment[argument_Arm_Location] : null) ?? (hasMicrosoftOperationalInsights_workspaces_ArgumentsEnvironmentAll ? allMicrosoftOperationalInsights_workspaces_ArgumentsEnvironments[argument_Arm_Location] : null)

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
