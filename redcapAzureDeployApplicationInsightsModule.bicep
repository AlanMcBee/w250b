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
// ------------------------

param MicrosoftOperationalInsights_workspaces_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Log Analytics variables
// -----------------------

var logAnalytics_Workspace_ResourceName = MicrosoftOperationalInsights_workspaces_Arguments.Arm_ResourceName

// Application Insights variables
// ------------------------------

var applicationInsights_ResourceName = MicrosoftInsights_components_Arguments.Arm_ResourceName

var thisEnvironment = contains(MicrosoftInsights_components_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment] : null
var allEnvironments = MicrosoftInsights_components_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var applicationInsights_Location = (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) ?? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null)

var argument_enabled = 'enabled'
var applicationInsights_Enabled = (contains(thisEnvironment, argument_enabled) ? thisEnvironment[argument_enabled] : null) ?? (contains(allEnvironments, argument_enabled) ? allEnvironments[argument_enabled] : null)

// =========
// RESOURCES
// =========

resource logAnalytics_Workspace_Resource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalytics_Workspace_ResourceName
}

resource appInsights_Resource 'Microsoft.Insights/components@2020-02-02' = if (applicationInsights_Enabled) {
  name: applicationInsights_ResourceName
  location: applicationInsights_Location
  tags: Cdph_CommonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics_Workspace_Resource.id
  }
}
