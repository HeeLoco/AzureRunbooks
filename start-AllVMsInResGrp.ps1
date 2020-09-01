#This runbook starts all VMs in a resource group

#vars
$myResgrp = "MyResGroup";
$mySubID = "0000000-0000-0000-0000-0000000000";
$Conn = Get-AutomationConnection -Name 'AzureRunAsConnection';
[Bool]$myOnline = $false
[Int]$i = 0;

#login
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationID $Conn.ApplicationId -Subscription $mySubID -CertificateThumbprint $Conn.CertificateThumbprint

#start VMs in ressource group
do{
    Get-AzVM -ResourceGroupName $myResgrp | start-AzVM;

    #get VM state
    $myVMs = Get-AzVM -ResourceGroupName $myResgrp -status
    foreach($VM in $myVMs){
        #count running VMs
        if($VM.PowerState -eq "VM running"){
            $i++;
        }
    }

    #check vm state
    if($i -eq $myVMs.count){
        $myOnline = $true
        $myOut = "`n----------------`nVMs are running`n" + $myVms.Name + "`n----------------`n";
    }
    #reset count var
    $i = 0;

}while($myOnline -ne $true)
#logout
logout-AzAccount;

#output
write-output $myOut;
