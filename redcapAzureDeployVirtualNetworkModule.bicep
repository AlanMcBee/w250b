// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Virtual Network parameters
// --------------------------

param MicrosoftNetwork_virtualNetworks_AddressSpace_AddressPrefixes array

param MicrosoftNetwork_virtualNetworks_Arm_Location string

param MicrosoftNetwork_virtualNetworks_Arm_ResourceName string

param MicrosoftNetwork_virtualNetworks_DhcpOptions_DnsServers array

// =========
// VARIABLES
// =========

// =========
// RESOURCES
// =========

resource VirtualNetwork_Resource 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: MicrosoftNetwork_virtualNetworks_Arm_ResourceName
  location: MicrosoftNetwork_virtualNetworks_Arm_Location
  tags: Cdph_CommonTags
  properties: {
    addressSpace: {
      addressPrefixes: MicrosoftNetwork_virtualNetworks_AddressSpace_AddressPrefixes
    }
    dhcpOptions: {
      dnsServers: MicrosoftNetwork_virtualNetworks_DhcpOptions_DnsServers
    }
  }
}
