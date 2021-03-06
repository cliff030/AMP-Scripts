. "\\AMP\Support\Scripts\includes\LoadSqlPs.ps1"
. "\\AMP\Support\Scripts\includes\DatabaseConfig.ps1"

LoadSqlPs

function SetFilePath($Company,$Type) {
    $FilePath = "\\AMP\$Company"
    
    if($Company -eq "Select Financial") {
        $FilePath = $FilePath + "\Reports"
        
        switch($Type) {
            "Clients" {
                $FilePath = $FilePath + "\Client"
            }
            "Leads" {
                $Filepath = $FilePath + "\Lead"
            }
            default {
                throw "This type is not valid for this company."
            }
        }
    } elseif($Company -eq "Liberty Financial" -or $Company -eq "First Financial") {
        $FilePath = $FilePath + "\Scanned Documents\$Type\"
    } else {
        throw "Invalid company"
    }

    return $FilePath
}

function CreateDirectory($Company,$Type,$ID) {
    try {
        $FilePath = SetFilePath $Company $Type
        $FilePath = $FilePath + $ID
    
        if( (Test-Path -LiteralPath "FileSystem::$FilePath") -eq $false) {
            New-Item "FileSystem::$FilePath" -Type Directory | Out-Null
        }
        } catch [System.Exception] {
            throw $_
        }
}

$ClientsSQL = "SELECT DISTINCT ClientID FROM Clients ORDER BY ClientID"
$LeadsSQL = "SELECT DISTINCT ClientID FROM LeadClient ORDER BY ClientID"
$CreditorsSQL = "SELECT DISTINCT CreditorID FROM Creditors ORDER BY CreditorID"
$IssuesSQL = "SELECT DISTINCT IssueID FROM Issues WHERE Status<>'Completed' AND Status<>'Closed' ORDER BY IssueID"

$SqlStatements = @{"Clients"=$ClientsSQL;"Leads"=$LeadsSQL;"Creditors"=$CreditorsSQL;"Issues"=$IssuesSQL}

foreach($local:Company in $global:Companies.GetEnumerator()) {
    SetCompany $local:Company."DB" $local:Company."Name"

    foreach($Sql in $SqlStatements.GetEnumerator()) {
        if($global:Company -eq "Select Financial" -and ( $Sql."Name" -eq "Creditors" -or $Sql."Name" -eq "Issues" ) ) {
            continue
        } else {        
            Invoke-Sqlcmd -Query $Sql."Value" -ServerInstance $global:DSN -Database $global:DB -SuppressProviderContextWarning | ForEach-Object {
                try {                
                    CreateDirectory $global:Company $Sql."Name" $_[0]
                } catch [System.Exception] {
                    Write-Host $_.Exception.ToString()
                }
            }
        }
    }
}