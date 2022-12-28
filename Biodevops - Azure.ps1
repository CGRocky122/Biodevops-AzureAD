function require{
    Install-Module -Name MSOnline
    Install-Module -Name AzureAD
    Install-Module -Name ExchangeOnline
    Install-Module -Name MicrosoftTeams
}

function MainMenu{
    Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Main Menu ================"
    Write-Host "[1] - Promotions menu"
    Write-Host "[2] - Users menu"
    Write-Host "[0] - Exit"

}

function PromoMenu{
    Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Promotions Menu ================"
    Write-Host "[1] - Create promotions"
    Write-Host "[2] - Delete promotions"
    Write-Host "[0] - Return to main menu"
}

function PromotionCreationMenu{
    Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Promotions Creation Menu ================"
    Write-Host "[1] - Create a unique promotion"
    Write-Host "[2] - Create promotion in bulk"
    Write-Host "[0] - Return to main menu"
}

function UserMenu{
    Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - Users Menu ================"
    Write-Host "[1] - Create users"
    Write-Host "[2] - Disable users"
    Write-Host "[0] - Return to main menu"
}

function UserCreationMenu{
    Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - User Creation Menu ================"
    Write-Host "[1] - Create a unique user"
    Write-Host "[2] - Create users in bulk"
    Write-Host "[0] - Return to main menu"
}

function UserDisableMenu{
    Clear-Host
    Write-Host "`n================ Biodevops - AzureAD management - User Disable Menu ================"
    Write-Host "[1] - Disable a unique user"
    Write-Host "[2] - Disable users in bulk"
    Write-Host "[0] - Return to main menu"
}

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

function createsinglePromo{
    [int]$yearPromotion = Read-Host "Enter the year of the promotion"
    [int]$SelectacronymPromotion = Read-Host "[1] - PSSI - Pentesting & Security of Information Systems`n[2] - GPP - Public and Private Cloud Manager`n[3] - CPS - Project Management and Strategy`n[4] - ASI - Information Systems Architecture`nEnter a field of study"
    Switch($SelectacronymPromotion){
        1{$acronymPromotion = "PSSI"}
        2{$acronymPromotion = "GPP"}
        3{$acronymPromotion = "CPS"}
        4{$acronymPromotion = "ASI"}
    }
    $namePromotion = "$yearPromotion"+"_"+"$acronymPromotion"
    
    try{
        Write-Host "[*] Creation of an administrative unit" -ForegroundColor Yellow
        New-AzureADMSAdministrativeUnit -DisplayName $namePromotion `
                                        -Description $namePromotion | Out-Null
        $idAU = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namePromotion'" 
        Write-Host "[+] AU $namePromotion created with success" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        $nameLDS = "$acronymPromotion"+"."+"$yearPromotion"
        Write-Host "[*] Creation of a Microsoft365 group" -ForegroundColor Yellow
        New-AzureADMSGroup -DisplayName $nameLDS `
                           -MailEnabled $True `
                           -Visibility Private `
                           -MailNickname $nameLDS `
                           -GroupTypes Unified `
                           -SecurityEnabled $True | Out-Null
        $idGRP = Get-AzureADMSGroup -Filter "DisplayName eq '$nameLDS'"
        Write-Host "[+] The $nameLDS group successfully created" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Add-AzureADMSAdministrativeUnitMember -Id $idAU.Id `
                                              -RefObjectId $idGRP.Id | Out-Null
        Write-Host "[+] Adding the $namePromotion group in the $namePromotion AU success " -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Write-Host "[*] Activation of the teams group" -ForegroundColor Yellow
        TeamsConnect($Global:AADCredential)
        New-Team -Group $idGRP.Id | Out-Null
        AADConnect($Global:AADCredential)
        Write-Host "[+] The Teams $nameLDS group associated with the Microsoft365 group has been activated" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }
    Write-Host "[+] The $acronymPromotion of $yearPromotion has been created" -ForegroundColor Green
}

function createbulkPromo{
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    $counterPromos = 0
    Foreach($Promo in $dataCSV){
        [int]$yearPromotion = $Promo.yearpromotion
        [string]$acronymPromotion = $Promo.acronympromotion
        $namePromotion = "$yearPromotion"+"_"+"$acronymPromotion"
        $nameLDS = "$acronymPromotion"+"."+"$yearPromotion"

        try{
            Write-Host "[*] Creation of a promotion in progress" -ForegroundColor Yellow
            New-AzureADMSAdministrativeUnit -DisplayName $namePromotion `
                                            -Description $namePromotion | Out-Null
            $idAU = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namePromotion'"

            New-AzureADMSGroup -DisplayName $nameLDS `
                               -MailEnabled $True `
                               -Visibility Private `
                               -MailNickname $nameLDS.ToLower() `
                               -GroupTypes Unified `
                               -SecurityEnabled $True | Out-Null
            $idGRP = Get-AzureADMSGroup -Filter "DisplayName eq '$nameLDS'"

            Add-AzureADMSAdministrativeUnitMember -Id $idAU.Id `
                                                  -RefObjectId $idGRP.Id | Out-Null
            
            TeamsConnect($Global:AADCredential)
            New-Team -Group $idGRP.Id | Out-Null
            AADConnect($Global:AADCredential)
            Write-Host "[+] The $acronymPromotion of $yearPromotion has been created" -ForegroundColor Green
            $counterPromos += 1
        }catch{
            Write-Error $Error[0]
        }
    }
    Write-Host "[+] Creation success of $counterPromos promotions" -ForegroundColor Green
}

function Get-SkuID{
    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense 
    $planname = "DEVELOPERPACK_E5"
    $licenseadd = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
    $licenseadd.AddLicenses = $license
    return $licenseadd
}

function createsingleUser{
    [string]$firstnameUser = Read-Host "Enter the student's first name"
    [string]$firstnameUser = $firstnameUser.substring(0, 1).ToUpper()+$firstnameUser.substring(1).ToLower()
    [string]$lastnameUser = Read-Host "Enter the student's last name"
    [string]$lastnameUser = $lastnameUser.ToUpper()
    [string]$passwordUser = Read-Host "Enter a password (You need at least 8 characters: one number, one upper case, one lower case and one special character)"
    $passwordprofileUser = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordprofileUser.Password = $passwordUser
    [string]$yearpromotionUser = Read-Host "Enter the year of the student's graduation"
    [string]$acronympromotionUser = Read-Host "Enter the student's class acronym"
    [string]$uidUser = "U"+$yearpromotionUser+(0..9 | Get-Random -Count 10)
    [string]$uidUser = $uidUser -replace "\s",""
    [string]$mailUser = $firstnameUser.ToLower()+"."+$lastnameUser.ToLower()+"@biodevops.tech"

    try{
        Write-Host "[*] Creation a student account in progress" -ForegroundColor Yellow
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
                        -AccountEnabled $True | Out-Null
        Write-Host "[+] The account of the student $firstnameUser $lastnameUser has been successfully created" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Write-Host "[*] Assignment of a unique identifier" -ForegroundColor Yellow
        Set-AzureADUserExtension -ObjectId "$mailUser" `
                                 -ExtensionName "employeeId" `
                                 -ExtensionValue $uidUser | Out-Null
        Write-Host "[+] The user $firstnameUser $lastnameUser will have as unique identifier $uidUser" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Write-Host "[*] Granting of an Office license" -ForegroundColor Yellow
        $skuidE5 = Get-SkuID
        Set-AzureADUserLicense -ObjectId "$mailUser" `
                               -AssignedLicenses $skuidE5 | Out-Null
        Write-Host "[*] An Office365 E5 license has been assigned to $firstnameUser $lastnameUser' account" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Write-Host "[*] Assignment of the student to a promotion" -ForegroundColor Yellow
        $namepromotionUser = "$yearpromotionUser" + "_" + "$acronympromotionUser"
        $nameldsGroup = "$acronympromotionUser"+"."+"$yearpromotionUser"
        $idAU = (Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namepromotionUser'").Id
        $idUser = (Get-AzureADUser -Filter "UserPrincipalName eq '$mailUser'").ObjectId
        $idGroup = (Get-AzureADGroup -Filter "DisplayName eq '$nameldsGroup'").ObjectId
        Add-AzureADMSAdministrativeUnitMember -Id $idAU `
                                              -RefObjectId $idUser | Out-Null
        Add-AzureADGroupMember -ObjectId $idGroup `
                               -RefObjectId $idUser | Out-Null
        Write-Host "[+] Assignment of the student in the $namepromotionUser success promotion" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }
}

function createbulkUsers{
    $pathCSV = Read-Host "Enter the location of your CSV"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    $counterUsers = 0
    Foreach ($User in $dataCSV){
        [string]$firstnameUser = $User.firstname
        [string]$firstnameUser = $firstnameUser.substring(0, 1).ToUpper()+$firstnameUser.substring(1).ToLower()
        [string]$lastnameUser = $User.lastname
        [string]$lastnameUser = $lastnameUser.ToUpper()
        $passwordprofileUser = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        $passwordprofileUser.Password = $User.password
        [string]$acronympromotionUser = $User.acronympromotion
        [string]$yearpromotionUser = $User.yearpromotion
        [string]$uidUser = "U"+$yearpromotionUser+(0..9 | Get-Random -Count 10)
        [string]$uidUser = $uidUser -replace "\s",""
        [string]$mailUser = $firstnameUser.ToLower()+"."+$lastnameUser.ToLower()+"@biodevops.tech"
        
        try{
            Write-Host "[*] Creation a student account in progress" -ForegroundColor Yellow
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
                            -AccountEnabled $True | Out-Null

            Set-AzureADUserExtension -ObjectId "$mailUser" `
                                    -ExtensionName "employeeId" `
                                    -ExtensionValue $uidUser | Out-Null

            $skuidE5 = Get-SkuID
            Set-AzureADUserLicense -ObjectId "$mailUser" `
                                   -AssignedLicenses $skuidE5 | Out-Null
            Write-Host "[+] The account of the student $firstnameUser $lastnameUser has been successfully created" -ForegroundColor Green
            $counterUsers += 1
        }catch{
            Write-Error $Error[0]
        }

        try{
            Write-Host "[*] Assignment of the student to a promotion" -ForegroundColor Yellow
            $namepromotionUser = "$yearpromotionUser" + "_" + "$acronympromotionUser"
            $nameldsGroup = "$acronympromotionUser"+"."+"$yearpromotionUser"
            $idAU = (Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$namepromotionUser'").Id
            $idUser = (Get-AzureADUser -Filter "UserPrincipalName eq '$mailUser'").ObjectId
            $idGroup = (Get-AzureADGroup -Filter "DisplayName eq '$nameldsGroup'").ObjectId
            Add-AzureADMSAdministrativeUnitMember -Id $idAU `
                                                  -RefObjectId $idUser | Out-Null
            Add-AzureADGroupMember -ObjectId $idGroup `
                                   -RefObjectId $idUser | Out-Null
            Write-Host "[+] Assignment of the student in the $namepromotionUser success promotion" -ForegroundColor Green
        }catch{
            Write-Error $Error[0]
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
                            1{createsinglePromo}
                            2{createbulkPromo}
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
                            1{createsingleUser}
                            2{createbulkUsers}
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
