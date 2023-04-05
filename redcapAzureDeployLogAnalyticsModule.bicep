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

var applicationInsights_Enabled = MicrosoftInsights_components_Arguments.byEnvironment[Cdph_Environment].enabled ?? MicrosoftInsights_components_Arguments.byEnvironment.ALL.enabled

// Log Analytics variables
// -----------------------

var logAnalytics_Workspace_ResourceName = MicrosoftOperationalInsights_workspaces_Arguments.Arm_ResourceName

var logAnalytics_Workspace_Location = MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftOperationalInsights_workspaces_Arguments.byEnvironment.ALL.Arm_Location

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
