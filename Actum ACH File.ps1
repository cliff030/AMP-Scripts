. "\\AMP\Support\Scripts\includes\LoadSqlPs.ps1"
. "\\AMP\Support\Scripts\includes\CSV.ps1"
. "\\AMP\Support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\ACHBatch.ps1"

$debug = $false

LoadSqlPs

SelectCompany
$ACHBatchGroupID = SelectBatchGroup

# Actum requires that only standard ASCII characters be present in the file (no extended ASCII) so we will be telling the CreateCSVString function to strip unicode characters.
$CSVStringSettings = @{"Unicode"=$false;"Debug"=$debug;"Header"=$true;"DateFormat"="MM.dd.yyyy";}

$Sql = "EXEC Custom_ActumACHFile"

$ClientList = GetBatchList $ACHBatchGroupID $Sql

<# 
# Our CSV file should have the following header. The linebreaks in this comment are for readability purposes only.
 "ParentID","SubID","PmtType","TransactionType","CustName","CustPhone","CustEmail","CustAddress1","CustAddress2","CustCity","CustState","CustZip","ShipAddress1","ShipAddress2","ShipCity","ShipState","ShipZip",
 "AccountType","ABANumber","AccountNumber","MerOrderNumber","Currency","InitialAmount","BillingCycle","RecurAmount","DaysTilRecur","MaxNumBillings","FreeSignUp","ProfileID","PrevHistoryID","CheckNumber",
 "Username","Password","NextBillingDate"
#>

$CSVString = CreateCSVString $ClientList $CSVStringSettings

$Dirname = "\\AMP\ACH\" + $Company."Name" + " ACH\Actum"

if( ! (Test-Path -Path $Dirname) )
{
    mkdir $Dirname
}

$Filename = $Dirname + "\ACH_A20130077_" + (Get-Date).ToString("yyyy.MM.dd") + "_" + $ACHBatchGroupID + ".txt"

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