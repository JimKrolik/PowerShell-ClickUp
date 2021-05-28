 <#	
	.NOTES
	===========================================================================
	 Created on:   	05/27/2021
	 Updated on:	05/28/2021
	 Created by:   	James Krolik
	 Filename:     	ClickUp-UpdateTitle.ps1
	===========================================================================
	.DESCRIPTION
		This script is part of a collection of scripts meant to interact with ClickUp via PowerShell.
        This script is intended to update the title of an existing ticket.  The use case would be in conjunction with a low disk space monitor to update the title from low to critically low, etc.
        Additionally, the script can accept a parameter to use Custom ticket (xx-xxxxxx) identifier by passing in -customID with $true.

    .USAGE
        ClickUp-UpdateTitle.ps1 -taskID "JT-12345" -newTitle "Computer disk C space is now critically low."
        ClickUp-UpdateTitle.ps1 -taskID "a1b2c3d" -newTitle "New" -customID $false


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
    [String]$newTitle,

    [Parameter(Mandatory=$false)]
    [Bool]$customID=$false


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

Function updateTitle {

    Param (
            
        [Parameter(Mandatory=$true)]
        [String]$taskID,

        [Parameter(Mandatory=$true)]
        [String]$newTitle

        )

<#######################
    Title Payload
#######################>
$body = ""

$body = @{
    
name=$newTitle
}

    #Convert the payload to JSON as the API requires.
    $json = $body | ConvertTo-Json

    <####################
      Parameter Payload
    ####################>

if ($customID -eq $true) {

    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/task/$taskID/?custom_task_ids=true&team_id=$teamID"
        "Method"= 'PUT'

        }

        Invoke-RestMethod @SendParameters -headers $headers -Body $json

        }

    if ($customID -eq $false) {

        $SendParameters = @{

        "URI"="https://api.clickup.com/api/v2/task/$taskID/"
        "Method"= 'PUT'

        }

        Invoke-RestMethod @SendParameters -headers $headers -Body $json
        }

    }

updateTitle -taskid $taskID -newTitle $newTitle
