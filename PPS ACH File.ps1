. "\\AMP\Support\Scripts\includes\LoadSqlPs.ps1"
. "\\AMP\Support\Scripts\includes\CSV.ps1"
. "\\AMP\Support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\ACHBatch.ps1"

$debug = $true

LoadSqlPs

SelectCompany
$ACHBatchGroupID = SelectBatchGroup

$CSVStringSettings = @{"Unicode"=$false;"Debug"=$debug;"Header"=$false;"DateFormat"="yyyy/MM/dd HH:mm:ss";}

$Sql = "EXEC Custom_PPSACHFile"

$ClientList = GetBatchList $ACHBatchGroupID $Sql

$CSVString = CreateCSVString $ClientList $CSVStringSettings

$Dirname = "\\AMP\ACH\" + $Company."Name" + " ACH\PPS"

if( ! (Test-Path -Path $Dirname) )
{
    mkdir $Dirname
}


$Filename = $Dirname + "\" + (Get-Date).ToString("MM.dd.yyyy") + ".csv"

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