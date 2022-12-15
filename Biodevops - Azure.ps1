function require{
    Install-Module -Name MSOnline
    Install-Module -Name AzureAD
    Install-Module -Name ExchangeOnline
    Install-Module -Name MicrosoftTeams
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
        ExchConnect($Global:AADCredential)
        Write-Host "[*] Creation of a Microsoft365 group" -ForegroundColor Yellow
        New-UnifiedGroup -DisplayName $namePromotion `
                         -Alias $namePromotion `
                         -AccessType Private `
                         -PrimarySmtpAddress "$namePromotion@biodevops.tech" `
                         -Language fr-FR `
                         -Owner "administrateur@biodevops.tech" | Out-Null
        Start-Sleep 5
        $idGRP = Get-UnifiedGroup -Identity $namePromotion
        AADConnect($Global:AADCredential)
        Write-Host "[+] The $namePromotion group successfully created" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        Add-AzureADMSAdministrativeUnitMember -Id $idAU.id `
                                              -RefObjectId $idGRP.ExternalDirectoryObjectId | Out-Null
        Write-Host "[+] Adding the $namePromotion group in the $namePromotion AU success " -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }

    try{
        TeamsConnect($Global:AADCredential)
        New-Team -Group $idGRP.ExternalDirectoryObjectId | Out-Null
        AADConnect($Global:AADCredential)
        Write-Host "[+] The Teams $namePromotion group associated with the Microsoft365 group has been activated" -ForegroundColor Green
    }catch{
        Write-Error $Error[0]
    }
    Write-Host "[+] The $acronymPromotion of $yearPromotion has been created" -ForegroundColor Green

    [int]$userCreation = Read-Host "[1] - Create a unique user`n[2] - Create users in bulk`n[0] - Quit`nEnter an action"
    Switch($userCreation){
        1{createUser}
        2{createUsers}
        0{break}
    }
}

function createUser{

}

function createUsers{

}

# ======== MAIN ========
# Lancement des pré-requis
require

# Initialisation de la connexion
$AADCredential = Get-Credential -Message "Enter the login credentials of a general Azure Active Directory administrator account"
try{
    AADConnect($AADCredential)
    Write-Host "[+] Connected to the AzureAD domain" -ForegroundColor Green
}catch{
    Write-Error $Error[0]
}



[int]$MainMenu = Read-Host "[1] - Create a promotion`n[0] - Exit`nEnter an action"
Switch($MainMenu){
    1{createPromo}
    0{break}
}

# Fermeture du script
AADDisconnect
Read-Host "Appuyer sur ENTREE pour quitter ..."
