<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

 #>
#requires -Modules Az.Resources, Az.KeyVault
#requires -Version 7.1

param (
    # Name of the resource group to deploy resources into
    [Parameter()]
    [string]
    $Arm_ResourceGroupName,

    # Geographic location for all resources in this deployment. 
    # This script can deploy resources into the following regions: 
    #   centralus
    #   eastus
    #   eastus2
    #   northcentralus
    #   southcentralus
    #   westcentralus
    #   westus
    #   westus2
    #   westus3

    [Parameter(Mandatory = $true)]
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
    $Arm_MainSiteResourceLocation,

    # Resource instance number to use for naming resources
    [Parameter()]
    [int]
    $Cdph_ResourceInstance = 1,

    # Path to PFX certificate file to upload to Key Vault for App Service SSL binding
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]
    $PfxCertificatePath,

    # Password for PFX certificate file
    [Parameter(Mandatory = $true)]
    [securestring]
    $PfxCertificatePassword
)

$startTime = Get-Date
Write-Output "Beginning deployment at $starttime"

$requiredParameters = @(
    'Cdph_SslCertificateThumbprint'
)
$deployParametersPath = 'redcapAzureDeploy.parameters.json'
$deployParameters = Get-Content $deployParametersPath | ConvertFrom-Json -Depth 8 -AsHashtable
if ($null -eq $deployParameters)
{
    Write-Error "Unable to load deployment parameters from $deployParametersPath"
}
if (-not $deployParameters.ContainsKey('parameters'))
{
    Write-Error "Deployment parameters from $deployParametersPath do not contain a 'parameters' property"
}
$parametersEntry = $deployParameters.parameters
foreach ($requiredParameter in $requiredParameters)
{
    if (-not $parametersEntry.ContainsKey($requiredParameter))
    {
        Write-Error "Deployment parameters from $deployParametersPath do not contain a required '$requiredParameter' property"
    }
    if (0 -eq $parametersEntry[$requiredParameter].value.Length)
    {
        Write-Error "Deployment parameters from $deployParametersPath do not contain a required value for the '$requiredParameter' property"
    }
}

# Create hashtable from parametersEntry moving the value sub-property to the top level
$flattenedParameters = @{}
foreach ($parameterName in $parametersEntry.Keys)
{
    $flattenedParameters[$parameterName] = $parametersEntry[$parameterName].value
}

# Override parameters with values from the command line
$flattenedParameters['Arm_MainSiteResourceLocation'] = $Arm_MainSiteResourceLocation
$flattenedParameters['Cdph_ResourceInstance'] = $Cdph_ResourceInstance

# Merge parameters
$templateParameters = $flattenedParameters
$organization = $templateParameters['Cdph_Organization']
$businessUnit = $templateParameters['Cdph_BusinessUnit']
$program = $templateParameters['Cdph_BusinessUnitProgram']
$environment = $templateParameters['Cdph_Environment']
$instance = $templateParameters['Cdph_ResourceInstance'].ToString().PadLeft(2, '0')

if ($PSBoundParameters.ContainsKey('Arm_ResourceGroupName') && ![string]::IsNullOrWhiteSpace( $Arm_ResourceGroupName))
{
    $resourceGroupName = $Arm_ResourceGroupName
}
else
{
    $resourceGroupName = "rg-$organization-$businessUnit-$program-$environment-$instance"
}

$appServicePlanName = "asp-$organization-$businessUnit-$program-$environment-$($instance.PadLeft(2, '0'))"

# Make sure we're logged in. Use Connect-AzAccount if not.
Get-AzContext -ErrorAction Stop

# Start deployment
$bicepPath = 'redcapAzureDeployKeyVault.bicep'

try
{
    Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop
    Write-Output "Resource group $resourceGroupName exists. Updating deployment"
}
catch
{
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $Arm_MainSiteResourceLocation
    Write-Output "Created new resource group $resourceGroupName."
}

$version = (Get-Date).ToString('yyyyMMddHHmmss')
$deploymentName = "REDCapDeployKeyVault.$version"
$deployArgs = @{
    ResourceGroupName       = $resourceGroupName
    TemplateFile            = $bicepPath
    Name                    = $deploymentName
    TemplateParameterObject = $templateParameters
}
[Microsoft.Azure.Commands.Resources.Models.PSResourceGroupDeployment] $armDeployment = New-AzResourceGroupDeployment @deployArgs -Force -Verbose -DeploymentDebugLogLevel ResponseContent

while ($null -ne $armDeployment && $armDeployment.ProvisioningState -eq 'Running') {
    Write-Output "Waiting for deployment to complete at $([datetime]::Now.AddSeconds(5).ToShortTimeString())"
    Start-Sleep 5
}

if ($null -ne $armDeployment && $armDeployment.ProvisioningState -eq 'Succeeded') # PowerShell 7
{
    $siteName = $armDeployment.Outputs.webSiteFQDN.Value
    $deployment.Outputs | ConvertTo-Json -Depth 8

    $keyVaultResourceName = $deployment.Outputs.KeyVault_ResourceName.Value

    $deployment
    Import-AzKeyVaultCertificate `
        -VaultName $keyVaultResourceName `
        -Name $appServicePlanName `
        -FilePath $PfxCertificatePath `
        -Password $PfxCertificatePassword
}
else
{
    [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSDeploymentOperation] $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
    $deploymentErrors | ConvertTo-Json -Depth 8
}

$endTime = Get-Date

Write-Output "Total Deployment time:"
New-TimeSpan -Start $startTime -End $endTime | Select-Object Hours, Minutes, Seconds
