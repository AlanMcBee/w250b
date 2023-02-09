<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

 #>
#requires -Modules Az.Resources
#requires -Version 7.1

param (
    # Name of the resource group to deploy resources into
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,

    # Geographic location for all resources in this deployment. 
    # This script will deploy resources into the following regions: 
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
    $Arm_ResourceLocation,

    # Password for the MySQL administrator account
    [Parameter(Mandatory = $true)]
    [securestring]
    $DatabaseForMySql_AdministratorLoginPassword,

    # Password for the REDCap Community site account
    [Parameter(Mandatory = $true)]
    [securestring]
    $ProjectRedcap_CommunityPassword,

    # Password for the SMTP server account
    [Parameter(Mandatory = $true)]
    [securestring]
    $Smtp_UserPassword
)

$startTime = Get-Date
Write-Output "Beginning deployment at $starttime"

$requiredParameters = @(
    'Cdph_SslCertificateThumbprint',
    'ProjectRedcap_DownloadAppZipUri',
    'ProjectRedcap_CommunityUsername',
    'Smtp_FromEmailAddress',
    'Smtp_FQDN',
    'Smtp_UserLogin'
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

# Merge parameters
$templateParameters = $flattenedParameters + @{
    DatabaseForMySql_AdministratorLoginPassword = $DatabaseForMySql_AdministratorLoginPassword
    ProjectRedcap_CommunityPassword             = $ProjectRedcap_CommunityPassword
    Smtp_UserPassword                           = $Smtp_UserPassword
}

# Make sure we're logged in. Use Connect-AzAccount if not.
Get-AzContext -ErrorAction Stop

# Start deployment
$bicepPath = 'redcapAzureDeploy.bicep'

try
{
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-Output "Resource group $ResourceGroupName exists. Updating deployment"
}
catch
{
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Arm_ResourceLocation
    Write-Output "Created new resource group $ResourceGroupName."
}

$version = (Get-Date).ToString('yyyyMMddHHmmss')
$deploymentName = "RedCAPDeploy.$version"
# $deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $parms -TemplateFile $TemplateFile -Name "RedCAPDeploy$version"  -Force -Verbose
$deployArgs = @{
    ResourceGroupName       = $ResourceGroupName
    TemplateFile            = $bicepPath
    Name                    = $deploymentName
    TemplateParameterObject = $templateParameters
}
$armDeployment = New-AzResourceGroupDeployment @deployArgs -Force -Verbose

if ($armDeployment?.ProvisioningState -eq 'Succeeded') # PowerShell 7
{
    $siteName = $armDeployment.Outputs.webSiteFQDN.Value
    Start-Process "https://$($siteName)/AzDeployStatus.php"
    $deployment.Outputs | ConvertTo-Json -Depth 8
}
else
{
    $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $ResourceGroupName
    $deploymentErrors | ConvertTo-Json -Depth 8
}

$endTime = Get-Date

Write-Output "Total Deployment time:"
New-TimeSpan -Start $startTime -End $endTime | Select-Object Hours, Minutes, Seconds
