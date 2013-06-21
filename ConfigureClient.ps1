#-------------------------------------------------------------------------------------------------------------------------
# Voip-connections - New customer provisioning script.
# 1.0.0
#-------------------------------------------------------------------------------------------------------------------------
param([string]$Configure, #Configure "AD","Lync", "HostedVoice"
    [string]$SipDomain, #SipDomain for the users
    [string]$UserFile, #Full path of the file containing user names
    [string]$OrganizationName) #Organization Domain for hosted voice.



If ($Configure -ne "Lync" -and $Configure -ne "AD" -and $Configure -ne "HostedVoice")
{
    Write-Host "Options:"
    Write-Host "Lync - Configure Lync user on a Lync server."
    Write-Host "AD - Create and configure user in AD and add UPN entry."
    Write-Host "HostedVoice - Set hosted voice policy and enble enterprise voice for users."
    Exit
}

$ADDomain= "lynconaws" #"MediationGateway" Change this to new AD domain of test server.
$ADDomainSuffix = "net"
$LyncModules="C:\Program Files\Common Files\Microsoft Lync Server 2013\Modules\Lync\Lync.psd1"
$UpnName =$SipDomain
# Example OU=Amaxra,OU=User_Demo,DC=MediationGateway,DC=com
$ExchangeUsersOU = "OU=$OrganizationName,OU=Customers,DC=$ADDomain,DC=$ADDomainSuffix"
$RegistrarPool = "Lyncfesrv.lynconaws.net"
$FileName = $UserFile 

If ([string]::IsNullOrEmpty($FileName))
{
    #//Get the file name for users
    $FileName = Select-FileDialog -Title "Import an CSV file" -Directory "c:\"
}

Write-Host "Voip-Connections: Starting new client configuration for  new client configuration for." $SipDomain

If ($Configure -eq "AD")
{
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()  
    $DomainDN = (([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()).Domains | ? {$_.Name -eq $domain}).GetDirectoryEntry().distinguishedName
    $final = "LDAP://$DomainDN"
    $DomainPath = [ADSI]"$final"

    $test = Get-AdForest
    if( -not $test.UPNSuffixes.Contains($OrganizationName))
    {
        #// SetADForest
        Set-ADForest -UPNSuffixes @{Add="$UpnName"} -Identity "$ADDomain.$ADDomainSuffix"
    }
    
 
    $test = Get-ADObject -Filter {OU -like "customers"}
    if($test -eq $null)
    {
        #create new ou='customers'
        New-ADObject -type "organizationalunit" -name "customers" 
    }

    $test = Get-ADObject -Filter {OU -like $organizationname} -SearchBase "OU=customers,DC=$ADDomain,DC=$ADDomainSuffix"
    if($test -eq $null)
    {
        #create new ou='customers'
        New-ADObject -type "organizationalunit" -name $organizationname -Path "OU=customers,DC=$ADDomain,DC=$ADDomainSuffix" 
    }
    #TODO: do we re$cOU = $DomainPath.Create("OrganizationalUnit",$ExchangeUsersOU)

    #// Create new users
    Add-NewUsers-From-File -FileName $FileName


    #// Set new upn for all users
    $filter="*$ADDomain.$ADDomainSuffix"
    Get-ADUser -Filter {UserPrincipalName -like $filter} -SearchBase "$ExchangeUsersOU" |

    ForEach-Object {
    Write-Host $_.Name
        $UPN = $_.UserPrincipalName.Replace("$ADDomain.$ADDomainSuffix",$SipDomain)
        Set-ADUser $_ -UserPrincipalName $UPN
    }
 }

 If ($Configure -eq "Lync")
 {
    import-module $LyncModules
    #// Set SIP domain
    New-CsSipDomain -Identity $SipDomain

    #// TODO: Check if we need to publish toplogy 
    get-csaduser -filter {Enabled -ne $True} -OU $ExchangeUsersOU | Enable-CsUser -RegistrarPool $RegistrarPool -SipAddressType EmailAddress

 }

 If ($Configure -eq "HostedVoice")
 {
    import-module $LyncModules
    $HostedVoicePolicyName = $SipDomain+"_Policy"
    #// Enable enterprise voice for all users
    New-CsHostedVoicemailPolicy -Identity $HostedVoicePolicyName -Destination exap.um.outlook.com -Description "Hosted voicemail policy for $SipDomain" -Organization -"$OrganizationName.onmicrosoft.com"
    Get-CsUser -OU $ExchangeUsersOU | Grant-CsHostedVoicemailPolicy -PolicyName $HostedVoicePolicyName
    Get-CsUser -OU $ExchangeUsersOU |Set-CsUser -HostedVoiceMail $True
 }

Write-Host "Voip-Connections new client configuration completed."




function Add-NewUsers-From-File
{
   param([string]$FileName)
    Write-Host "---------------------------------------------------------------"
    Write-Host "Creating new Users"
    Write-Host "---------------------------------------------------------------"

    $UserInformation = Import-Csv $FileName
    
    $OUPath = "LDAP://$ExchangeUsersOU,$DomainDN"
    $UserPath = [ADSI]"$OUPath"

    Foreach ($User in $UserInformation){
	
	    $CN = $User.samAccountName
	    $SN = $User.Surname
	    $Given = $User.givenName
	    $samAccountName = $User.samAccountName
	    $Display = $User.DisplayName
	
	    $LABUser = $UserPath.Create("User","CN=$CN")
	    Write-Host "Creating User: $User.samAccountName"
	    $LABUser.Put("samAccountName",$samAccountName)
	    $LABUser.Put("sn",$SN)
	    $LABUser.Put("givenName",$Given)
	    $LABUser.Put("displayName",$Display)
	    $LABUser.Put("mail","$samAccountName@$domain")
	    $LABUser.Put("description", "Lab User - created via Script")
	    $LABUser.Put("userPrincipalName","$samAccountName@$domain")
	    $LABUser.SetInfo()
	
	    $Pwrd = $User.Password
	
	    $LABUser.psbase.invoke("setPassword",$Pwrd)
	    $LABUser.psbase.invokeSet("AccountDisabled",$False)
	    $LABUser.psbase.CommitChanges()
    }

}



function Select-FileDialog 
{
	param([string]$Title,[string]$Directory,[string]$Filter="CSV Files (*.csv)|*.csv")
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	$objForm.ShowHelp = $true
	
	$Show = $objForm.ShowDialog()
	
	If ($Show -eq "OK")
	{
		Return $objForm.FileName
	}
	Else
	{
		Exit
	}
}
