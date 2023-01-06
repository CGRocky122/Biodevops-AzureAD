function require {
    Install-Module -Name AzureAD
    Install-Module -Name MicrosoftTeams
}

function Credential {
    param (
        [string]$Username,
        [string]$Password
    )

    $secureStringPwd = $Password | ConvertTo-SecureString -AsPlainText -Force 
    $creds = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $secureStringPwd

    return $creds
}

function LogMessage {
    param (
        [string]$Filename,
        [string]$Message
    )
    Add-Content -Path "C:\temp\$Filename.txt" "$([datetime]::Now) : $Message"
}

function ExtractLog {
    param (
        [string]$file,
        [PSCredential]$Credential
    )

    $From = "notification@biodevops.tech"
    $To = "cgaspar2@myges.fr"
    $Cc = "gtaverneantoine@myges.fr", "ehagnere@myges.fr"
    $Attachment = "C:\temp\$file.txt"
    $Subject = "[Log] Log of $file.txt"
    $Body = "Please check the attached"
    $SMTPServer = "smtp.office365.com"
    $SMTPPort = "587"

    Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachment -UseSsl -Credential $Credential
}

function AADConnect {
    Connect-AzureAD -TenantId biodevops.onmicrosoft.com `
                    -CertificateThumbprint 578FD3C043D7A47996B79740D07DAFA70C87E37B `
                    -ApplicationId 71269d2e-dae3-4489-b429-df60dbcb6405
}

function AADDisconnect {
    Disconnect-AzureAD
}

function CheckPromotionStudent {
    $logFile = "PromotionStudent"
    $pathCSV = "C:\temp\PromotionStudent.csv"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    Foreach ($Promo in $dataCSV) {
        $Student = $Promo.student
        $Acronym = $Promo.acronympromotion
        $Year = $Promo.yearpromotion

        $Department = "$Acronym"+" "+"$Year"
        $AU = "$Year"+"_"+"$Acronym"
        $Group = "$Acronym"+"."+"$Year"

        $Informations = Get-AzureADUser -Filter "UserPrincipalName eq '$Student'" | Select-Object Department,ObjectId

        $oldAU = Get-AzureADMSAdministrativeUnit | where-Object { Get-AzureADMSAdministrativeUnitMember -Id $_.Id | where-Object {$_.Id -eq $Informations.ObjectId} }
        $oldGroup = Get-AzureADGroup | where-Object { Get-AzureADGroupMember -ObjectId $_.ObjectId | where-Object {$_.ObjectId -eq $Informations.ObjectId} }
        $newAU = Get-AzureADMSAdministrativeUnit -Filter "DisplayName eq '$AU'"
        $newGroup = Get-AzureADGroup -Filter "DisplayName eq '$Group'"

        if ($Department -notmatch $Informations.Department) {
            [string]$Message = "WARNING : The user $Student is not in the right promotion"
            LogMessage -Filename $logFile -Message $Message

            try{
                Remove-AzureADUserManager -ObjectId $Informations.ObjectId
                [string]$Message = "SUCCESS : The operation to remove the delegate of $Student was successful."
                LogMessage -Filename $logFile -Message $Message
            } catch {
                [string]$Message = "FAILED : The operation to remove the delegate of $Student delegate failed."
                LogMessage -Filename $logFile -Message $Message
            }
            
            try {
                Remove-AzureADMSAdministrativeUnitMember -Id $oldAU.Id `
                                                         -MemberId $Informations.ObjectId
                [string]$Message = "SUCCESS : The operation to remove AU from $Student was successful."
                LogMessage -Filename $logFile -Message $Message
            } catch {
                [string]$Message = "FAILED : The operation to remove AU from $Student failed."
                LogMessage -Filename $logFile -Message $Message
            }
    
            try {
                Remove-AzureADGroupMember -ObjectId $oldGroup.ObjectId `
                                          -MemberId $Informations.ObjectId
                [string]$Message = "SUCCESS : The operation to remove the group from $Student was successful."
                LogMessage -Filename $logFile -Message $Message
            } catch {
                [string]$Message = "FAILED : The operation to remove the group from $Student failed."
                LogMessage -Filename $logFile -Message $Message
            }
    
            try {
                Add-AzureADMSAdministrativeUnitMember -Id $newAU.Id `
                                                      -RefObjectId $Informations.ObjectId
                [string]$Message = "SUCCES : The operation to add in the AU $Student was successful."
                LogMessage -Filename $logFile -Message $Message
            } catch {
                [string]$Message = "FAILED : The operation to add in the AU $Student failed."
                LogMessage -Filename $logFile -Message $Message
            }
    
            try {
                Add-AzureADGroupMember -ObjectId $newGroup.ObjectId `
                                       -RefObjectId $Informations.ObjectId
                [string]$Message = "SUCCESS : The operation to add the class group to $Student was successful."
                LogMessage -Filename $logFile -Message $Message
            } catch {
                [string]$Message = "FAILED : The operation to add the class group to $Student failed."
                LogMessage -Filename $logFile -Message $Message
            }
    
            try {
                Set-AzureADUser -ObjectId $Informations.ObjectId `
                                -Department $Department
                [string]$Message = "SUCCESS : The operation to define the new class of $Student was successful."
                LogMessage -Filename $logFile -Message $Message
            } catch {
                [string]$Message = "FAILED : The operation to define the new class of $Student failed."
                LogMessage -Filename $logFile -Message $Message
            }
        }
    }
    [string]$Message = "INFORMATION : The student promotion verification function has been completed"
    LogMessage -Filename $logFile -Message $Message
}

function CheckClassDelegate {
    $logFile = "ClassDelegate"
    $pathCSV = "C:\temp\ClassDelegate.csv"
    $dataCSV = Import-CSV -Path $pathCSV -Delimiter ","

    Foreach ($Promo in $dataCSV) {
        $Promotion = $Promo.Department
        $Delegate = $Promo.Delegate

        $Delegate = (Get-AzureADUser -Filter "UserPrincipalName eq '$Delegate'").ObjectId
        $Users = Get-AzureADUser | Select-Object Department,ObjectId

        if (!$Delegate) {
            [string]$Message = "INFORMATION : The informed delegate cannot be found for $Promotion"
            LogMessage -Filename $logFile -Message $Message
            continue
        }

        Foreach ($User in $Users) {
            $Student = $User.ObjectId
            $Department = $User.Department

            if (($Promotion -notmatch $Department) -or (!$Department) -or ($Student -eq $Delegate)) {
                continue
            }

            $Manager = (Get-AzureADUserManager -ObjectId $Student).ObjectId
            if ($Manager -notmatch $Delegate){
                [string]$Message = "WARNING : "+((Get-AzureADUser -Filter "ObjectId eq '$Student'").UserPrincipalName)+" has the wrong class representative"
                LogMessage -Filename $logFile -Message $Message
                
                try{
                    Set-AzureADUserManager -ObjectId $Student `
                                           -RefObjectId $Delegate
                    [string]$Message = "SUCCESS : The operation to change the class delegate of "+((Get-AzureADUser -Filter "ObjectId eq '$Student'").UserPrincipalName)+" was successful"
                    LogMessage -Filename $logFile -Message $Message
                } catch {
                    [string]$Message = "FAILED : The operation to change the class delegate of "+((Get-AzureADUser -Filter "ObjectId eq '$Student'").UserPrincipalName)+" failed"
                    LogMessage -Filename $logFile -Message $Message
                }
            }
        }
    }
    [string]$Message = "INFORMATION: The class representative audit function has ended"
    LogMessage -Filename $logFile -Message $Message
}

# ======== MAIN ========
AADConnect

# DO NOT DO THAT !! But for the script is ok
$Credential = Credential -Username "notification@biodevops.tech" -Password "Fug37537"

CheckPromotionStudent
ExtractLog -file PromotionStudent -Credential $Credential
CheckClassDelegate
ExtractLog -file ClassDelegate -Credential $Credential

AADDisconnect