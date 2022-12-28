# Prerequisites
function require{
    Install-Module -Name MSOnline
    Install-Module -Name AzureAD
    Install-Module -Name ExchangeOnline
    Install-Module -Name MicrosoftTeams
}

# Menus
function MainMenu{
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Main Menu ================"
    Write-Host "[1] - Promotions menu"
    Write-Host "[2] - Users menu"
    Write-Host "[0] - Exit"

}

function PromoMenu{
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Promotions Menu ================"
    Write-Host "[1] - Create promotions"
    Write-Host "[2] - Delete promotions"
    Write-Host "[0] - Return to main menu"
}

function PromotionCreationMenu{
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Promotions Creation Menu ================"
    Write-Host "[1] - Create a unique promotion"
    Write-Host "[2] - Create promotion in bulk"
    Write-Host "[0] - Return to main menu"
}

function UserMenu{
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Users Menu ================"
    Write-Host "[1] - Create users"
    Write-Host "[2] - Disable users"
    Write-Host "[0] - Return to main menu"
}

function UserCreationMenu{
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - User Creation Menu ================"
    Write-Host "[1] - Create a unique user"
    Write-Host "[2] - Create users in bulk"
    Write-Host "[0] - Return to main menu"
}

function UserDisableMenu{
    #Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - User Disable Menu ================"
    Write-Host "[1] - Disable a unique user"
    Write-Host "[2] - Disable users in bulk"
    Write-Host "[0] - Return to main menu"
}

# Connection module Microsoft
function AADConnect{
    param(
        [PSCredential]$Credential
    )

    try{
        Connect-AzureAD -Credential $Credential | Out-Null
    }catch{
        Write-Error $Error[0]
    }
}

function AADDisconnect{
    Disconnect-AzureAD
}

function TeamsConnect{
    param(
        [PSCredential]$Credential
    )

    try{
        Connect-MicrosoftTeams -Credential $Credential  | Out-Null
    }catch{
        Write-Error $Error[0]
    }
}

# Promotion
function CreatePromotion {
    param (
        [int]$yearPromotion,
        [string]$acronymPromotion
    )

    $namePromotion = "$yearPromotion"+"_"+"$acronymPromotion"
    $nameGroup = "$acronymPromotion"+"."+"$yearPromotion"

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

function CreateSinglePromotion{
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

function CreatePromotionFromCSV{
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    $counterPromos = 0
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
    Write-Host "[+] Creation success of $counterPromos promotions" -ForegroundColor Green
}

# User
function Get-SkuID{
    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense 
    $planname = "DEVELOPERPACK_E5"
    $licenseadd = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
    $licenseadd.AddLicenses = $license
    return $licenseadd
}

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
    $uidUser = ("U"+$yearpromotionUser+(0..9 | Get-Random -Count 10)) -replace "\s",""
    $mailUser = $firstnameUser.ToLower()+"."+$lastnameUser.ToLower()+"@biodevops.tech"

    $namepromotionUser = "$yearpromotionUser"+"_"+"$acronympromotionUser"
    $namegroupUser = "$acronympromotionUser"+"."+"$yearpromotionUser"
    $au = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namepromotionUser'"
    $group = Get-AzureADGroup -Filter "DisplayName eq '$namegroupUser'"

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

function CreateSingleUser{
    [string]$firstnameUser = Read-Host "Enter the student's first name"
    [string]$lastnameUser = Read-Host "Enter the student's last name"
    [string]$passwordUser = Read-Host "Enter a password (You need at least 8 characters: one number, one upper case, one lower case and one special character)"
    [string]$yearpromotionUser = Read-Host "Enter the year of the student's graduation"
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

function CreateUserFromCSV{
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    $counterUsers = 0
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
    Write-Host "[+] Creation success of $counterUsers users" -ForegroundColor Green
}

function desactivatesingleUser{
    [string]$upnUser = Read-Host "Enter the UPN of the disabled user"
    $idUser = (Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'").ObjectId

    try{
        Write-Host "[*] Deactivation of a user" -ForegroundColor Yellow
        Set-AzureADUser -ObjectId $idUser `
                        -AccountEnabled $False | Out-Null
        Write-Host "[+] The account of the student "((Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'").DisplayName)" has been successfully deactivated" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }
}

function desactivatebulkUsers{
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    $counterUser = 0
    Foreach($User in $dataCSV){
        [string]$upnUser = $User.UPN
        $idUser = (Get-AzureADUser -Filter "UserPrincipalName eq '$upnUser'").ObjectId

        try{
            Set-AzureADUser -ObjectId $idUser `
                            -AccountEnabled $False | Out-Null
        }catch{
            Write-Error $Error[0]
        }
        $counterUser += 1
    }
    Write-Host "[+] Successful deactivation of $counterUser accounts" -ForegroundColor Green
}

# ======== MAIN ========
require
$Global:AADCredential = Get-Credential -Message "Enter the login credentials of a general Azure Active Directory administrator account"
AADConnect($Global:AADCredential)

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
                            1{desactivatesingleUser}
                            2{desactivatebulkUsers}
                            0{break}
                        }
                    }until($UserDisableMenu -eq 0)
                }
                0{break}
            }
        }until($UserMenu -eq 0)
    }
    0{break}
    }
}until($MainMenu -eq 0)

AADDisconnect
