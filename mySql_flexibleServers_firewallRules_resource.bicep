param name string
param startIPAddress string
param endIPAddress string

resource serverName_variables_firewallRules_copyIndex_name_name 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-05-01' = {
  name: name
  properties: {
    startIpAddress: startIPAddress
    endIpAddress: endIPAddress
  }
}
