<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCap.ps1
 #>

param (
    # Optional CDPH resource instance number to allow multiple deployments to the same subscription. If not specified, the default value of 1 will be used.
    [Parameter()]
    [int]
    $Cdph_ResourceInstance = 1,

    # Optional CDPH environment name to allow multiple deployments to the same subscription. If not specified, the default value of 'dev' will be used.
    [Parameter()]
    [ValidateSet('dev', 'test', 'stage', 'prod')]
    [string]
    $Cdph_Environment = 'dev',

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

. '.\Deploy-REDCapKeyVault.ps1'
. '.\Deploy-REDCapMain.ps1'

$keyVaultDeployArgs = @{
    Cdph_Environment             = $Cdph_Environment
    Cdph_ResourceInstance        = $Cdph_ResourceInstance
    Cdph_PfxCertificatePath      = $Cdph_PfxCertificatePath
    Cdph_PfxCertificatePassword  = $Cdph_PfxCertificatePassword
    Cdph_ClientIPAddress         = $Cdph_ClientIPAddress
}

$keyVaultDeploymentResult = Deploy-REDCapKeyVault @keyVaultDeployArgs

if ($keyVaultDeploymentResult.Successful -eq $true)
{
    $mainDeployArgs = @{
        Cdph_Environment                            = $Cdph_Environment
        Cdph_ResourceInstance                       = $Cdph_ResourceInstance
        DatabaseForMySql_AdministratorLoginPassword = $DatabaseForMySql_AdministratorLoginPassword
        ProjectRedcap_CommunityPassword             = $ProjectRedcap_CommunityPassword
        Smtp_UserPassword                           = $Smtp_UserPassword
    }
    $mainDeploymentResult = Deploy-REDCapMain @mainDeployArgs
    Write-Output $mainDeploymentResult
}
