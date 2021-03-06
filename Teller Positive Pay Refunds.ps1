. "\\AMP\Support\Scripts\includes\LoadSqlPs.ps1"
. "\\AMP\Support\Scripts\includes\CreateCSVString.ps1"
. "\\AMP\Support\Scripts\includes\DatabaseConfig.ps1"

LoadSqlPs

function WriteCSVFile($CSVString,$Filename)
{
    # Per Actum, the file must be ASCII!
    $CSV = [System.Text.Encoding]::ASCII.GetBytes($CSVString)
    
    $fileStream = New-Object System.IO.FileStream($Filename, [System.IO.FileMode]::OpenOrCreate)
    $fileStream.Write($CSV, 0, $CSV.Length)
    $fileStream.Close()
}

$BankAccountID = 0
$CheckRunID = 1710

$TimeStamp = (Get-Date)

SetCompany "CSDATA8" "Select Financial"

$sql = "SELECT AccountNumber FROM BankAccounts WHERE BankAccountID = $BankAccountID"

$Result = Invoke-Sqlcmd -Query "$Sql" -ServerInstance $DSN -Database $DB

$AccountNumber = $Result.AccountNumber

$sql = "EXEC Custom_TellerPositivePay $BankAccountID, $CheckRunID"

$Result = Invoke-Sqlcmd -Query "$Sql" -ServerInstance $DSN -Database $DB

foreach($Row in $Result)
    {
        foreach($Col in $Row.Table.Columns)
        {
            if($Row.$Col.GetType().Name -eq "decimal")
            {
                $Row.$Col = [System.Math]::Round($Row.$Col,2)
            }
        }
    }

$CSVStringSettings = @{"Unicode"=$false;"Debug"=$debug;"Header"=$false;"DateFormat"="MMddyy";}

$CSVString = CreateCSVString $Result $CSVStringSettings

$Filepath = "$env:USERPROFILE\Desktop\"

$Filename = $Filepath + $AccountNumber + "[" + $TimeStamp.ToString("MMddyyHHmmss") + "].csv"

WriteCSVFile $CSVString $Filename