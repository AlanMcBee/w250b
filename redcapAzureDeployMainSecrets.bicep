// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

param KeyVault_ResourceName string

param DatabaseForMySql_ResourceName string

@secure()
param MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword string

@secure()
param ProjectREDCap_CommunityPassword string

@secure()
param Smtp_UserPassword string

resource databaseForMySql_FlexibleServer_Resource 'Microsoft.DBforMySQL/flexibleServers' existing = {
  name: DatabaseForMySql_ResourceName
  properties: {
    administratorLoginPassword: MicrosoftDBforMySQL_flexibleServers_AdministratorLoginPassword
  }
}
