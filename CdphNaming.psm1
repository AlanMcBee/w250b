function New-KeyVaultResourceName
{
    [CmdletBinding()]
    param (
        # CDPH Owner
        [Parameter(Mandatory = $true)]
        [ValidateSet('ITSD', 'CDPH')]
        [string]
        $Cdph_Organization,

        # CDPH Business Unit (numbers & digits only)
        [Parameter(Mandatory = $true)]
        [ValidateLength(2, 5)]
        [string]
        $Cdph_BusinessUnit,

        # CDPH Business Unit Program (numbers & digits only)
        [Parameter(Mandatory = $true)]
        [ValidateLength(2, 7)]
        [string]
        $Cdph_BusinessUnitProgram,

        # Targeted deployment environment
        [Parameter(Mandatory = $true)]
        [ValidateSet('DEV', 'TEST', 'PROD')]
        [string]
        $Cdph_Environment,

        # Instance number (when deploying multiple instances of this template into one environment)
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 99)]
        [int]
        $Cdph_ResourceInstance
    )

    begin
    { }

    process
    {
        $arm_ResourceInstance_ZeroPadded = $Cdph_ResourceInstance.ToString('00')
        $orgLength = $Cdph_Organization.Length
        $unitLength = $Cdph_BusinessUnit.Length
        $programLength = $Cdph_BusinessUnitProgram.Length
        $envLength = $Cdph_Environment.Length
        $minBaseLength = 'kv00'.Length + 4 # 'kv' + 2-digit instance + 4 hyphens (not including the last hyphen which is optional)
        $maxKeyVaultNameLength = 24
        $inputNameLength = $orgLength + $unitLength + $programLength + $envLength
        $inputOverBaseLength = $inputNameLength + $minBaseLength
        $isOneOverMax = $inputOverBaseLength -eq $maxKeyVaultNameLength # if one over, will just remove the last hyphen
        $isOverMax = $inputOverBaseLength -gt $maxKeyVaultNameLength # if over, will remove the last hyphen anyway
        $lastHyphen = ($isOneOverMax -or $isOverMax) ? '' : '-'
        $lengthOverMax = [Math]::Max(0, $inputOverBaseLength - $maxKeyVaultNameLength) # adjust for the removed hyphen
        $newProgramLength = $programLength - $lengthOverMax
        $newProgram = $Cdph_BusinessUnitProgram.Substring(0, $newProgramLength)
        $keyVault_ResourceName = "kv-$Cdph_Organization-$Cdph_BusinessUnit-$newProgram-$Cdph_Environment$lastHyphen$arm_ResourceInstance_ZeroPadded"
        Write-Output $keyVault_ResourceName
    }

    end
    { }
}
Export-ModuleMember -Function 'New-KeyVaultResourceName'

