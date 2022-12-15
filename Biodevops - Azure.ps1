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
