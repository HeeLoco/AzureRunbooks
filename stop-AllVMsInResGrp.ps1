#This runbook stops all VMs in a resource group

#vars
$myResgrp = "MyResGroup";
$mySubID = "0000000-0000-0000-0000-0000000000";
$Conn = Get-AutomationConnection -Name 'AzureRunAsConnection';
[Bool]$myOnline = $true
[Int]$i = 0;

#login
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationID $Conn.ApplicationId -Subscription $mySubID -CertificateThumbprint $Conn.CertificateThumbprint

#stop VMs in resource group
do{
    Get-AzVM -ResourceGroupName $myResgrp | stop-AzVM -Force;

    #get VM state
    $myVMs = Get-AzVM -ResourceGroupName $myResgrp -status
    foreach($VM in $myVMs){
        #count offline VMs
        if($VM.PowerState -eq "VM deallocated"){
            $i++;
        }
    }

    #check vm state
    if($i -eq $myVMs.count){
        $myOnline = $false
        $myOut = "`n----------------`nVMs are stopped`n" + $myVms.Name + "`n----------------`n";
    }
    #reset count var
    $i = 0;

}while($myOnline -ne $false)
#logout
logout-AzAccount;

#output
write-output $myOut;
