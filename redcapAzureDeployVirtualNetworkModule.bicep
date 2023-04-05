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

// Virtual Network parameters
// --------------------------
@description('Settings for the Virtual Network resource. See the ReadMe.md file and the redcapAzureDeploy.parameters.json file for more information')
param MicrosoftNetwork_virtualNetworks_Arguments object

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Virtual Network variables
// -------------------------

var virtualNetwork_ResourceName = MicrosoftNetwork_virtualNetworks_Arguments.Arm_ResourceName

var virtualNetwork_Location = MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment.ALL.Arm_Location

var virtualNetwork_DnsServers = MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment[Cdph_Environment].DnsServers ?? MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment.ALL.DnsServers

var virtualNetwork_AddressSpace = MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment[Cdph_Environment].AddressSpace ?? MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment.ALL.AddressSpace

// =========
// RESOURCES
// =========

resource VirtualNetwork_Resource 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: virtualNetwork_ResourceName
  location: virtualNetwork_Location
  tags: Cdph_CommonTags
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetwork_AddressSpace
    }
    dhcpOptions: {
      dnsServers: virtualNetwork_DnsServers
    }
  }
}
