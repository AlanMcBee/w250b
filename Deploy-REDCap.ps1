<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
 #>

param (
    # Optional Azure resource group name. If not specified, a default name will be used based on the parameters.json file and the instance number.
    [Parameter()]
    [string]
    $ResourceGroupName,

    # Optional CDPH resource instance number to allow multiple deployments to the same subscription. If not specified, the default value of 1 will be used.
    [Parameter()]
    [int]
    $CdphResourceInstance = 1,

    # Azure region for the main site. Options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
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

    # Azure region for the storage account. Options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
    [Parameter()]
    [string]
    $StorageResourceLocation = 'westus',
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

    # Path to PFX certificate
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]
    $PfxCertificatePath,

    # Password for PFX certificate. Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $PfxCertificatePassword,

    # Password for MySQL administrator. Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $MySqlAdminPassword,

    # Password for REDCap Community. Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $RedcapCommunityPassword,

    # Password for SMTP server. Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $SmtpPassword
)

Set-StrictMode -Version Latest

$keyVaultDeployArgs = @{
    Arm_ResourceGroupName        = $ResourceGroupName
    Arm_MainSiteResourceLocation = $MainSiteResourceLocation
    Cdph_ResourceInstance        = $CdphResourceInstance
    PfxCertificatePath           = $PfxCertificatePath
    PfxCertificatePassword       = $PfxCertificatePassword
}
.\Deploy-REDCapKeyVault.ps1 @keyVaultDeployArgs


$mainDeployArgs = @{
    Arm_ResourceGroupName                       = $ResourceGroupName
    Arm_MainSiteResourceLocation                = $MainSiteResourceLocation
    Arm_StorageResourceLocation                 = $StorageResourceLocation
    Cdph_ResourceInstance                       = $CdphResourceInstance
    DatabaseForMySql_AdministratorLoginPassword = $mySqlAdminPassword
    ProjectRedcap_CommunityPassword             = $redcapCommunityPassword
    Smtp_UserPassword                           = $smtpPassword
}
.\Deploy-REDCapMain.ps1 @deployArgs
