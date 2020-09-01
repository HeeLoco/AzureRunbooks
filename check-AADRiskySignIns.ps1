
## CURRENTLY NOT WORKING ##

<#
    
    This script retrieves Azure Active Directory Risk Sign-in Events from the Microsoft Graph API and send an email alert report.
    Only the active events from the last 30 days will be retrieved (that can be modified via the $filter value in uriGraphEndpoint or removed to get all events).
    See the official documentation for more info:
      https://docs.microsoft.com/en-us/azure/active-directory/active-directory-identityprotection-graph-getting-started
      https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/user_sendmail
      
#>

$ClientID = "00000000-0000-0000-0000-000000000000"
$ClientSecret = "XXXXXXXXXXXXXXXXXXXXXX"
$tenantDomain = "Loco.planet"
$emailSender = "Service@Loco.planet"
$emailRecipient = "HeeLoco@Loco.planet"
$emailSubject = "AAD Risky Sign-ins Report $(Get-Date -Format yyyy/MM/dd)"

$emailBody = "<h1>Azure Active Directory Risky Sign-ins Report</h1>`n"
$emailBody += "<p>Date: $(Get-Date)</p>`n"
$emailBody += "<p>Tenant: $($tenantdomain)</p>`n"
$emailBody += "<p>More detail at: <a href='https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RiskySignIns' target='_blank'>Azure Active Directory Portal</a></p>`n"
$emailBody += "<br>`n"

$loginURL = "https://login.microsoft.com"
$resource = "https://graph.microsoft.com"
$body       = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth      = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body


if ($oauth.access_token -ne $null) {
    
    $reqBody='{
        "message": {
        "subject": "",
        "body": {
            "contentType": "",
            "content": ""
        },
        "toRecipients": [
            {
            "emailAddress": {
                "address": ""
            }
            }
        ]
        }
    }' | ConvertFrom-Json

    $reqBody.message.subject = $emailSubject
    $reqBody.message.body.contentType = "Html"
    $reqBody.message.toRecipients.emailAddress.address = $emailRecipient
    
    $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}

    [uri]$uriGraphEndpoint = "https://graph.microsoft.com/beta/identityRiskEvents?`$filter=riskEventDateTime gt $(Get-Date -date (Get-Date).AddDays(-30).ToUniversalTime() -Format o) and riskEventStatus eq 'active'"

    $response = Invoke-RestMethod -Method Get -Uri $uriGraphEndpoint.AbsoluteUri -Headers $headerParams

    if ($response.value -ne $null) {


        foreach ( $event in $response.value ) {
            
            $emailBody += "<p>`n"
            $emailBody += "User: $($event.userDisplayName)<br>`n"
            $emailBody += "UserPrincipalName: $($event.userPrincipalName)<br>`n"
            $emailBody += "Event time: $($event.riskEventDateTime)<br>`n"
            $emailBody += "Risk type: $($event.riskEventType)<br>`n"
            $emailBody += "Risk level: $($event.riskLevel)<br>`n"
            $emailBody += "Risk status: $($event.riskEventStatus)<br>`n"

            if ( $event.ipAddress -ne $null) {
                        
                $emailBody += "IP: $($event.ipAddress)<br>`n"

                [uri]$uriIpinfo = "https://ipinfo.io/$($event.ipAddress)"
                $ipInfo = Invoke-RestMethod -Method Get -Uri $uriIpinfo.AbsoluteUri

                if ($ipInfo.country -ne "") { $emailBody += "IP country: $($ipInfo.country)<br>`n" }
                if ($ipInfo.city -ne "") { $emailBody += "IP city: $($ipInfo.city)<br>`n" }
                if ($ipInfo.org -ne "") { $emailBody += "IP org: $($ipInfo.org)<br>`n" }


            }

            $emailBody += "</p>`n"

        }

        $reqBody.message.body.content = $emailBody
        Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/v1.0/users/$($emailSender)/sendMail" -Headers @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"; 'Content-type'="application/json"} -Body ($reqBody | ConvertTo-Json -Depth 4 | Out-String)

    }

    else {
    
                $emailBody += "<p>No risky sign-ins event.</p>"
                $reqBody.message.body.content = $emailBody
                Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/v1.0/users/$($emailSender)/sendMail" -Headers @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"; 'Content-type'="application/json"} -Body ($reqBody | ConvertTo-Json -Depth 4 | Out-String)
     
     }


} 

else {

    Write-Output "ERROR: No Access Token"

} 
