<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCap.ps1
 #>

using namespace System.Diagnostics

using module .\ErrorRecord.psm1

param (
    # CDPH Owner
    [Parameter(Mandatory = $true)]
    [ValidateSet('ITSD', 'CDPH')]
    [string]
    $Cdph_Organization,

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

[Stopwatch] $stopwatch = [Stopwatch]::StartNew()

Write-Information "Beginning deployment at $((Get-Date).ToString())"

try
{
    Remove-Module DeployREDCapAzure -Force -ErrorAction SilentlyContinue
    Import-Module .\DeployREDCapAzure.psm1 -Force

    $DeployArguments = @{
        Cdph_Organization                                                               = $Cdph_Organization
        Cdph_Environment                                                                = $Cdph_Environment
        Cdph_ResourceInstance                                                           = $Cdph_ResourceInstance
        Cdph_PfxCertificatePath                                                         = $Cdph_PfxCertificatePath
        Cdph_PfxCertificatePassword                                                     = $Cdph_PfxCertificatePassword
        Cdph_ClientIPAddress                                                            = $Cdph_ClientIPAddress
        MicrosoftKeyVault_vaults_secrets_MicrosoftDBforMySQL_AdministratorLoginPassword = $DatabaseForMySql_AdministratorLoginPassword
        MicrosoftKeyVault_vaults_secrets_ProjectREDCap_CommunityUserPassword            = $ProjectRedcap_CommunityPassword
        MicrosoftKeyVault_vaults_secrets_Smtp_UserPassword                              = $Smtp_UserPassword
    }

    Deploy-AzureREDCap @DeployArguments
}
catch
{
    $x = $_
    # $x | ConvertTo-Json -Depth 10 | Out-File -FilePath 'deploy.json' -Encoding UTF8 -Force
    Write-CaughtErrorRecord $x Error -IncludeStackTrace
}
finally
{
    # Stop timer
    $stopwatch.Stop() | Out-Null
    $measured = $stopwatch.Elapsed

    Write-Information "Total Deployment time: $($measured.ToString())"
}

# return $deploymentResult
