# This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 

Set-StrictMode -Version Latest

# Copied and expanded from StackOverflow answer by user https://stackoverflow.com/users/1701026/iron
# https://stackoverflow.com/a/32890418/100596

function PickValueToKeep
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConsolidatingHashtable,

        [Parameter(Mandatory = $true)]
        [PSObject]
        $Key,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $MergingHashtable,

        [Parameter()]
        [Switch]
        $MultipleValues,

        [Parameter()]
        [Switch]
        $KeepFirstValues
    )

    if ($ConsolidatingHashtable.ContainsKey($Key))
    { 
        if ($MultipleValues)
        {
            return @($ConsolidatingHashtable[$Key]) + $MergingHashtable[$Key]
        }
        else
        { 
            if ($KeepFirstValues)
            {
                return $ConsolidatingHashtable[$Key] # returns a new value
            }
            else
            {
                return $MergingHashtable[$Key]
            }
        } 
    }
    else
    {
        return $MergingHashtable[$Key]
    }
}

function Merge-Hashtables
{
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Hashtable[]]
        $Hashtables,

        [Parameter()]
        [Switch]
        $MultipleValues,

        [Parameter()]
        [Switch]
        $KeepFirstValues,

        [Parameter()]
        [Switch]
        $RequireUnique,

        [Parameter()]
        [ScriptBlock]
        $Operation
    )
    
    $output = @{ }
    foreach ($hashTable in $Hashtables)
    {
        foreach ($key in $hashTable.Keys)
        { 
            $output.$key = PickValueToKeep `
                -ConsolidatingHashtable $output `
                -Key $key `
                -MergingHashtable $hashtable `
                -MultipleValues:$MultipleValues `
                -KeepFirstValues:$KeepFirstValues 
        }
    }

    if ($Operation)
    { 
        foreach ($key in @($output.Keys))
        { 
            $_ = @($output[$key]); 
            $output[$key] = Invoke-Command $Operation 
        } 
    }

    $output
}
Export-ModuleMember -Function 'Merge-Hashtables'

function Get-HashtableValue
{
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]
        $Hashtable,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]
        $Key
    )
    
    $value = $null
    $foundOnce = $false

    foreach ($testKey in $Hashtable.Keys)
    {
        if ($testKey -ieq $Key)
        {
            if ($foundOnce)
            {
                throw "Hashtable contains more than one key can can match '$Key' in a case-insensitive comparison"
            }
            else
            {
                $value = $Hashtable[$testKey]
                $foundOnce = $true
            }
        }
    }
    return $value
}
Export-ModuleMember -Function 'Get-HashtableValue'
