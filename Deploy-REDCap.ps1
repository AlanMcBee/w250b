<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCap.ps1
 #>
using namespace Microsoft.Azure.Commands.KeyVault.Models

param (
    # Optional Azure resource group name. If not specified, a default name will be used based on the parameters.json file and the instance number.
    [Parameter()]
    [string]
    $Arm_ResourceGroupName,

    # Azure region for the main site. 
    # Basic options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
    # Full list of regions can be found here: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies
    # Not all resources are available in all regions.
    [Parameter()]
    [ValidateSet(
        'centralus',
        'eastus',
        'eastus2',
        'northcentralus',
        'southcentralus',
        'westcentralus',
        'westus',
        'westus2',
        'westus3'
    )]    
    [string]
    $Arm_MainSiteResourceLocation = 'eastus',

    # Azure region for the storage account. 
    # Basic options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
    # Full list of regions can be found here: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies
    # Not all resources are available in all regions.
    [Parameter()]
    [ValidateSet(
        'centralus',
        'eastus',
        'eastus2',
        'northcentralus',
        'southcentralus',
        'westcentralus',
        'westus',
        'westus2',
        'westus3'
    )]    
    [string]
    $Arm_StorageResourceLocation = 'westus',

    # Optional CDPH resource instance number to allow multiple deployments to the same subscription. If not specified, the default value of 1 will be used.
    [Parameter()]
    [int]
    $Cdph_ResourceInstance = 1,

    # Path to PFX certificate file to upload to Key Vault for App Service SSL binding
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]
    $Cdph_PfxCertificatePath,

    # Password for PFX certificate file
    [Parameter(Mandatory = $true)]
    [securestring]
    $Cdph_PfxCertificatePassword,

    # Client IP address to allow access to Key Vault
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')]
    [string]
    $Cdph_ClientIPAddress,
    
    # Password for MySQL administrator account
    # Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $DatabaseForMySql_AdministratorLoginPassword,

    # Password for REDCap Community.
    # Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $ProjectRedcap_CommunityPassword,

    # Password for SMTP server.
    # Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $Smtp_UserPassword
)

Set-StrictMode -Version Latest

$keyVaultDeployArgs = @{
    Arm_ResourceGroupName        = $Arm_ResourceGroupName
    Arm_MainSiteResourceLocation = $Arm_MainSiteResourceLocation
    Cdph_ResourceInstance        = $Cdph_ResourceInstance
    Cdph_PfxCertificatePath      = $Cdph_PfxCertificatePath
    Cdph_PfxCertificatePassword  = $Cdph_PfxCertificatePassword
    Cdph_ClientIPAddress         = $Cdph_ClientIPAddress
}
$keyVaultDeploymentResult = &'.\Deploy-REDCapKeyVault.ps1' @keyVaultDeployArgs

if ($keyVaultDeploymentResult.Successful -eq $true)
{
    # Get the certificate from the Key Vault deployment and update the main deployment parameters file with the thumbprint of the certificate.
    [PSKeyVaultCertificate] $keyVaultCertificate = $keyVaultDeploymentResult.Certificate
    $mainParameters = Get-Content -Path '.\redcapAzureDeployMain.parameters.json' -Raw | ConvertFrom-Json
    $mainParameters.parameters.Cdph_SslCertificateThumbprint.value = $keyVaultCertificate.Thumbprint
    $mainParameters 
    | ConvertTo-Json -Depth 10 
    | Set-Content -Path '.\redcapAzureDeployMain.parameters.json' -Encoding UTF8 -Force

    $mainDeployArgs = @{
        Arm_ResourceGroupName                       = $Arm_ResourceGroupName
        Arm_MainSiteResourceLocation                = $Arm_MainSiteResourceLocation
        Arm_StorageResourceLocation                 = $Arm_StorageResourceLocation
        Cdph_ResourceInstance                       = $Cdph_ResourceInstance
        DatabaseForMySql_AdministratorLoginPassword = $DatabaseForMySql_AdministratorLoginPassword
        ProjectRedcap_CommunityPassword             = $ProjectRedcap_CommunityPassword
        Smtp_UserPassword                           = $Smtp_UserPassword
    }
}
$mainDeploymentResult = &'.\Deploy-REDCapMain.ps1' @mainDeployArgs
$mainDeploymentResult | ConvertTo-Json -Depth 12
