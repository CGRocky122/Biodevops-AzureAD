function require{
    Install-Module -Name MSOnline
    Install-Module -Name AzureAD
    Install-Module -Name ExchangeOnline
    Install-Module -Name MicrosoftTeams
}

function Menu{
    Write-Host "================ Biodevops - AzureAD management ================"
    Write-Host "[1] - Create a promotion"
    Write-Host "[2] - Create a unique user"
    Write-Host "[3] - Create users in bulk"
    Write-Host "[0] - Exit"

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

function OfficeConnect{
    param(
        [PSCredential]$Credential
    )

    try{
        Connect-MsolService -Credential $Credential | Out-Null
    }catch{
        Write-Error $Error[0]
    }
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

function AADDisconnect{
    Disconnect-AzureAD
}

function createPromo{
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
        TeamsConnect($Global:AADCredential)
        New-Team -Group $idGRP.Id | Out-Null
        AADConnect($Global:AADCredential)
        Write-Host "[+] The Teams $nameLDS group associated with the Microsoft365 group has been activated" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }
    Write-Host "[+] The $acronymPromotion of $yearPromotion has been created" -ForegroundColor Green
}


function createUser{
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
        Set-AzureADUserExtension -ObjectId "$mailUser" -ExtensionName "employeeId" -ExtensionValue $uidUser | Out-Null
        Write-Host "[+] The user $firstnameUser $lastnameUser will have as unique identifier $uidUser" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Write-Host "[*] Granting of an Office license" -ForegroundColor Yellow
        OfficeConnect($Global:AADCredential)
        Start-Sleep 2
        Set-MsolUserLicense -UserPrincipalName "$mailUser" -AddLicenses "biodevops:DEVELOPERPACK_E5"
        Write-Host "[*] An Office365 E5 license has been assigned to $firstnameUser $lastnameUser' account" -ForegroundColor Green
        AADConnect($Global:AADCredential)
    }catch{
        Write-Error $Error[0]
    }
}

function createUsers{

}

# ======== MAIN ========
require
$AADCredential = Get-Credential -Message "Enter the login credentials of a general Azure Active Directory administrator account"
AADConnect($AADCredential)

do{
    Menu
    [int]$MainMenu = Read-Host "Enter an action"
    Switch($MainMenu){
    1{createPromo}
    2{createUser}
    3{createUsers}
    0{break}
    }
}until($MainMenu -eq 0)

AADDisconnect
