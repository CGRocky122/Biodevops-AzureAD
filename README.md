<h1 align="center">[4 SRC2 - Groupe 2] - Industrialisation d'identité à l'aide de PowerShell - Biodevops</h1>

<br>

## :dart: A propos ##

Rendu de projet 4 SRC2 Groupe 2 pour le cours de PowerShell.
L'objectif était de réalisé un script permettant à des équipes IT de faire de la génération et de la gestion d'une base d'identité AD/AzureAD.


## :wrench: Compatibilités ##

:x: Active Directory\
:heavy_check_mark: Azure Active Directory


## :sparkles: Fonctionnalités ##

:star2: Création d'une promotion de A à Z\
:star2: Création et désactivation d'un compte d'étudiant de manière unique ou via CSV\
:star2: Assignation de délégué par étudiant ou promotion\
:star2: Gestion des doublons\
:star2: Changement de noms des utilisateurs\
:star2: Script plannifié pour vérification des délégués et promotion avec rectification, logs et export par mail


## :rocket: Technologies ##

Nous avons utilisé le language de programmation suivant:

- [Windows PowerShell](https://www.microsoft.com/fr-fr/windows?r=1)

Et la base de connaissance suivante :

- [Azure AD](https://learn.microsoft.com/en-us/powershell/module/azuread/?view=azureadps-2.0)


## :warning: Avertissement ##

La connexion à l'AzureAD du script de vérification se fait par certificat qui authentifie la machine en tant qu'application dans le tenant.
Afin d'éviter toutes erreurs de connexions, il est recommandé de générer un nouveau certificat par machine devant exécuter le script.\
Pour se faire, nous vous recommandons de suivre les [instructions de Microsoft](https://learn.microsoft.com/en-us/powershell/azure/active-directory/signing-in-service-principal?view=azureadps-2.0) à ce propos.


## :white_check_mark: Prérequis ##

Avant de commercer, vous devez avoir l'application [Windows Terminal](https://www.microsoft.com/store/productId/9N0DX20HK701) d'installer.
Comme le script est conçu pour de l'administration d'[AzureAD](https://azure.microsoft.com/fr-fr/products/active-directory/), il n'est pas nécessaire d'avoir un serveur à disposition.
Cependant, il sera nécessaire d'avoir deux modules PowerShell pour les connexions aux différents services, mais le script s'en charge pour vous.\

:warning: Le script est rédigé en anglais afin d'éviter des problèmes d'affichage de certains caractères.


## :thread: CSVs ##

Le script permet un fonctionnement de certaines fonctions via CSV.
Nous fournissons les templates et voici les correspondances par script :

### Biodevops - Azure ###

- Création de promotion -> [Promos.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/Promos.csv)
- Création de comptes étudiant -> [Users.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/Users.csv)
- Désactivation de comptes étudiant -> [DisableUsers.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/DisableUsers.csv)
- Changement d'un étudiant de promotion -> [PromotionUsers.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/PromotionUsers.csv)
- Renommer des étudiants -> [RenameUsers.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/RenameUsers.csv)

### Biodevops - Checkup ###

- Liste des etudiants par promotion -> [PromotionStudent.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/PromotionStudent.csv)
- Liste des délégués par promotion -> [ClassDelegate.csv](https://github.com/CGRocky122/Biodevops-AzureAD/blob/main/ClassDelegate.csv)


## :checkered_flag: Commencer ##

A l'aide d'un terminal bash, cloner le repository sur votre ordinateur et créer un répertoire pour les logs et CSV du script Checkup :
```bash
# Clone this project
$ git clone https://github.com/CGRocky122/Biodevops-AzureAD.git
mkdir C:\temp
```

Puis grâce à un interpréteur PowerShell exécuter en administrateur, lancer le script :
```powershell
# Go to the script location
cd <your location>

# Execute
& '.\Biodevops - Azure.ps1'
or
& '.\Biodevops - Checkup.ps1'
```

## :memo: Author ##

- <a href="https://github.com/CGRocky122" target="_blank">CharlesG</a>
- <a href="https://github.com/GasparTA" target="_blank">GasparTA</a>
- <a href="https://github.com/zozo2756" target="_blank">EnzoH</a>

&#xa0;

<a href="#top">Retour en haut</a>