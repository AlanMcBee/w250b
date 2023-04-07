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

var hasEnvironment = contains(MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment, Cdph_Environment)
var thisEnvironment = hasEnvironment ? MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment[Cdph_Environment] : null
var hasEnvironmentAll = contains(MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment, 'ALL')
var allEnvironments = hasEnvironmentAll ? MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment.ALL : null

var argument_Arm_Location = 'Arm_Location'
var virtualNetwork_Location = (hasEnvironment ? (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) : null) ?? (hasEnvironmentAll ? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null) : null)

var argument_DnsServers = 'DnsServers'
var virtualNetwork_DnsServers = (hasEnvironment ? (contains(thisEnvironment, argument_DnsServers) ? thisEnvironment[argument_DnsServers] : null) : null) ?? (hasEnvironmentAll ? (contains(allEnvironments, argument_DnsServers) ? allEnvironments[argument_DnsServers] : null) : null)

var argument_AddressSpace = 'AddressSpace'
var virtualNetwork_AddressSpace = (hasEnvironment ? (contains(thisEnvironment, argument_AddressSpace) ? thisEnvironment[argument_AddressSpace] : null) : null) ?? (hasEnvironmentAll ? (contains(allEnvironments, argument_AddressSpace) ? allEnvironments[argument_AddressSpace] : null) : null)


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
