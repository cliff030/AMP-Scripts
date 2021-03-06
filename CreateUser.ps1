[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
        [switch]$AMPUser,
    [Parameter(Mandatory=$False)]
        [switch]$RemoteUser,
    [Parameter(Mandatory=$False)]
        [string]$ImportFileName,    
    [Parameter(Mandatory=$False)]
        [string]$UserType,
    [Parameter(Mandatory=$False)]
        [switch]$help
)

. "\\AMP\Support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\LoadADModule.ps1"
. "\\AMP\Support\Scripts\includes\CreateAMPUser.ps1"
. "\\AMP\Support\Scripts\includes\CreateRemoteUser.ps1"

LoadADModule

$global:UserTypes = @("AMP", "Remote")

function ListUserTypes($andor = "and")
{
    $UserTypeList = [String]::Empty

    if($global:UserTypes.Length -le 1)
    {
        $UserTypeList += $global:UserTypes[0]
    }
    else
    {
        $i = 1
        foreach($gUserType in $global:UserTypes)
        {
            if($i -lt $global:UserTypes.Length)
            {
                if($global:UserTypes.Length -le 2)
                {
                    $UserTypeList += $gUserType + " "
                }
                else
                {
                    $UserTypeList += $gUserType + ", "
                }
            }
            else
            {
                $UserTypeList += $andor + " " + $gUserType
            }            
            $i++
        }
    }
    
    $UserTypeList += "."
    
    return $UserTypeList
}

function PrintHelpAndExit
{
    Write-Host "CreateNewUser - This script will create a new Active Directory user. When run without parameters it will prompt for the user type. You can also use this script to mass create users by importing a csv file."
    Write-Host "`r"
    
    Write-Host "PARAMETERS:"
    Write-Host "All parameters are optional."
    Write-Host "`r"
    
    Write-Host "-UserType: Use this parameter to specify the type of user you are creating. The value of this paramter will override any short hand user type parameters (e.g. -AMPUser)."
    Write-Host "-AMPUser: Specify that you are creating an AMP user."
    Write-Host "-RemoteUser: Specify that you are creating an Remote user."
    Write-Host "-ImportFileName: Specify a path to a CSV file containing a list of users to create."
    Write-Host "-help: Print this information and exit."
    Write-Host "`r"
    
    Write-Host "USER TYPES:"
    $UserType = "Valid user types are " + ( ListUserTypes "and")
    Write-Host $UserType
    Write-Host "`r"
    
    Write-Host "IMPORTING USERS:"
    Write-Host "When importing users you are required to specify the user type via the -UserType parameter or one of the short hand user type parameters."
    Write-Host "`r"
    Write-Host "All csv files should contain the following column: Username"
    Write-Host "All csv files may optionally contain the following column: Password"
    Write-Host "`r"
    
    Write-Host "AMP USERS:"
    Write-Host "If you are creating an AMP user, then the csv file must also contain the following columns: FirstName, LastName, EmailAddress"
    Write-Host "`r"
    
    Write-Host "REMOTE USERS:"
    Write-Host "If you are creating a Remote user, then the csv file may optionally contain the following columns: Company, UserProfile, Manager"
    Write-Host 'The UserProfile column must be a valid UNC path. The Manager column should be set to "0" (false) or "1" (true)'    
    Exit
}

function CheckUserType($UserType)
{
    if($global:UserTypes -notcontains $UserType)
    {
        $ErrorMessage = "Invalid UserType! Valid values for UserType are "
    
        $ErrorMessage += ListUserTypes
        
        throw $ErrorMessage
    }    
}

function CheckParameters
{
    if($help -eq $true)
    {
        PrintHelpAndExit
    }

    if($UserType -eq $null -or $UserType -eq [String]::Empty)
    {
        if($AMPUser -eq $true -and $RemoteUser -eq $true)
        {
            throw "-AMPUser and -RemoteUser cannot be set at the same time."
        }
        else
        {
            if($AMPUser -eq $true)
            {
                $UserType = "AMP"
            }
            elseif($RemoteUser -eq $true)
            {
                $UserType = "Remote"
            }
        }
    }
    
    if($UserType -ne $null -and $UserType -ne [String]::Empty)
    {
        try
        {
            CheckUserType $UserType
        }
        catch
        {
            throw $_
        }
    }

    if($ImportFileName -ne $null -and $ImportFileName -ne [String]::Empty)
    {
        if( ($AMPUser -ne $true -and $RemoteUser -ne $true) -and ($UserType -eq $null -or $UserType -eq [String]::Empty) )
        {
            $error = "You must specify whether the users to import are "
            $error += (ListUserTypes "or")
            
            throw $error
        }
        
        if( (Test-Path $ImportFileName) -eq $false)
        {
            throw "File $ImportFileName does not exist. Please specify a valid file path."
        }
    }
    
    return $UserType
}

function SetUserType
{
    $i = 0
        
    while($i -eq 0)
    {
        Write-Host "Select from the following user types:"
        
        $j = 1
        $Output = [String]::Empty
        foreach($gUserType in $global:UserTypes)
        {
            $Output += [string]$j + ". " + $gUserType + "`n"
            $j++    
        }
        
        Write-Host $Output
        
        $UserSelection = Read-Host "Select the user type: "
        
        for($j = 0; $j -lt $global:UserTypes.Length; $j++)
        {
            if( ($UserSelection - 1) -eq $j)
            {
                $UserType = $global:UserTypes[$j]
                break
            }
        }
        
        if($global:UserTypes -notcontains $UserType)
        {
            Write-host "Invalid selection!"
        }
        else
        {
            $i++
        }
    }
    
    return $UserType
}

function ImportUsers($ImportFileName,$UserType)
{
    Write-Host $UserType
}

try
{
    $UserType = CheckParameters
    
    if($ImportFileName -ne $null -and $ImportFileName -ne [String]::Empty)
    {
        ImportUsers $ImportFileName $UserType    
    }
    elseif($UserType -eq $null -or $UserType -eq [String]::Empty)
    {
        $UserType = SetUserType
    }
    
    switch($UserType)
    {
        "AMP"
        {
            $User = CreateAMPUser 
        }
        "Remote"
        {
            $User = CreateRemoteUser
        }
        default
        {
            $Output = "Invalid user type. Valid user types are " + (ListUserTypes)
        }
    }
    
    if($User."Success" -eq $true)
    {
        $Output = "Successfully created " + $User."FirstName" + " " + $User."LastName"
    }
    else
    {
        $Output = "Could not create the specified user!"
    }
    
    Write-Host $output
    Read-Host "Press enter to exit: "
    Exit
}
catch
{
    Write-Host $_.Exception.Message
    Read-Host "Press enter to exit: "
    Exit
}