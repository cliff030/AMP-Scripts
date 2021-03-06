. "\\AMP\Support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\LoadADModule.ps1"

LoadADModule

function CheckCurrentUserPermissions()
{
    $RequiredPermissions = @("GenericAll", "CreateChild, DeleteChild", "ReadProperty, WriteProperty")

    $username = $env:username

    $user = Get-ADUser -Filter {samAccountName -eq $username}

    $groups = @()
    Get-ADPrincipalGroupMembership $user.samAccountName | Select Name | ForEach-Object {$groups += "AMP\" + $_.Name}

    $ACLs = Get-ACL -Path "AD:\OU=Remote Users,DC=accountmanagementplus,DC=com" | Select-Object -ExpandProperty Access | Where-Object {$_.AccessControlType -eq "Allow" -and $RequiredPermissions -contains $_.ActiveDirectoryRights -and $groups -contains $_.IdentityReference.Value}

    $EffectiveACLs = @()
    foreach($ACL in $ACLs)
    {
        if($EffectiveACLs.Length -eq 0)
        {
            $EffectiveACLs += $ACL
        }
        else
        {
            $FoundACL = $false
        
            foreach($EffectiveACL in $EffectiveACLs)
            {
                if($EffectiveACL.ActiveDirectoryRights -eq $ACL.ActiveDirectoryRights)
                {
                    $FoundACL = $true
                    break
                }
            }
            
            if($FoundACL -eq $false)
            {
                $EffectiveACLs += $ACL
            }
        }
    }

    if($EffectiveACLs.Length -lt 3)
    {
        return $false 
    }
    else
    {
        return $true
    }
}

function CheckIfUserExists($Username,$OU) {
    try {
        $User = (Get-ADUser -SearchBase $OU -Filter {SamAccountName -eq $Username})
        
        if($User -ne $null) {
            return $true
        } else {
            return $false
        }
        
        return $true
    }
    catch [exception] {
        return $false
    }
}

function SetUser($OU) {
    $i = 0
    
    while($i -eq 0) {
        $Username = Read-Host -Prompt "Enter the username: "
        $Username = $Username -replace "^AMP\\"
        
        $SamAccountName = ($Username -Replace " ").ToUpper()
        $FirstName = ($Username -Split " ")[0]
        $LastName = ($Username -Split " ")[1]
    
        if( (CheckIfUserExists $SamAccountName $OU) -eq $true) {
            Write-Host "This user already exists!"
        } else {
            $i++
        }
    }
    
    $User = @{"SamAccountName"=$SamAccountName;"FirstName"=$SamAccountName;"LastName"=$null;"FullName"=$SamAccountName}
    
    Return $User
}


function SetOU {
    $OU = "ou=" + $global:Company."ShortName" + ",ou=Remote Users,dc=accountmanagementplus,dc=com"
    
    return $OU
}

function SetPassword {
    switch($Company."ShortName") {
        "Select" {
            $password = "docusignisfun"
        }
        "Liberty" {
            $password = "4mplF1n"
        }
        "Karma" {
            $password = "spring"
        }
        "FFN" {
            $password = "4mplF1n"
        }
        default {
            throw "Invalid company selected!"
        }
    }
    
    $password = (ConvertTo-SecureString $password -AsPlainText -force)
    
    return $password
}

function SetEncryptedPassword {
    switch($Company."ShortName") {
        "Select" {
            $EncryptedPassword = "01000000D08C9DDF0115D1118C7A00C04FC297EB01000000E5107A88C259EE47B62019F0FCAF54420400000008000000700073007700000003660000C000000010000000C3DB13F9B39C923C81653973DB62998D0000000004800000A000000010000000F2EA95C221466C354B50EA7BC1457A3020000000AE713A0813D1DAC590588554BDA028B427A01F5DB71D2E028EB3DCE31E225EC2140000001A8F7CBA63354975A8938A7163A3E5078E962BF8"
        }
        "Liberty" {
            $EncryptedPassword = "01000000D08C9DDF0115D1118C7A00C04FC297EB01000000E5107A88C259EE47B62019F0FCAF54420400000008000000700073007700000003660000C0000000100000001643AD5D83BB390740032BB60EB60ADA0000000004800000A0000000100000003B0C48E4C6919EDF2EC5B876EC5BB22010000000110CAD6FBD846622762EE5C31D4D1B261400000029D627BDB6F57728F5131392849BD3FCBC639301"
        }
        "Karma" {
            $EncryptedPassword = "01000000D08C9DDF0115D1118C7A00C04FC297EB01000000E5107A88C259EE47B62019F0FCAF54420400000008000000700073007700000003660000C000000010000000931B6D85B6ED2BB7C947D8137EE84C850000000004800000A000000010000000D390C69EFF0C667E0A3919272BAA0198100000000BE998F90BCA98EFB314C95317FF2038140000006C1A0A0405DFFA85C21BF926AEC14A1398C7F88F"
        }
        "FFN" {
            $EncryptedPassword = "01000000D08C9DDF0115D1118C7A00C04FC297EB01000000E5107A88C259EE47B62019F0FCAF54420400000008000000700073007700000003660000C0000000100000001643AD5D83BB390740032BB60EB60ADA0000000004800000A0000000100000003B0C48E4C6919EDF2EC5B876EC5BB22010000000110CAD6FBD846622762EE5C31D4D1B261400000029D627BDB6F57728F5131392849BD3FCBC639301"
        }
        default {
            throw "Invalid company selected!"
        }
    }
    
    return $EncryptedPassword
}

function SetUserProfile {
    $UserProfile = "\\AMP\" + $Company."Name" + '\User Profiles\%username%'
    
    Return $UserProfile
}

if( (CheckCurrentUserPermissions) -eq $false)
{
    Write-Host "You do not have the permissions necessary to run this program. Please contact your administrator."
    Read-Host "Press enter to close: "
    Exit
}

SelectCompany

$Group = (Get-ADGroup -Identity $global:Company."Group")
$PrimaryGroupID = $Group.SID.Value.Substring($Group.SID.Value.LastIndexOf('-')+1)

$OU = SetOU

$Password = SetPassword

$UserProfile = SetUserProfile

$User = SetUser $OU

New-ADUser -Path $OU -Enabled $true -AccountExpirationDate $null -SamAccountName $User."SamAccountName" -GivenName $User."FirstName" -DisplayName $User."FullName" -Name $User."FullName" -PasswordNeverExpires $true -AccountPassword $Password -ChangePasswordAtLogon $false -Profile $UserProfile -UserPrincipalName ($User."SamAccountName" + "@accountmanagementplus.com")

Add-ADGroupMember -Identity "CSOFT Remote" $User."SamAccountName"
Add-ADGroupMember -Identity $Company."Group" $User."SamAccountName"

$Output = "Successfully created " + $User."SamAccountName"

Write-Host $Output

Read-Host "Press enter to exit: "