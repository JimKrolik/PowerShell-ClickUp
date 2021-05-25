
 <#	
	.NOTES
	===========================================================================
	 Created on:   	05/25/2021
	 Updated on:	05/25/2021
	 Created by:   	James Krolik
	 Filename:     	ClickUp-CreateTicket.ps1
	===========================================================================
	.DESCRIPTION
		This script is part of a collection of scripts meant to interact with ClickUp via PowerShell.
        This script is intended to create a ticket and assign a tag for easier viewing.  
        
        As part of its functionality, it will create a flag file that will be referenced by the ClickUp-UpdateStatus.ps1 script.

    .USAGE
        ClickUp-CreateTicket.ps1 -title "MyServer disk C space is under 12% free" -description "Disk space under 12%"
        ClickUp-CreateTicket.ps1 -title "MyServer disk C has less than 2GB free" -description "Disk space is under 2GB" -priority 2 -tag "server critical space" -flagName "lowDiskSpace"

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
$listID = ""
$flagPath = "C:\Windows\Temp"

<#######################                      
#   Parameter Block    #
#######################>


Param(

    [Parameter(Mandatory=$true)]
    [String]$description,

    [Parameter(Mandatory=$true)]
    [String]$ticketTitle,

    [Parameter(Mandatory=$false)]
    [Int]$priority = 3,

    [Parameter(Mandatory=$false)]
    [String]$tag,

    [Parameter(Mandatory=$false)]
    [String]$flagName

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

Function CreateTicket {


    Param (
            
        [Parameter(Mandatory=$true)]
        [String]$ticketTitle,

        [Parameter(Mandatory=$true)]
        [String]$description,

        [Parameter(Mandatory=$false)]
        [Int]$priority = 3

        )

$body = ""

$body = @{
name=$ticketTitle
description=$description
priority=$priority
}

$json = convertto-json $body


    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/list/$listID/task"
    "Method"= 'POST'

    }

    Invoke-RestMethod @SendParameters -headers $headers -Body $json

    }

Function SetTag {


    Param (
            
        [Parameter(Mandatory=$true)]
        [String]$ticketID,

        [Parameter(Mandatory=$true)]
        [String]$tag

        )

$body = ""

$body = @{
task_id=$ticketID
tag_name=$tag

}

$json = convertto-json $body


    $SendParameters = @{

    "URI"="https://api.clickup.com/api/v2/task/$ticketID/tag/$tag/"
    "Method"= 'POST'

    }

    Invoke-RestMethod @SendParameters -headers $headers -Body $json

    }

#Create ticket and sleep for creation.
$newTicket = createTicket -ticketTitle $ticketTitle -description $description -priority $priority
Start-Sleep 5

#Create folder for flag file.
if ((Test-Path -Path $flagPath) -eq $false) {

    New-Item -ItemType "Directory" -Name "Flags" -Path $flagPath

}

#Extract ticket ID from newly created ticket.
$splitInfo = $newTicket
$splitinfo = $splitinfo -replace "[{}]",""
$splitInfo = $splitInfo -replace "[;]","`n"
$splitinfo = $splitInfo -replace "[@]",""
$splitinfo = $splitInfo | ConvertFrom-StringData
$idNumber = $splitInfo.get_item("id")


#Create flag file with ticket number for later referencing.
#If a flag parameter was specified, assign it now.
if (!([String]::IsNullOrEmpty($flagName))) {

    $flag = "$flagPath\Flags\$flagName.flag"

}

#If not, default to the ticket title.
else { 

    $flag = "$flagPath\Flags\$ticketTitle.flg"

}

#If the flag file still exists after the resolve script ran, delete it.
if ((Test-Path -Path $flag) -eq $true) {

    Remove-Item -Path $flag -Force

}

#Create the new flag.
New-Item $flag 
Add-Content $flag $idNumber

#Assign tag if one was supplied.
if (!([String]::IsNullOrEmpty($tag))) {

    SetTag -ticketID $idNumber -tag $tag

}
