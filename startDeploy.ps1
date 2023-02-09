<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

 #>

param (
    [Parameter()]
    [string]
    $ResourceGroupName,

    [Parameter()]
    [int]
    $CdphResourceInstance = 1,

    [Parameter()]
    [string]
    $MainSiteResourceLocation = 'eastus',
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
    
    [Parameter()]
    [string]
    $StorageResourceLocation = 'westus'
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
)

Set-StrictMode -Version Latest 

$env:NO_COLOR = '_' # used during testing in Windows Server 2012; remove for all others

if ($PSBoundParameters.ContainsKey('ResourceGroupName'))
{
    $rgName = $ResourceGroupName
}
else
{
    $rgName = Read-Host -Prompt 'Resource Group Name (see https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftresources)'
}
[securestring] $mySqlAdminPassword = Read-Host -Prompt 'MySQL Administrator Password' -AsSecureString
[securestring] $redcapCommunityPassword = Read-Host -Prompt 'REDCap Community Password' -AsSecureString
[securestring] $smtpPassword = Read-Host -Prompt 'SMTP Password' -AsSecureString

$deployArgs = @{
    Arm_ResourceGroupName                       = $rgName
    Arm_MainSiteResourceLocation                = $MainSiteResourceLocation
    Arm_StorageResourceLocation                 = $StorageResourceLocation
    Cdph_ResourceInstance                       = $CdphResourceInstance
    DatabaseForMySql_AdministratorLoginPassword = $mySqlAdminPassword
    ProjectRedcap_CommunityPassword             = $redcapCommunityPassword
    Smtp_UserPassword                           = $smtpPassword
}

.\redcapAzureDeploy.ps1 @deployArgs
