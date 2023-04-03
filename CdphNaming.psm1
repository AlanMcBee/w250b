<#
.SYNOPSIS
Creates the CDPH-compliant resource name for the specified resource provider.

.DESCRIPTION
Choose a resource provider from the list of supported resource providers and provide the required parameters to generate a CDPH-compliant resource name.
#>
function New-CdphResourceName
{
    [CmdletBinding()]
    param (
        # Resource Provider Name
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Microsoft.DBforMySQL/flexibleServers',
            'Microsoft.Insights/components',
            'Microsoft.KeyVault/vaults',
            'Microsoft.Network/virtualNetworks',
            'Microsoft.OperationalInsights/workspaces',
            'Microsoft.Resources/resourceGroups',
            'Microsoft.Storage/storageAccounts',
            'Microsoft.Web/certificates',
            'Microsoft.Web/serverfarms',
            'Microsoft.Web/sites'
        )]
        [string]
        $Arm_ResourceProvider,

        # CDPH Owner
        [Parameter(Mandatory = $true)]
        [ValidateSet('ITSD', 'CDPH')]
        [string]
        $Cdph_Organization,

        # CDPH Business Unit (numbers & digits only)
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z0-9]{2,5}$')]
        [string]
        $Cdph_BusinessUnit,
        
        # CDPH Business Unit Program (numbers & digits only)
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z0-9]{2,7}$')]
        [string]
        $Cdph_BusinessUnitProgram,

        # Targeted deployment environment
        [Parameter(Mandatory = $true)]
        [ValidateSet('DEV', 'TEST', 'STAGE', 'PROD')]
        [string]
        $Cdph_Environment,

        # Instance number (when deploying multiple instances of this template into one environment)
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 99)]
        [int]
        $Cdph_ResourceInstance
    )

    begin
    { 
        $newResourceName = $null
    }

    process
    {
        $arm_ResourceInstance_ZeroPadded = $Cdph_ResourceInstance.ToString('00')
        $orgLength = $Cdph_Organization.Length
        $unitLength = $Cdph_BusinessUnit.Length
        $programLength = $Cdph_BusinessUnitProgram.Length
        $envLength = $Cdph_Environment.Length
        $inputNameLength = $orgLength + $unitLength + $programLength + $envLength
        switch ($Arm_ResourceProvider)
        {
            'Microsoft.Resources/resourceGroups'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftresources
                $prefix = 'rg'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.KeyVault/vaults'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftkeyvault
                $prefix = 'kv'
                $minBaseLength = $prefix.Length + 6 # 'kv' + 2-digit instance + 4 hyphens (not including the last hyphen which is optional)
                $maxKeyVaultNameLength = 24
                $inputOverBaseLength = $inputNameLength + $minBaseLength
                $isOneOverMax = $inputOverBaseLength -eq $maxKeyVaultNameLength # if one over, will just remove the last hyphen
                $isOverMax = $inputOverBaseLength -gt $maxKeyVaultNameLength # if over, will remove the last hyphen anyway
                $lastHyphen = ($isOneOverMax -or $isOverMax) ? '' : '-'
                $lengthOverMax = [Math]::Max(0, $inputOverBaseLength - $maxKeyVaultNameLength) # adjust for the removed hyphen
                $newProgramLength = $programLength - $lengthOverMax
                $newProgram = $Cdph_BusinessUnitProgram.Substring(0, $newProgramLength)
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$newProgram-$Cdph_Environment$lastHyphen$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.Storage/storageAccounts'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftstorage
                $prefix = 'st'
                $minBaseLength = $prefix.Length + 2 # 'st' + 2-digit instance
                $maxStorageAccountNameLength = 24
                $inputOverBaseLength = $inputNameLength + $minBaseLength
                $isOvermax = $inputOverBaseLength -gt $maxStorageAccountNameLength
                $lengthOverMax = [Math]::Max(0, $inputOverBaseLength - $maxStorageAccountNameLength)
                $newProgramLength = $programLength - $lengthOverMax
                $newProgram = $Cdph_BusinessUnitProgram.Substring(0, $newProgramLength)
                $newResourceName = "$prefix$Cdph_Organization$Cdph_BusinessUnit$newProgram$Cdph_Environment$arm_ResourceInstance_ZeroPadded".ToLower()
                break
            }
            'Microsoft.DBforMySQL/flexibleServers'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftdbformysql
                $prefix = 'mysql'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded".ToLower()
                break
            }
            'Microsoft.Network/virtualNetworks'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftnetwork
                $prefix = 'vnet'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.Web/serverfarms'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftweb
                $prefix = 'asp'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.Web/sites'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftweb
                $prefix = 'app'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.Web/certificates'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftweb
                $prefix = 'cert'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.Insights/components'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftinsights
                $prefix = 'appi'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            'Microsoft.OperationalInsights/workspaces'
            {
                # https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftoperationalinsights
                $prefix = 'log'
                $newResourceName = "$prefix-$Cdph_Organization-$Cdph_BusinessUnit-$Cdph_BusinessUnitProgram-$Cdph_Environment-$arm_ResourceInstance_ZeroPadded"
                break
            }
            default
            {
                throw "Unsupported resource provider: $Arm_ResourceProvider"
            }
        }
    }
    
    end
    { 
        Write-Output $newResourceName
    }
}
Export-ModuleMember -Function 'New-CdphResourceName'

