// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Application Insights parameters
// -------------------------------

param enableDeployment_ApplicationInsights bool

// Log Analytics parameters

param MicrosoftOperationalInsights_workspaces_Arm_Location string

param MicrosoftOperationalInsights_workspaces_Arm_ResourceName string

// =========
// VARIABLES
// =========

// =========
// RESOURCES
// =========

resource logAnalytics_Workspace_Resource 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableDeployment_ApplicationInsights) {
  name: MicrosoftOperationalInsights_workspaces_Arm_ResourceName
  location: MicrosoftOperationalInsights_workspaces_Arm_Location
  tags: Cdph_CommonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}
