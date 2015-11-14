. '\\amp\support\scripts\includes\DatabaseConfig 2.0.ps1'
. '\\amp\support\scripts\includes\LoadSqlPs.ps1'

LoadSqlPs

function ReadPhoneNumberList($filename)
{
    $PhoneNumberList = Import-Csv $filename

    return $PhoneNumberList
}

$PhoneNumberList = ReadPhoneNumberList C:\users\chris\Downloads\Book1.csv

function CheckDatabase($PhoneNumberList)
{
   $Columns = @("HomePhone","WorkPhone","OtherPhone","Mobile")

   $sql = [String]::Empty
   $sql += "SELECT * FROM Custom_ClientPhoneNumbers WHERE "

   $i = 1
   foreach($col in $Columns)
   {
        $sql += "$col IN ("
        
        $j = 1
        foreach($PhoneNumber in $PhoneNumberList)
        {
            $sql += "'" + $PhoneNumber.Phone + "'"

            if($j -lt $PhoneNumberList.Length)
            {
                $sql += ","
            }

            $j++
        }
         
        $sql += ")"
        
        if($i -lt $Columns.Length)
        {
            $sql += " OR "
        }

        $i++
   }

   $results = Invoke-Sqlcmd -ServerInstance $global:DSN -Database $Global:Company.DB $sql

   $results | Export-Csv -Append C:\users\chris\Downloads\results.csv
}

if( (Test-Path C:\users\chris\Downloads\results.csv) )
{
    Remove-Item C:\users\chris\Downloads\results.csv
}

foreach($Company in $global:Companies)
{
    SetCompany($Company)

    CheckDatabase($PhoneNumberList)
}

