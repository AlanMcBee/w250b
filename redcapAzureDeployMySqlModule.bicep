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

var databaseForMySql_Location = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].Arm_Location ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.Arm_Location

var databaseForMySql_AdministratorLoginName = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].AdministratorLoginName ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.AdministratorLoginName

var databaseForMySql_DatabaseName = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].DatabaseName ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.DatabaseName

var databaseForMySql_Tier = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].Tier ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.Tier

var databaseForMySql_Sku = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].Sku ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.Sku

var databaseForMySql_StorageGB = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].StorageGB ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.StorageGB

var databaseForMySQL_BackupRetentionDays = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].BackupRetentionDays ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.BackupRetentionDays

var databaseForMySql_FirewallRules = MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment[Cdph_Environment].FirewallRules ?? MicrosoftDBforMySQL_flexibleServers_Arguments.byEnvironment.ALL.FirewallRules

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
