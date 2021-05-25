 <#	
	.NOTES
	===========================================================================
	 Created on:   	05/25/2021
	 Updated on:	05/25/2021
	 Created by:   	James Krolik
	 Filename:     	ClickUp-UpdateStatus.ps1
	===========================================================================
	.DESCRIPTION
		This script is part of a collection of scripts meant to interact with ClickUp via PowerShell.
        This script is intended to update the status of an existing ticket and currently supports 'Open', 'Pending', 'New', and 'Complete' Statuses.
        Additionally, the script can accept a parameter to use Custom ticket (xx-xxxxxx) identifier by passing in -customID with $true.

    .USAGE
        ClickUp-UpdateStatus.ps1 -taskID "JT-12345" -newStatus "Complete"
        ClickUp-UpdateStatus.ps1 -taskID "a1b2c3d" -newStatus "New" -customID $false


    .ADDITIONAL NOTES
        For ClickUp's API, please see their website here:
        https://clickup.com/api
        This was built with the OAuth2 authorization code and access token steps in mind.  
        You could also sub out the access token with the personal key that they mention (pk_) and it would work just the same as the authorization key.

#>

<##########################
 Site Specific Information
###########################>

$authorizationKey = ""
$teamID = ""
$flagPath = "C:\Windows\Temp"

<#######################                      
#   Parameter Block    #
#######################>

Param(

    [Parameter(Mandatory=$false)]
    [String]$taskID,

    [Parameter(Mandatory=$true)]
    [String]$newStatus,

    [Parameter(Mandatory=$false)]
    [Bool]$customID=$false,

    [Parameter(Mandatory=$false)]
    [String]$flag

    )

<#######################                      
#     Header Block     #
#######################>

$headers = @{
    Authorization=$authorizationKey
    "Content-Type" = "application/json"
    }

<######################                    
#   Function Block    #
#######################>

Function updateStatus {

    Param (
            
        [Parameter(Mandatory=$true)]
        [String]$taskID,

        [Parameter(Mandatory=$true)]
        [String]$newStatus

        )

<#######################
    Status Payload
#######################>
$body = ""

if ($newStatus -match "New") {


$body = @' 
    {
    "status":"New"
    }
'@
    
    }

if ($newStatus -match "Open") {

$body = @' 
    {
    "status":"Open"
    }
'@
    }

if ($newStatus -match "Pending") {

$body = @' 
    {
    "status":"Pending"
    }
'@

    }

if ($newStatus -match "Complete") {


$body = @' 
    {
    "status":"Complete"
    }
'@
    
    }


<####################
  Parameter Payload
####################>

if ($customID -eq $true) {

    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/task/$taskID/?custom_task_ids=true&team_id=$teamID"
    "Method"= 'PUT'

    }
    Invoke-RestMethod @SendParameters -headers $headers -Body $body

    }

if ($customID -eq $false) {

    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/task/$taskID/"
    "Method"= 'PUT'

    }
    Invoke-RestMethod @SendParameters -headers $headers -Body $body

    }

}

#If the flag has been set, grab the ticket number from it.
if (!([String]::IsNullOrEmpty($flag))) {

    $flagDataToRead = "$flagPath\Flags\$flag.flag"
    $taskID = Get-Content -Path $flagDataToRead

}

updateStatus -taskid $taskID -newstatus $newStatus
