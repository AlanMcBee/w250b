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

var tryEnvironmentSettings = !empty(MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment])

var applicationInsights_Location = tryEnvironmentSettings ? (MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftInsights_components_Arguments.byEnvironment.ALL.Arm_Location) : MicrosoftInsights_components_Arguments.byEnvironment.ALL.Arm_Location

var applicationInsights_Enabled = tryEnvironmentSettings ? (MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment].enabled ?? MicrosoftInsights_components_Arguments.byEnvironment.ALL.enabled) : MicrosoftInsights_components_Arguments.byEnvironment.ALL.enabled

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
