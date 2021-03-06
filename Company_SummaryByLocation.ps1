. "\\amp\support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\LoadSqlPs.ps1"

LoadSqlPs

$URI = "http://AMP-DC/ReportServer/ReportExecution2005.asmx?wsdl"
$format = "pdf"
$deviceinfo = ""            
$extention = ""            
$mimeType = ""            
$encoding = "UTF-8"            
$warnings = $null            
$streamIDs = $null

$Database = "CSDATA9"

SelectCompany $Database

$EndDate = Get-Date
$StartDate = [datetime]([string]$EndDate.Year + "-" + [string]$EndDate.Month + "-01")

if($EndDate.DayOfWeek -eq "Saturday" -or $EndDate.DayOfWeek -eq "Sunday") {
    exit
}

function GetLocations()
{
    $sql = "SELECT LocationID, LocationName FROM Locations WHERE LocationID <> 1"
    
    $Result = Invoke-Sqlcmd -Query "$Sql" -ServerInstance $DSN -Database $DB
    
    return $Result
}

function EmailReport($ReportName,$ReportFiles,$ReportDate) {
    $Sender = New-Object Net.Mail.MailAddress("reports@ampaccount.com","AMP Reports")
    $Recipient = New-Object Net.Mail.MailAddress("boudreau.bruce@gmail.com","Bruce Boudreau")
    $CC = New-Object Net.Mail.MailAddress("chris@ampaccount.com","Chris Brundage")
    $CC2 = New-Object Net.Mail.MailAddress("almaw@ampaccount.com","Alma Wiseman")
    
    $Subject = "$ReportName " + $ReportDate.ToString("MM/dd/yyyy")
    
    $SmtpHost = "mail.myampaccount.com"
    $Port = 587
    $Username = "reports@ampaccount.com"
    $Password = "Zzr8WVyHsueDJXWs9WDfWEe4"
    
    $Msg = New-Object Net.Mail.MailMessage
    
    $Smtp = New-Object Net.Mail.SmtpClient($SmtpHost,$Port)
    $Smtp.Credentials = New-Object Net.NetworkCredential($Username,$Password)
    
    $Msg.From = $Sender
    $Msg.To.Add($Recipient)
    $Msg.CC.Add($CC)
    $Msg.CC.Add($CC2)
    $Msg.Subject = $Subject
    $Msg.Body = "See attached."
    
    foreach($ReportFile in $ReportFiles)
    {
        $Report = New-Object Net.Mail.Attachment($ReportFile)
        $Msg.Attachments.Add($Report)
    }
    
    $Smtp.Send($Msg)
    $Report.Dispose()
}

$Locations = GetLocations

$ReportPath = GetReportPath
    
$ReportName = $ReportPath + "Custom_CompanySummary by Location"

$ReportFiles = @()

foreach($Location in $Locations)
{
    $ReportObject = New-WebServiceProxy -Uri $URI -UseDefaultCredential -namespace "ReportExecution2005"  

    $rsExec = New-Object ReportExecution2005.ReportExecutionService            
    $rsExec.Credentials = [System.Net.CredentialCache]::DefaultCredentials             
            
    #Set ExecutionParameters            
    $execInfo = @($ReportName, $null)             
            
    #Load the selected report.            
    $rsExec.GetType().GetMethod("LoadReport").Invoke($rsExec, $execInfo) | out-null       

    #Report Parameters
    $ParamStartDate = new-object ReportExecution2005.ParameterValue
    $ParamStartDate.Name = "StartDate"
    $ParamStartDate.Value = $StartDate.ToString("MM/dd/yyyy")

    $ParamEndDate = new-object ReportExecution2005.ParameterValue
    $ParamEndDate.Name = "EndDate"
    $ParamEndDate.Value = $EndDate.ToString("MM/dd/yyyy")
    
    $ParamLocationID = new-object ReportExecution2005.ParameterValue
    $ParamLocationID.Name = "LocationID"
    $ParamLocationID.Value = $Location."LocationID"

    $Parameters = [ReportExecution2005.ParameterValue[]] ($ParamStartDate,$ParamEndDate,$ParamLocationID)

    #Set ExecutionParameters            
    $ExecParams = $rsExec.SetExecutionParameters($Parameters, "en-us");             
            
    $Render = $rsExec.Render($format, $deviceInfo,[ref] $extention, [ref] $mimeType,[ref] $encoding, [ref] $warnings, [ref] $streamIDs)             

    $ReportFile = "$env:TEMP\" + $Location."LocationName" + " " + $StartDate.ToString("yyyy.MM.dd") + ".pdf"

    $fileStream = New-Object System.IO.FileStream($ReporTfile, [System.IO.FileMode]::OpenOrCreate)
    $fileStream.Write($render, 0, $render.Length)
    $fileStream.Close()
    
    $ReportFiles += $ReportFile
}

$Subject = $Company."Name" + " - Company Summary By Location"

EmailReport  $Subject $ReportFiles $EndDate