. "C:\scripts\Resources\DatabaseConfig.ps1"

$URI = "http://AMP-DC/ReportServer/ReportExecution2005.asmx?wsdl"
$format = "pdf"
$deviceinfo = ""            
$extention = ""            
$mimeType = ""            
$encoding = "UTF-8"            
$warnings = $null            
$streamIDs = $null

$Databases = ("CSDATA9_INC", "CSDATA9_FFN")

function GetStartDate {
    $StartDate = ( Get-Date )
       
    while( $StartDate.DayOfweek -ne "Monday") {
        $StartDate = $StartDate.AddDays(-1)
    }
    
    return $StartDate
}

function EmailReport($ReportName,$ReportFile,$ReportDate) {
    if($ReportName -eq "ConvertedLeadsByDateRange" ) {
        $ReportName = $global:Company."Name" + " - Converted Leads"
    } elseif($ReportName -eq "NewLeadsByDateRange") {
        $ReportName = $global:Company."Name" + " - New Leads"
    }

    $Sender = New-Object Net.Mail.MailAddress("reports@ampaccount.com","AMP Reports")
    $Recipient = New-Object Net.Mail.MailAddress("boudreau.bruce@gmail.com","Bruce Boudreau")
    $Recipient2 = New-Object Net.Mail.MailAddress("nruggeri@aol.com","Nick Ruggeri")
    $CC = New-Object Net.Mail.MailAddress("chris@ampaccount.com","Chris Brundage")
    
    $Subject = "$ReportName " + $ReportDate.ToString("MM/dd/yyyy")
    
    $SmtpHost = "mail.myampaccount.com"
    $Port = 587
    $Username = "reports@ampaccount.com"
    $Password = "Zzr8WVyHsueDJXWs9WDfWEe4"
    
    $Report = New-Object Net.Mail.Attachment($ReportFile)
    $Msg = New-Object Net.Mail.MailMessage
    
    $Smtp = New-Object Net.Mail.SmtpClient($SmtpHost,$Port)
    $Smtp.Credentials = New-Object Net.NetworkCredential($Username,$Password)
    
    $Msg.From = $Sender
    $Msg.To.Add($Recipient)
    $Msg.To.Add($Recipient2)
    $Msg.CC.Add($CC)
    $Msg.Subject = $Subject
    $Msg.Body = "See attached."
    $Msg.Attachments.Add($Report)
    
    $Smtp.Send($Msg)
    $Report.Dispose()
}

$EndDate = ( Get-Date )

if($EndDate.DayOfWeek -eq "Saturday" -or $EndDate.DayOfWeek -eq "Sunday") {
    exit
}

$StartDate = GetStartDate

$Reports = ("ConvertedLeadsByDateRange", "NewLeadsByDateRange")

foreach($Database in $Databases)
{
    try
    {
        SelectCompany $Database
        
        $ReportPath = GetReportPath
        
        foreach($Report in $Reports)
        {
            $ReportName = $ReportPath + $Report
       
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

            $Parameters = [ReportExecution2005.ParameterValue[]] ($ParamStartDate,$ParamEndDate)

            #Set ExecutionParameters            
            $ExecParams = $rsExec.SetExecutionParameters($Parameters, "en-us");             
                    
            $Render = $rsExec.Render($format, $deviceInfo,[ref] $extention, [ref] $mimeType,[ref] $encoding, [ref] $warnings, [ref] $streamIDs)             
            
            $ReportFile = "$env:TEMP\" + $Company."Name" + " - " + $Report + "-" + $EndDate.ToString("yyyy.MM.dd") + ".pdf"
            
            $fileStream = New-Object System.IO.FileStream($ReporTfile, [System.IO.FileMode]::OpenOrCreate)
            $fileStream.Write($render, 0, $render.Length)
            $fileStream.Close()
            
            Write-host $ReportFile
            
            EmailReport $Report $ReportFile $EndDate
        }
    }
    catch [System.Exception]
    {
        Write-Host $_.Exception.ToString()
    }
}
