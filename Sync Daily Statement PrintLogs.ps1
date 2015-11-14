import-module sqlps

$dbs = @("CSDATA8", "CSDATA8_INC", "CSDATA8_FFN")

foreach($db in $dbs)
{
    $sql = "truncate table custom_dailystatementsprintlog"
    invoke-sqlcmd -Database $db -ServerInstance "tcp:AMP-DC,1433" $sql

    $sql = "SELECT ACHBatchID, DatePrinted, PrintedBy FROM Custom_DailyStatements WHERE Success = 1 order by achbatchid asc"
    $logs = invoke-sqlcmd -Database $db -ServerInstance "tcp:AMP-DC,1433" $sql

    foreach($log in $logs)
    {
        $sql = "INSERT INTO Custom_DailyStatementsPrintLog ( ACHBatchID, DatePrinted, PrintedBy, Success ) VALUES ( "
        $sql += $log.ACHBatchID.ToString() + ", "
        $sql += "'" + $log.DatePrinted + "', "
        $sql += "'" + $log.PrintedBy + "', "
        $sql += "1 )"

        invoke-sqlcmd -Database $db -ServerInstance "tcp:AMP-DC,1433" -Username "developer" -Password "3JgvlLhcKHsr" $sql
    }
}