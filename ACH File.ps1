$ScriptFilePath = "\\AMP\Support\Scripts"

$ACHProcessors = (
    (New-Object PSObject -Property @{
        "Name"="Actum";
        "MenuOption"="1";
        "Active"=$true;
        "FileName"="Actum ACH File.ps1";
    }),
    (New-Object PSObject -Property @{
        "Name"="ACH Solutions";
        "MenuOption"="2";
        "Active"=$true;
        "FileName"="ACHSolutions ACH File.ps1";
    }),
    (New-Object PSObject -Property @{
        "Name"="UMS";
        "MenuOption"="3";
        "Active"=$true;
        "FileName"="UMS ACH File.ps1";
    }),
    (New-Object PSObject -Property @{
        "Name"="PPS";
        "MenuOption"="4";
        "Active"=$true;
        "FileName"="PPS ACH File.ps1";
    })
)

function SelectACHProcessor
{
    $i = 0
    $ACHProcessor = $null
    
    while($i -eq 0)
    {
        $OptionList = "ACH Processors:`n"
        
        foreach($Processor in $ACHProcessors)
        {
            if($Processor."Active" -eq $true)
            {
                $OptionList += $Processor."MenuOption" + ". " + $Processor."Name" + "`n"
            }
        }
        
        Write-Host $OptionList
        $Selection = Read-host "Select the ACH processor"
        
        $match = $false
        for($j = 0; $j -lt $ACHProcessors.Length; $j++)
        {
            if($ACHProcessors[$j]."MenuOption" -eq $Selection)
            {
                $match = $true
                
                $ACHProcessor = $ACHProcessors[$j]
                break
            }
        }
        
        if($match -eq $true)
        {
            $i++
        }
        else
        {
            Write-Host "Invalid selection!"
        }
    }
    
    return $ACHProcessor
}

$ACHProcessor = SelectACHProcessor

$ScriptFileName = Join-Path -Path $ScriptFilePath -ChildPath $ACHProcessor."FileName"

if( (Test-Path $ScriptFileName) -eq $false)
{
    Write-Host "Error: Unable to locate $ScriptFileName"
    Read-Host "Press enter to exit."
}
else
{
    $Command = '& "' + $ScriptFileName + '"'
    
    $UserOutput = "You have selected " + $ACHProcessor."Name" + "`n"
    
    Write-Host $UserOutput
    
    Invoke-Expression $Command
}

