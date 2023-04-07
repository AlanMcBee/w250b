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

// Database for MySQL parameters
// -----------------------------

param MicrosoftDBforMySQL_flexibleServers_Arguments object

@secure()
param DatabaseForMySql_AdministratorLoginPassword string

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

// Database for MySQL variables
// ----------------------------

var databaseForMySql_ResourceName = MicrosoftDBforMySQL_flexibleServers_Arguments.Arm_ResourceName

var thisEnvironment = contains(MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment, Cdph_Environment) ? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment] : null
var allEnvironments = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL

var argument_Arm_Location = 'Arm_Location'
var databaseForMySql_Location = (contains(thisEnvironment, argument_Arm_Location) ? thisEnvironment[argument_Arm_Location] : null) ?? (contains(allEnvironments, argument_Arm_Location) ? allEnvironments[argument_Arm_Location] : null)

var argument_AdministratorLoginName = 'AdministratorLoginName'
var databaseForMySql_AdministratorLoginName = (contains(thisEnvironment, argument_AdministratorLoginName) ? thisEnvironment[argument_AdministratorLoginName] : null) ?? (contains(allEnvironments, argument_AdministratorLoginName) ? allEnvironments[argument_AdministratorLoginName] : null)

var argument_DatabaseName = 'DatabaseName'
var databaseForMySql_DatabaseName = (contains(thisEnvironment, argument_DatabaseName) ? thisEnvironment[argument_DatabaseName] : null) ?? (contains(allEnvironments, argument_DatabaseName) ? allEnvironments[argument_DatabaseName] : null)

var argument_Tier = 'Tier'
var databaseForMySql_Tier = (contains(thisEnvironment, argument_Tier) ? thisEnvironment[argument_Tier] : null) ?? (contains(allEnvironments, argument_Tier) ? allEnvironments[argument_Tier] : null)

var argument_Sku = 'Sku'
var databaseForMySql_Sku = (contains(thisEnvironment, argument_Sku) ? thisEnvironment[argument_Sku] : null) ?? (contains(allEnvironments, argument_Sku) ? allEnvironments[argument_Sku] : null)

var argument_StorageGB = 'StorageGB'
var databaseForMySql_StorageGB = (contains(thisEnvironment, argument_StorageGB) ? thisEnvironment[argument_StorageGB] : null) ?? (contains(allEnvironments, argument_StorageGB) ? allEnvironments[argument_StorageGB] : null)

var argument_BackupRetentionDays = 'BackupRetentionDays'
var databaseForMySQL_BackupRetentionDays = (contains(thisEnvironment, argument_BackupRetentionDays) ? thisEnvironment[argument_BackupRetentionDays] : null) ?? (contains(allEnvironments, argument_BackupRetentionDays) ? allEnvironments[argument_BackupRetentionDays] : null)

var argument_FirewallRules = 'FirewallRules'
var databaseForMySql_FirewallRules = (contains(thisEnvironment, argument_FirewallRules) ? thisEnvironment[argument_FirewallRules] : null) ?? (contains(allEnvironments, argument_FirewallRules) ? allEnvironments[argument_FirewallRules] : null)

var databaseForMySql_HostName = '${databaseForMySql_ResourceName}.mysql.database.azure.com'

var databaseForMySql_FlexibleServer_ConnectionString_parts = [
  'Database=${databaseForMySql_DatabaseName}'
  'Data Source=${databaseForMySql_HostName}'
  'User Id=${databaseForMySql_AdministratorLoginName}'
  'Password=${DatabaseForMySql_AdministratorLoginPassword}'
]
var databaseForMySql_ConnectionString = join(databaseForMySql_FlexibleServer_ConnectionString_parts, '; ')

// =========
// RESOURCES
// =========

// Database for MySQL Flexible Server
// ----------------------------------

resource databaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: databaseForMySql_ResourceName
  location: databaseForMySql_Location
  tags: Cdph_CommonTags
  sku: {
    name: databaseForMySql_Sku
    tier: databaseForMySql_Tier
  }
  properties: {
    administratorLogin: databaseForMySql_AdministratorLoginName
    administratorLoginPassword: DatabaseForMySql_AdministratorLoginPassword
    backup: {
      backupRetentionDays: databaseForMySQL_BackupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    replicationRole: 'None'
    storage: {
      storageSizeGB: databaseForMySql_StorageGB
    }
    version: '8.0.21'
  }

  resource databaseForMySql_FlexibleServer_FirewallRule_Resource 'firewallRules' = [for (firewallRule, index) in items(databaseForMySql_FirewallRules): {
    name: firewallRule.key
    properties: {
      startIpAddress: firewallRule.value.StartIpAddress
      endIpAddress: firewallRule.value.EndIpAddress
    }
  }]

  resource databaseForMySql_FlexibleServer_RedCapDb_Resource 'databases' = {
    name: databaseForMySql_DatabaseName
    properties: {
      charset: 'utf8'
      collation: 'utf8_general_ci'
    }
  }
}

output out_DatabaseForMySql_HostName string = databaseForMySql_HostName
output out_DatabaseForMySql_ConnectionString string = databaseForMySql_ConnectionString
