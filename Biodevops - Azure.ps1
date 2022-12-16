function require{
    Install-Module -Name MSOnline
    Install-Module -Name AzureAD
    Install-Module -Name ExchangeOnline
    Install-Module -Name MicrosoftTeams
}

function Menu{
    Write-Host "================ Biodevops - AzureAD management ================"
    Write-Host "[1] - Create a promotion"
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

function ExchConnect{
    param(
        [PSCredential]$Credential
    )

    try{
        Connect-ExchangeOnline -Credential $Credential -ShowBanner:$false  | Out-Null
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
    [string]$firstnameUser
    [string]$lastnameUser
    [string]$yearpromotionUser
    [string]$acronympromotionUser

    
    New-AzureADUser -DisplayName "$firstnameUser $lastnameUser" `
                    -GivenName "$firstnameUser" `
                    -Surname "$lastnameUser" `
                    -UserPrincipalName "$mailUser" `
                    -PasswordProfile $passwordUser `
                    -MailNickname "$firstnameUser.$lastnameUser" `
                    -JobTitle "Etudiant" `
                    -Department "$acronympromotionUser $yearpromotionUser" `
                    -CompanyName "BioDevops" `
                    -UsageLocation FR `
                    -UserType Member
    
    Set-AzureADUserExtension -ObjectId "$mailUser" -ExtensionName "employeeId" -ExtensionValue $uidUser
}

function createUsers{

}

# ======== MAIN ========
require
$AADCredential = Get-Credential -Message "Enter the login credentials of a general Azure Active Directory administrator account"

do{
    Menu
    [int]$MainMenu = Read-Host "Enter an action"
    Switch($MainMenu){
    1{createPromo}
    0{break}
    }
}until($MainMenu -eq 0)

AADDisconnect
