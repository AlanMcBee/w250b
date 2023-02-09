<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

 #>

param (
    [Parameter()]
    [string]
    $ResourceGroupName
)

Set-StrictMode -Version Latest 

[string] $rgName = Read-Host -Prompt 'Resource Group Name (see https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftresources)'
[string] $resourceLocation = 'westus2'
# Options:
#   centralus
#   eastus
#   eastus2
#   northcentralus
#   southcentralus
#   westcentralus
#   westus
#   westus2
#   westus3
[securestring] $mySqlAdminPassword = Read-Host -Prompt 'MySQL Administrator Password' -AsSecureString
[securestring] $redcapCommunityPassword = Read-Host -Prompt 'REDCap Community Password' -AsSecureString
[securestring] $smtpPassword = Read-Host -Prompt 'SMTP Password' -AsSecureString

$deployArgs = @{
    ResourceGroupName                           = $rgName
    Arm_ResourceLocation                        = $resourceLocation
    DatabaseForMySql_AdministratorLoginPassword = $mySqlAdminPassword
    ProjectRedcap_CommunityPassword             = $redcapCommunityPassword
    Smtp_UserPassword                           = $smtpPassword
}

.\redcapAzureDeploy.ps1 @deployArgs