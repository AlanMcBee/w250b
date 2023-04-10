// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Log Analytics parameters
// ------------------------

param MicrosoftOperationalInsights_workspaces_Arm_ResourceName string

// Application Insights parameters
// -------------------------------

param enableDeployment_ApplicationInsights bool

param MicrosoftInsights_components_Arm_ResourceName string

param MicrosoftInsights_components_Arm_Location string

// =========
// RESOURCES
// =========

resource logAnalytics_Workspace_Resource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: MicrosoftOperationalInsights_workspaces_Arm_ResourceName
}

resource appInsights_Resource 'Microsoft.Insights/components@2020-02-02' = if (enableDeployment_ApplicationInsights) {
  name: MicrosoftInsights_components_Arm_ResourceName
  location: MicrosoftInsights_components_Arm_Location
  tags: Cdph_CommonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics_Workspace_Resource.id
  }
}
