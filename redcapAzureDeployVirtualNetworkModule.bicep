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

var thisEnvironment = contains(MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment[Cdph_Environment] : null
var allEnvironments = MicrosoftNetwork_virtualNetworks_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var virtualNetwork_Location = (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) ?? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null)

var argument_DnsServers = 'DnsServers'
var virtualNetwork_DnsServers = (contains(thisEnvironment, argument_DnsServers) ? thisEnvironment[argument_DnsServers] : null) ?? (contains(allEnvironments, argument_DnsServers) ? allEnvironments[argument_DnsServers] : null)

var argument_AddressSpace = 'AddressSpace'
var virtualNetwork_AddressSpace = (contains(thisEnvironment, argument_AddressSpace) ? thisEnvironment[argument_AddressSpace] : null) ?? (contains(allEnvironments, argument_AddressSpace) ? allEnvironments[argument_AddressSpace] : null)


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
