$locations = Get-AzLocation 
| Where-Object RegionType -eq 'Physical' 
| Select-Object -Property Location, DisplayName, GeographyGroup, PhysicalLocation, Latitude, Longitude, PairedRegion # , Providers
| Sort-Object -Property Location

# Convert array of objects into a hashtable with a key for each location.
$locationMap = [ordered]@{}
$locations | ForEach-Object {
    $locationMap.Add($_.Location, $_)
}

$locationMap 
| ConvertTo-Json -Depth 5 
| Out-File -FilePath 'AzLocationMap.json' -Encoding UTF8 -Force
