# Prerequisites
function require {
    Install-Module -Name AzureAD
    Install-Module -Name MicrosoftTeams
}

# Menus
function MainMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Main Menu ================"
    Write-Host "[1] - Promotions menu"
    Write-Host "[2] - Users menu"
    Write-Host "[3] - Delegate menu"
    Write-Host "[0] - Exit"

}

function PromoMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Promotions Menu ================"
    Write-Host "[1] - Create promotions"
    Write-Host "[2] - Delete promotions"
    Write-Host "[0] - Return to main menu"
}

function PromotionCreationMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Promotions Creation Menu ================"
    Write-Host "[1] - Create a unique promotion"
    Write-Host "[2] - Create promotion in bulk"
    Write-Host "[0] - Return to main menu"
}

function UserMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Users Menu ================"
    Write-Host "[1] - Create users"
    Write-Host "[2] - Disable users"
    Write-Host "[3] - Change promotion"
    Write-Host "[0] - Return to main menu"
}

function UserCreationMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - User Creation Menu ================"
    Write-Host "[1] - Create a unique user"
    Write-Host "[2] - Create users in bulk"
    Write-Host "[0] - Return to main menu"
}

function UserDisableMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - User Disable Menu ================"
    Write-Host "[1] - Disable a unique user"
    Write-Host "[2] - Disable users in bulk"
    Write-Host "[0] - Return to main menu"
}

function ChangeUserPromotion {
       #Clear-Host
       Write-Host "`n================ Biodevops - AzureAD management - Change User's promotion Menu ================"
       Write-Host "[1] - Change a unique user"
       Write-Host "[2] - Change users in bulk"
       Write-Host "[0] - Return to main menu" 
}

function DelegateMenu {
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Delegate Menu ================"
    Write-Host "[1] - Assign delegate to unique user"
    Write-Host "[2] - Assign delegate to a whole promotion"
    Write-Host "[0] - Return to main menu"
}

# Connection modules Microsoft
function AADConnect {
    try{
        Connect-AzureAD -Credential $Global:AADCredential | Out-Null
    }catch{
        Write-Error "Failed to connect to AzureAD"
        $SelectAzureAD = Read-Host "Would you like to retry ?"
        Switch($SelectAzureAD) {
            "Y"{AADConnect}
            "N"{break}
        }
    }
}

function AADDisconnect {
    Disconnect-AzureAD
}

function TeamsConnect {
    param(
        [PSCredential]$Credential
    )

    try{
        Connect-MicrosoftTeams -Credential $Credential  | Out-Null
    }catch{
        Write-Error $Error[0]
    }
}

# Replace wrong characters
function Remove-StringLatinCharacters {
    param (
        [string]$String
    )

    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

# Create Promotion
function CreatePromotion {
    param (
        [int]$yearPromotion,
        [string]$acronymPromotion
    )

    $namePromotion = "$yearPromotion"+"_"+"$acronymPromotion"
    $nameGroup = "$acronymPromotion"+"."+"$yearPromotion"

    Write-Warning "[*] Creating a new promotion in progress"

    New-AzureADMSAdministrativeUnit -DisplayName $namePromotion `
                                    -Description $namePromotion `
                                    -ErrorAction Stop `
                                    -ErrorVariable createAUError | Out-Null
    $au = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namePromotion'"
    if ($createAUError) {
        return $createAUError
    }

    New-AzureADMSGroup -DisplayName $nameGroup `
                       -MailEnabled $True `
                       -Visibility Private `
                       -MailNickname $nameGroup `
                       -GroupTypes Unified `
                       -SecurityEnabled $True `
                       -ErrorAction Stop `
                       -ErrorVariable createGroupError | Out-Null
    $group = Get-AzureADMSGroup -Filter "DisplayName eq '$nameGroup'"
    if ($createGroupError) {
        return $createGroupError
    }

    Add-AzureADMSAdministrativeUnitMember -Id $au.Id `
                                          -RefObjectId $group.Id `
                                          -ErrorAction Stop `
                                          -ErrorVariable addMemberError | Out-Null
    if ($addMemberError) {
        return $addMemberError
    }

    TeamsConnect($Global:AADCredential)
    New-Team -Group $group.Id `
             -ErrorAction Stop `
             -ErrorVariable createTeamError | Out-Null
    AADConnect($Global:AADCredential)
    if ($createTeamError) {
        return $createTeamError
    }
}

function CreateSinglePromotion {
    [int]$yearPromotion = Read-Host "Enter the year of the promotion"
    [int]$SelectacronymPromotion = Read-Host "[1] - PSSI - Pentesting & Security of Information Systems`n[2] - GPP - Public and Private Cloud Manager`n[3] - CPS - Project Management and Strategy`n[4] - ASI - Information Systems Architecture`nEnter a field of study"
    Switch($SelectacronymPromotion){
        1{$acronymPromotion = "PSSI"}
        2{$acronymPromotion = "GPP"}
        3{$acronymPromotion = "CPS"}
        4{$acronymPromotion = "ASI"}
    }
    
    $result = CreatePromotion -yearPromotion $yearPromotion -acronymPromotion $acronymPromotion
    if ($result) {
        Write-Error $result
    } else {
        Write-Host "[+] The $acronymPromotion of $yearPromotion has been created" -ForegroundColor Green
    }
}

function CreatePromotionFromCSV {
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    Foreach($Promo in $dataCSV){
        [int]$yearPromotion = $Promo.yearpromotion
        [string]$acronymPromotion = $Promo.acronympromotion
        
        $result = CreatePromotion -yearPromotion $yearPromotion -acronymPromotion $acronymPromotion
        if ($result) {
            Write-Error $result
        } else {
            Write-Host "[+] The $acronymPromotion of $yearPromotion has been created" -ForegroundColor Green
        }
    }
}

# Get SkuID of E5
function Get-SkuID {
    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense 
    $planname = "DEVELOPERPACK_E5"
    $licenseadd = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
    $licenseadd.AddLicenses = $license
    return $licenseadd
}

# Create User
function CreateUser {
    param (
        [string]$firstnameUser,
        [string]$lastnameUser,
        [string]$passwordUser,
        [string]$yearpromotionUser,
        [string]$acronympromotionUser
    )

    $firstnameUser = $firstnameUser.substring(0, 1).ToUpper()+$firstnameUser.substring(1).ToLower()
    $lastnameUser = $lastnameUser.ToUpper()
    $passwordprofileUser = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordprofileUser.Password = $passwordUser
    $mailUser = (Remove-StringLatinCharacters($firstnameUser.ToLower()))+"."+(Remove-StringLatinCharacters($lastnameUser.ToLower()))

    do {
        $uidUser = ("U"+$yearpromotionUser+(0..9 | Get-Random -Count 10)) -replace "\s",""
        $result = CheckEmployeeID -UID $uidUser
    } until ($result -eq $True)

    $x = 1
    $checkUPN = CheckUPN -UPN "$mailUser@biodevops.tech"
    if ($checkUPN -eq $False) {
        $SelectnewUser = Read-Host "There is already a user with this UPN, do you still want to create the account ? [Y] Yes [N] No"
        Switch ($SelectnewUser) {
            "Y" {
                do {
                    $x +=1
                    $newmailUser = $mailUser+"$x"
                    $checkUPN = CheckUPN -UPN "$newmailUser@biodevops.tech"
                } until ($checkUPN -eq $True)
                
                $mailUser = $newmailUser+"@biodevops.tech"
                $namepromotionUser = "$yearpromotionUser"+"_"+"$acronympromotionUser"
                $namegroupUser = "$acronympromotionUser"+"."+"$yearpromotionUser"
                $au = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namepromotionUser'"
                $group = Get-AzureADGroup -Filter "DisplayName eq '$namegroupUser'"

                Write-Warning = "[*] Creating a new user in progress"

                New-AzureADUser -DisplayName "$firstnameUser $lastnameUser" `
                                -GivenName "$firstnameUser" `
                                -Surname "$lastnameUser" `
                                -UserPrincipalName "$mailUser" `
                                -PasswordProfile $passwordprofileUser `
                                -MailNickname "$firstnameUser.$lastnameUser" `
                                -JobTitle "Etudiant" `
                                -Department "$acronympromotionUser $yearpromotionUser" `
                                -CompanyName "BioDevops" `
                                -UsageLocation FR `
                                -UserType Member `
                                -AccountEnabled $True `
                                -ErrorAction Stop `
                                -ErrorVariable createUserError | Out-Null
                $user = Get-AzureADUser -Filter "UserPrincipalName eq '$mailUser'"
                if ($createUserError) {
                    return $createUserError
                }

                Set-AzureADUserExtension -ObjectId $user.ObjectId `
                                         -ExtensionName "employeeId" `
                                         -ExtensionValue $uidUser `
                                         -ErrorAction Stop `
                                         -ErrorVariable setExtensionError | Out-Null
                if ($setExtensionError) {
                    return $setExtensionError
                }

                $skuidE5 = Get-SkuID
                Set-AzureADUserLicense -ObjectId $user.ObjectId `
                                       -AssignedLicenses $skuidE5 `
                                       -ErrorAction Stop `
                                       -ErrorVariable setLicenseError | Out-Null 
                if ($setLicenseError) {
                    return $setLicenseError
                }

                Add-AzureADMSAdministrativeUnitMember -Id $au.Id `
                                                      -RefObjectId $user.ObjectId `
                                                      -ErrorAction Stop `
                                                      -ErrorVariable addAUMemberError | Out-Null
                if ($addAUMemberError) {
                    return $addAUMemberError
                }

                Add-AzureADGroupMember -ObjectId $group.ObjectId `
                                       -RefObjectId $user.ObjectId `
                                       -ErrorAction Stop `
                                       -ErrorVariable addGroupMemberError | Out-Null
                if ($addGroupMemberError) {
                    return $addGroupMemberError
                }
            }
            "N" {break}
        }
    }
}

function CreateSingleUser {
    [string]$firstnameUser = Read-Host "Enter the student's first name"
    [string]$lastnameUser = Read-Host "Enter the student's last name"
    [string]$passwordUser = Read-Host "Enter a password (You need at least 8 characters: one number, one upper case, one lower case and one special character)"
    [string]$yearpromotionUser = Read-Host "Enter the year of the student's promotion"
    [string]$SelectacronympromotionUser = Read-Host "[1] - PSSI - Pentesting & Security of Information Systems`n[2] - GPP - Public and Private Cloud Manager`n[3] - CPS - Project Management and Strategy`n[4] - ASI - Information Systems Architecture`nEnter a field of study"
    Switch($SelectacronympromotionUser){
        1{$acronympromotionUser = "PSSI"}
        2{$acronympromotionUser = "GPP"}
        3{$acronympromotionUser = "CPS"}
        4{$acronympromotionUser = "ASI"}
    }

    $result = CreateUser -firstnameUser $firstnameUser -lastnameUser $lastnameUser -passwordUser $passwordUser -yearpromotionUser $yearpromotionUser -acronympromotionUser $acronympromotionUser
    if ($result) {
        Write-Error $result
    } else {
        Write-Host "[+] The account of the student $firstnameUser $lastnameUser has been successfully created" -ForegroundColor Green
    }   
}

function CreateUserFromCSV {
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    Foreach ($User in $dataCSV){
        [string]$firstnameUser = $User.firstname
        [string]$lastnameUser = $User.lastname
        [string]$passwordUser = $User.password
        [string]$acronympromotionUser = $User.acronympromotion
        [string]$yearpromotionUser = $User.yearpromotion
        
        $result = CreateUser -firstnameUser $firstnameUser -lastnameUser $lastnameUser -passwordUser $passwordUser -yearpromotionUser $yearpromotionUser -acronympromotionUser $acronympromotionUser
        if ($result) {
            Write-Error $result
        } else {
            Write-Host "[+] The account of the student $firstnameUser $lastnameUser has been successfully created" -ForegroundColor Green
        }
    }
}

# Check User's EmployeeID
function CheckEmployeeID {
    param (
        [string]$UID
    )

    $users = Get-AzureADUser

    Foreach ($u in $users) { 
        $u = Get-AzureADUserExtension -ObjectId $u.ObjectId
        if ($u.employeeId -eq $UID){
            return $False
            break
        }
    }
    return $True
}

function CheckUPN {
    param (
        [string]$UPN
    )

    $users = Get-AzureADUser

    Foreach ($u in $users) {
        if ($u.UserPrincipalName -eq $UPN) {
            return $False
            break
        }
    }
    return $True
}

# Disable User
function DisableUser {
    param (
        [string]$upnUser
    )

    $user = Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'"

    Write-Warning "[*] Deactivation of a user in progress"

    Set-AzureADUser -ObjectId $user.ObjectId `
                    -AccountEnabled $False `
                    -ErrorAction Stop `
                    -ErrorVariable setUserError | Out-Null
    if ($setUserError) {
        return $setUserError
    }
}

function DisableSingleUser {
    [string]$upnUser = Read-Host "Enter the UPN of the disabled user"
    
    $result = DisableUser -upnUser $upnUser
    if ($result) {
        Write-Error $result
    } else {
        Write-Host "[+] The account of the student"((Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'").DisplayName)"has been successfully deactivated" -ForegroundColor Green
    }
}

function DisableUserFromCSV {
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    Foreach($User in $dataCSV){
        [string]$upnUser = $User.UPN

        $result = DisableUser -upnUser $upnUser
        if ($result) {
            Write-Error $result
        } else {
            Write-Host "[+] The account of the student"((Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'").DisplayName)"has been successfully deactivated" -ForegroundColor Green
        }
    }
}

# Set Manager
function SetManager {
    param (
        [string]$upnUser,
        [string]$upnDelegate
    )
 
    $delegate = Get-AzureADUser -Filter "UserPrincipalName eq '$upnDelegate'"
    $user = Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'"
    
    Write-Warning "[*] Assignment of a delegate in progress"

    Set-AzureADUserManager -ObjectId $user.ObjectId `
                           -RefObjectId $delegate.ObjectId `
                           -ErrorAction Stop `
                           -ErrorVariable setManagerError | Out-Null
    if ($setManagerError) {
        return $setManagerError
    }
}

function SetUserManager {
    [string]$upnUser = Read-Host "Enter the student's UPN"
    [string]$upnDelegate = Read-host "Enter the delegate's UPN"

    $result = SetManager -upnUser $upnUser -upnDelegate $upnDelegate
    if ($result) {
        Write-Error $result
    } else {
        Write-Host "[+]"((Get-AzureADUser -Filter "UserPrincipalName eq '$upnDelegate'").DisplayName)"is now the delegate of"((Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'").DisplayName) -ForegroundColor Green
    }
}

function SetPromotionManager {
    [int]$yearPromotion = Read-Host "Enter the year of the promotion"
    [int]$SelectacronymPromotion = Read-Host "[1] - PSSI - Pentesting & Security of Information Systems`n[2] - GPP - Public and Private Cloud Manager`n[3] - CPS - Project Management and Strategy`n[4] - ASI - Information Systems Architecture`nEnter a field of study"
    Switch($SelectacronymPromotion){
        1{$acronymPromotion = "PSSI"}
        2{$acronymPromotion = "GPP"}
        3{$acronymPromotion = "CPS"}
        4{$acronymPromotion = "ASI"}
    }
    [string]$upnDelegate = Read-Host "Enter the delegate's UPN"
    
    $nameGroup = "$acronymPromotion"+"."+"$yearPromotion"
    $namePromotion = "$yearPromotion"+"_"+"$acronymPromotion"

    $Promotion = Get-AzureADGroupMember -ObjectId (Get-AzureADGroup -Filter "DisplayName eq '$nameGroup'").ObjectId | Select-Object UserPrincipalName

    Foreach ($User in $Promotion) {
        $User = $user.UserPrincipalName
        if ($User -eq $upnDelegate) {
            continue
        }
        $result = SetManager -upnUser $User -upnDelegate $upnDelegate
        if ($result) {
            Write-Error $result
        }
    }
    Write-Host "[+]"((Get-AzureADUser -Filter "UserPrincipalName eq '$upnDelegate'").DisplayName)"is now the delegate for the promotion of"((Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namePromotion'").DisplayName) -ForegroundColor Green
}

# Change Promotion
function ChangePromotion {
    param (
        $oldPromotion,
        $oldGroup,
        $newPromotion,
        $newGroup,
        $User
    )

    $newDepartment = $newGroup.replace("."," ")
    $oldPromotion = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$oldPromotion'"
    $oldGroup = Get-AzureADMSGroup -Filter "DisplayName eq '$oldGroup'"
    $newPromotion = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$newPromotion'"
    $newGroup = Get-AzureADMSGroup -Filter "DisplayName eq '$newGroup'"
    $User = Get-AzureADUser -Filter "UserPrincipalName eq '$User'"

    Write-Warning "[*] Promotion change in progress"

    Remove-AzureADUserManager -ObjectId $User.ObjectId `
                              -ErrorAction Continue `
                              -ErrorVariable removeManagerError | Out-Null
    if ($removeManagerError) {
        return $removeManagerError
    }

    Remove-AzureADMSAdministrativeUnitMember -Id $oldPromotion.Id `
                                             -MemberId $User.ObjectId `
                                             -ErrorAction Stop `
                                             -ErrorVariable removeAUMemberError | Out-Null
    if ($removeAUMemberError) {
        return $removeAUMemberError
    }

    Remove-AzureADGroupMember -ObjectId $oldGroup.Id `
                              -MemberId $User.ObjectId `
                              -ErrorAction Stop `
                              -ErrorVariable removeGroupMemberError | Out-Null
    if ($removeGroupMemberError) {
        return $removeGroupMemberError
    }

    Add-AzureADMSAdministrativeUnitMember -Id $newPromotion.Id `
                                          -RefObjectId $User.ObjectId `
                                          -ErrorAction Stop `
                                          -ErrorVariable addAUMemberError | Out-Null
    if ($addAUMemberError) {
        return $addAUMemberError
    }

    Add-AzureADGroupMember -ObjectId $newGroup.Id `
                           -RefObjectId $User.ObjectId `
                           -ErrorAction Stop `
                           -ErrorVariable addGroupMemberError | Out-Null
    if ($addGroupMemberError) {
        return $addGroupMemberError
    }

    Set-AzureADUser -ObjectId $User.ObjectId `
                    -Department $newDepartment `
                    -ErrorAction Stop `
                    -ErrorVariable setUserDepartmentError | Out-Null
    if ($setUserDepartmentError) {
        return $setUserDepartmentError
    }
}

function ChangePromotionSingleUser {
    [string]$User = Read-Host "Enter the user's UPN"
    Write-Host "`nInformation of the former promotion"
    [string]$oldYearPromotion = Read-Host "Enter the year of the student's promotion"
    [string]$selectoldAcronymPromotion = Read-Host "[1] - PSSI - Pentesting & Security of Information Systems`n[2] - GPP - Public and Private Cloud Manager`n[3] - CPS - Project Management and Strategy`n[4] - ASI - Information Systems Architecture`nEnter a field of study"
    Switch($selectoldAcronymPromotion){
        1{$oldAcronymPromotion = "PSSI"}
        2{$oldAcronymPromotion = "GPP"}
        3{$oldAcronymPromotion = "CPS"}
        4{$oldAcronymPromotion = "ASI"}
    }
    Write-Host "`nInformation of the new promotion"
    [string]$newYearPromotion = Read-Host "Enter the year of the student's promotion"
    [string]$selectnewAcronymPromotion = Read-Host "[1] - PSSI - Pentesting & Security of Information Systems`n[2] - GPP - Public and Private Cloud Manager`n[3] - CPS - Project Management and Strategy`n[4] - ASI - Information Systems Architecture`nEnter a field of study"
    Switch($selectnewAcronymPromotion){
        1{$newAcronymPromotion = "PSSI"}
        2{$newAcronymPromotion = "GPP"}
        3{$newAcronymPromotion = "CPS"}
        4{$newAcronymPromotion = "ASI"}
    }

    $oldPromotionName = "$oldYearPromotion"+"_"+"$oldAcronymPromotion"
    $oldGroupName = "$oldAcronymPromotion"+"."+"$oldYearPromotion"
    $newPromotionName = "$newYearPromotion"+"_"+"$newAcronymPromotion"
    $newGroupName = "$newAcronymPromotion"+"."+"$newYearPromotion"

    $result = ChangePromotion -oldPromotion $oldPromotionName -oldGroup $oldGroupName -newPromotion $newPromotionName -newGroup $newGroupName -User $User
    if ($result) {
        Write-Error $result
    } else {
        Write-Host "[+] Student"((Get-AzureADUser -Filter "UserPrincipalName eq '$User'").DisplayName)"passed from the class of $oldPromotionName to $newPromotionName" -ForegroundColor Green
    }
}

function ChangePromotionFromCSV {
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    Foreach($U in $dataCSV){
        [string]$oldYearPromotion = $U.oldYearPromotion
        [string]$oldAcronymPromotion = $U.oldAcronymPromotion
        [string]$newYearPromotion = $U.newYearPromotion
        [string]$newAcronymPromotion = $U.newAcronymPromotion
        [string]$User = $U.UPN

        $oldPromotionName = "$oldYearPromotion"+"_"+"$oldAcronymPromotion"
        $oldGroupName = "$oldAcronymPromotion"+"."+"$oldYearPromotion"
        $newPromotionName = "$newYearPromotion"+"_"+"$newAcronymPromotion"
        $newGroupName = "$newAcronymPromotion"+"."+"$newYearPromotion"

        $result = ChangePromotion -oldPromotion $oldPromotionName -oldGroup $oldGroupName -newPromotion $newPromotionName -newGroup $newGroupName -User $User
        if ($result) {
            Write-Error $result
        } else {
            Write-Host "[+] Student"((Get-AzureADUser -Filter "UserPrincipalName eq '$User'").DisplayName)"passed from the class of $oldPromotionName to $newPromotionName"
        }
    }
}

# ======== MAIN ========
require
$Global:AADCredential = Get-Credential -Message "Enter the login credentials of a general Azure Active Directory administrator account"
AADConnect

do{
    MainMenu
    [int]$MainMenu = Read-Host "Enter an action"
    Switch($MainMenu){
        1{
            do{
                PromoMenu
                [int]$PromoMenu = Read-Host "Enter an action"
                Switch($PromoMenu){
                    1{
                        do {
                            PromotionCreationMenu
                            [int]$PromoCreateMenu = Read-Host "Enter an action"
                            Switch($PromoCreateMenu){
                                1{CreateSinglePromotion}
                                2{CreatePromotionFromCSV}
                                0{break}
                            }
                        }until($PromoCreateMenu -eq 0)
                    }
                    0{break}
                }
            }until($PromoMenu -eq 0)
        }
        2{
            do{
                UserMenu
                [int]$UserMenu = Read-Host "Enter an action"
                Switch($UserMenu){
                    1{
                        do{
                            UserCreationMenu
                            [int]$UserCreateMenu = Read-Host "Enter an action"
                            Switch($UserCreateMenu){
                                1{CreateSingleUser}
                                2{CreateUserFromCSV}
                                0{break}
                            }
                        }until($UserCreateMenu -eq 0)
                    }
                    2{
                        do{
                            UserDisableMenu
                            [int]$UserDisableMenu = Read-Host "Enter an Action"
                            Switch($UserDisableMenu){
                                1{DisableSingleUser}
                                2{DisableUserFromCSV}
                                0{break}
                            }
                        }until($UserDisableMenu -eq 0)
                    }
                    3{
                        do {
                            ChangeUserPromotion
                            [int]$ChangeUserPromotion = Read-Host "Enter an action"
                            Switch($ChangeUserPromotion){
                                1{ChangePromotionSingleUser}
                                2{ChangePromotionFromCSV}
                                0{break}
                            }
                        }until($ChangeUserPromotion -eq 0)
                    }
                    0{break}
                }
            }until($UserMenu -eq 0)
        }
        3{
            do{
                DelegateMenu
                [int]$DelegateMenu = Read-Host "Enter an action"
                Switch($DelegateMenu){
                    1{SetUserManager}
                    2{SetPromotionManager}
                    0{break}
                }
            }until($DelegateMenu -eq 0)
        }
        0{break}
    }
}until($MainMenu -eq 0)

AADDisconnect
