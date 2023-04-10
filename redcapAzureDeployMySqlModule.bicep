// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

// CDPH-specific parameters
// ------------------------

param Cdph_CommonTags object

// Database for MySQL parameters
// -----------------------------

param MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName string

@secure()
param MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword string

param MicrosoftDBforMySQL_flexibleServers_Arm_Location string

param MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName string

param MicrosoftDBforMySQL_flexibleServers_Backup_BackupRetentionDays int

param MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name string

param MicrosoftDBforMySQL_flexibleServers_FirewallRules array

param MicrosoftDBforMySQL_flexibleServers_Sku_Name string

param MicrosoftDBforMySQL_flexibleServers_Sku_Tier string

param MicrosoftDBforMySQL_flexibleServers_Storage_StorageSizeGB int

// =========
// VARIABLES
// =========

// Database for MySQL variables
// ----------------------------

var MicrosoftDBforMySQL_flexibleServers_HostName = '${MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName}.mysql.database.azure.com'

var connectionString_parts = [
  'Database=${MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name}'
  'Data Source=${MicrosoftDBforMySQL_flexibleServers_HostName}'
  'User Id=${MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName}'
  'Password=${MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword}'
]
var MicrosoftDBforMySQL_flexibleServers_ConnectionString = join(connectionString_parts, '; ')

// =========
// RESOURCES
// =========

// Database for MySQL Flexible Server
// ----------------------------------

resource databaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: MicrosoftDBforMySQL_flexibleServers_Arm_ResourceName
  location: MicrosoftDBforMySQL_flexibleServers_Arm_Location
  tags: Cdph_CommonTags
  sku: {
    name: MicrosoftDBforMySQL_flexibleServers_Sku_Name
    tier: MicrosoftDBforMySQL_flexibleServers_Sku_Tier
  }
  properties: {
    administratorLogin: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginName
    administratorLoginPassword: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword
    backup: {
      backupRetentionDays: MicrosoftDBforMySQL_flexibleServers_Backup_BackupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    replicationRole: 'None'
    storage: {
      storageSizeGB: MicrosoftDBforMySQL_flexibleServers_Storage_StorageSizeGB
    }
    version: '8.0.21'
  }

  resource databaseForMySql_FlexibleServer_FirewallRule_Resource 'firewallRules' = [for (firewallRule, index) in MicrosoftDBforMySQL_flexibleServers_FirewallRules: {
    name: firewallRule.key
    properties: {
      startIpAddress: firewallRule.value.StartIpAddress
      endIpAddress: firewallRule.value.EndIpAddress
    }
  }]

  resource databaseForMySql_FlexibleServer_RedCapDb_Resource 'databases' = {
    name: MicrosoftDBforMySQL_flexibleServers_Databases_RedCapDB_Name
    properties: {
      charset: 'utf8'
      collation: 'utf8_general_ci'
    }
  }
}

output out_MicrosoftDBforMySQL_flexibleServers_HostName string = MicrosoftDBforMySQL_flexibleServers_HostName
output out_MicrosoftDBforMySQL_flexibleServers_ConnectionString string = MicrosoftDBforMySQL_flexibleServers_ConnectionString
