    # Get the PowerShell credential and prints its properties
    $Cred = Get-AutomationPSCredential -Name 'myServiceCreds';

    #set some var
    $Body = "Following device(s) are not compliant anymore"
    $Subject = "Endpoint manager - iOS compliance check"
    $To ='HeeLoco@Loco.planet'
    $From ='Service@Loco.planet' #same as $Cred 

    if ($Cred -eq $null)
    {
        Write-Output "Credential entered: $AzureOrgIdCredential does not exist in the automation service. Please create one `n"   
    }

    Connect-MSGraph -Credential (Get-AutomationPSCredential -Name 'HeeLoco for MDM')

    $myIntuneDevices = Get-IntuneManagedDevice # | Select-Object id, deviceName, complianceState ,operatingSystem, userPrincipalName;
    $myNonCompliantDevices = $myIntuneDevices | Where-Object {$_.operatingSystem -match 'iOS' -and $_.complianceState -notlike 'compliant'};

    if($myNonCompliantDevices){

        #prepare output
        foreach($device in $myNonCompliantDevices){
            $Body += ($device | out-string);
        }
        $Body += "https://devicemanagement.microsoft.com/";
        #sender has to be the same as credential user
        #$Body += "`n`n" + $myNonCompliantDevices
        Send-MailMessage -To $To -Subject $Subject -Body $Body -UseSsl -Port 587 -SmtpServer 'smtp.office365.com' -From $From -Credential $Cred
    }
    else{
        write-host "no devices found"
    }
