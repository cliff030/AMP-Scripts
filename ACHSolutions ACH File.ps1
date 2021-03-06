. "\\AMP\Support\Scripts\includes\CSV.ps1"
. "\\AMP\Support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\ACHBatch.ps1"

$debug = $false

SelectCompany
$ACHBatchGroupID = SelectBatchGroup

# Actum requires that only standard ASCII characters be present in the file (no extended ASCII) so we will be telling the CreateCSVString function to strip unicode characters.
$CSVStringSettings = @{"Unicode"=$false;"Debug"=$debug;"Header"=$false;"DateFormat"="yyyy-MM-dd";}

$Sql = "EXEC Custom_ACHSolutionsACHFile"

$ClientList = GetBatchList $ACHBatchGroupID $Sql

$CSVString = CreateCSVString $ClientList $CSVStringSettings

$Dirname = "\\AMP\ACH\" + $Company."Name" + " ACH\ACH Solutions"

if( ! (Test-Path -Path $Dirname) )
{
    mkdir $Dirname
}

$Filename = $Dirname + "\" + (Get-Date).ToString("yyyy.MM.dd") + "_" + $ACHBatchGroupID + ".csv"

if($debug -ne $true)
{
    WriteCSVFile $CSVString $Filename
    
    Write-Host "File written to $Filename`r`n"
    Read-Host "Press enter to close"
}
else
{
    Write-Host $CSVString
}