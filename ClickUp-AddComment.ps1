 <#	
	.NOTES
	===========================================================================
     Created by:    James Krolik
	 Created on:   	05/25/2021
	 Updated on:	05/25/2021
	 Filename:     	ClickUp-AddComment.ps1
	===========================================================================
	.DESCRIPTION
		This script is part of a collection of scripts meant to interact with ClickUp.
        This script is intended to add comments to an existing ticket.
        Additionally, the script can accept a parameter to use the Custom Ticket ID's (XX-XXXXX) identifier by passing in -customID with $true.

    .USAGE
        ClickUp-AddComment.ps1 -ticket "a1b2c3d" -comment "The server is now back online."

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

<#######################                      
#   Parameter Block    #
#######################>


Param(

    [Parameter(Mandatory=$true)]
    [String]$taskID,

    [Parameter(Mandatory=$true)]
    [String]$comment,

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
   Comment Payload
######################>
$body = ""


$body = @{ 
    
      comment_text=$comment
    }



<####################
  Parameter Payload
####################>

if ($customID -eq $true) {

    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/task/$taskID/comment?custom_task_ids=true&team_id=$teamID"
    "Method"= 'POST'

    }

    $json = $body | ConvertTo-Json

    Invoke-RestMethod @SendParameters -headers $headers -Body $json

}

if ($customID -eq $false) {

    
    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/task/$taskID/comment?"
    "Method"= 'POST'

    }

    $json = $body | ConvertTo-Json

    Invoke-RestMethod @SendParameters -headers $headers -Body $json

}