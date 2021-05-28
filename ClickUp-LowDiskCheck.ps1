
 <#	
	.NOTES
	===========================================================================
	 Created on:   	05/25/2021
	 Updated on:	05/28/2021
	 Created by:   	James Krolik
	 Filename:     	ClickUp-LowDiskCheck.ps1
	===========================================================================
	.DESCRIPTION
		This script is part of a collection of scripts meant to interact with ClickUp via PowerShell.
        It was originally designed with ConnectWise Automate in mind, but any RMM tool will work and can be ran as a scheduled script.
        This script will check all fixed disks for free space, generate flag files if an event is triggered, and call create/update tickets as necessary.

    .USAGE
        ClickUp-LowDiskCheck.ps1 -minimumPercentageFree 12 -criticalGB 2 -deviceType "Server"

    .NOTES
        First this will check for any existing flags to check for status resolved.  Next we will check all other remaining fixed disks.

    .ADDITIONAL NOTES
        This script combines the functionality of the other three scripts listed in dependencies.

    .DEPENDENCIES
        Must all be in the same directory as this script for a successful run to occur.  Additionally, the team, list, and other ID's must be pre-populated in the scripts.
            ClickUp-CreateTicket.ps1
            ClickUp-AddComment.ps1
            ClickUp-UpdateStatus.ps1
            ClickUp-UpdateTitle.ps1

    .CHANGE NOTES
        05/28/2021 - Added functionality to update ticket titles and handle transition events moving from low to critical and critical to low.  Also added functionality to continually update the ticket with current free space.

#>

<####################
#  Parameter Block  #
####################>

Param(

    [Parameter(Mandatory=$false)]
    [Int]$minimumPercentageFree = 10,

    [Parameter(Mandatory=$false)]
    [Int]$criticalGB = 10,

    [Parameter(Mandatory=$false)]
    [String]$deviceType="workstation"

)

<#######################
# Configurable Options #
#######################> 

$flagDirectory = "C:\Windows\Temp\Flags"
[int]$minimumGBTarget = 16    #Minimum GB to be detected by low threshold.  This is to avoid the SYSTEM partition of Windows 10 being detected and throwing a false alert.

#Paths to call various routines if a ticket needs to be created or updated.
$CreateTicket = $PSScriptRoot+"\ClickUp-CreateTicket.ps1"
$AddComment = $PSScriptRoot+"\ClickUp-AddComment.ps1"
$UpdateStatus = $PSScriptRoot+"\ClickUp-UpdateStatus.ps1"
$UpdateTitle = $PSScriptRoot+"\ClickUp-UpdateTitle.ps1"

<########################
      Program Begin
########################>

#Create folder for flag file.
if ((Test-Path -Path $flagDirectory) -eq $false) {

    New-Item -ItemType "Directory" -Path $flagDirectory

}


#Create priority classifications for generalization.  Servers deserve a higher priority.
if ($deviceType -match "Workstation") {

    $priorityHigh = 2
    $priorityLow = 3

}

if ($deviceType -match "Server") {

    $priorityHigh = 1
    $priorityLow = 2

}
#Get all fixed disks (DriveType 3) so we know what to specifically target for checks.
$allFixedDisks = Get-WmiObject -class win32_logicaldisk -filter "DriveType = '3'"


ForEach ($disk in $allFixedDisks) {

        $driveLetter = $disk.deviceid.substring(0,1)

        $freeSpaceInGB = [math]::round(($disk.freespace / 1GB),2)
        $percentageFree = [int](($disk.freespace / $disk.size) * 100)
       
        #If we encounter a disk that is under the minimum size to check for, such as the System partition, just skip it entirely.
        if (($disk.size/1GB) -le $minimumGBTarget) {
            continue
        }

        #Check for critical free GB
            if ($freeSpaceInGB -le $criticalGB) {
            
                    if ((Test-Path -Path "$flagDirectory\CriticalDisk$driveLetter.flag") -eq $true) {

                        #If the flag file already exists, then we have already created a critical disk ticket.
                        #Add the current free space to the ticket.

                        $taskID = Get-Content "$flagDirectory\CriticalDisk$driveLetter.flag"
                        & $AddComment -taskID $taskID -comment "Current Free Space:  $freeSpaceInGB GB"
                    
                        continue
                    }

                    if ((Test-Path -Path "$flagDirectory\lowDisk$driveLetter.flag") -eq $true) {

                        #If we have detected that the low disk flag was already set, but not the critical, update the title and set the critical flag.
                        $taskID = Get-Content "$flagDirectory\lowDisk$driveLetter.flag"
                        Add-Content "$flagDirectory\CriticalDisk$driveLetter.flag" $taskID
                        & $UpdateTitle -taskID $taskID -newTitle "$env:ComputerName disk $driveLetter space under $criticalGB GB"

                        continue
                    }

            #If neither of the flags exist, create a ticket.
            & $CreateTicket -ticketTitle "$env:ComputerName disk $driveLetter space under $criticalGB GB" -description "Disk space has less than $criticalGB GB available.  The actual disk space free is $freeSpaceInGB GB." -flagName "CriticalDisk$driveLetter" -tag "$deviceType critical space" -priority $priorityHigh

            #If critical triggered, then skip the minimum percent free check to avoid duplicate alerts.
            continue
            }

        #Check for low percentage

            if ($percentageFree -le $minimumPercentageFree) {

                if ((Test-Path -Path "$flagDirectory\lowDisk$driveLetter.flag") -eq $true) {

                    $taskID = Get-Content "$flagDirectory\lowDisk$driveLetter.flag"
                    & $AddComment -taskID $taskID -comment "Current Free Space:  $freeSpaceInGB GB"

                    continue

                }

            #If the flag didn't previously exist, create a ticket now.
            & $CreateTicket -ticketTitle "$env:ComputerName disk $driveLetter space under $minimumPercentageFree % free" -description "Disk space has less than $minimumPercentageFree % available.  The actual disk space free is $freeSpaceInGB GB." -flagName "LowDisk$driveLetter" -tag "$deviceType low space" -priority $priorityLow

            }

}

#Now that we've raised alerts for any new low disk space devices, check for flags and see if any are now resolved.

ForEach ($disk in $allFixedDisks) {

        $driveLetter = $disk.deviceid.substring(0,1)

        $freeSpaceInGB = [math]::round(($disk.freespace / 1GB),2)
        $percentageFree = [int](($disk.freespace / $disk.size) * 100)

        #Check for Critical Disk flags
            if ((Test-Path -Path "$flagDirectory\CriticalDisk$driveLetter.flag") -eq $true) {

                if ($freeSpaceInGB -gt $criticalGB) {

                    $taskID = Get-Content "$flagDirectory\CriticalDisk$driveLetter.flag"

                    & $AddComment -taskID $taskID -comment "The device is no longer below $criticalGB GB free."
                    & $AddComment -taskID $taskID -comment "Current Free Space:  $freeSpaceInGB GB"

                    #Check if we still are still in a low disk space state.
                    if ($percentageFree -gt $minimumPercentageFree) {
                    
                        #If we are, mark ticket as complete and delete the flags.
                        & $UpdateStatus -taskID $taskID -newStatus "Complete"
                        Remove-Item -Path "$flagDirectory\CriticalDisk$driveLetter.flag" -Force
                        Remove-Item -Path "$flagDirectory\LowDisk$driveLetter.flag" -Force
                    }

                    else {

                        #If we are not, then update the title back to low and delete the critical flag.
                        & $UpdateTitle -taskID $taskID -newTitle "$env:ComputerName disk $driveLetter space under $minimumPercentageFree % free"
                        Remove-Item -Path "$flagDirectory\CriticalDisk$driveLetter.flag" -Force
                    }

                }
        
            }

        #Check for low disk space flags  
            if ((Test-Path -Path "$flagDirectory\lowDisk$driveLetter.flag") -eq $true) {

                if ($percentageFree -gt $minimumPercentageFree) {

                    $taskID = Get-Content "$flagDirectory\LowDisk$driveLetter.flag"

                    & $AddComment -taskID $taskID -comment "The device is no longer below $minimumPercentageFree % free."
                    & $AddComment -taskID $taskID -comment "Current Free Space:  $freeSpaceInGB GB"
                    & $AddComment -taskID $taskID -comment "Current Percentage Free: $percentageFree"
                    & $UpdateStatus -taskID $taskID -newStatus "Complete"

                    Remove-Item -Path "$flagDirectory\LowDisk$driveLetter.flag" -Force

                    #If the critical flag is still present, clean it up now.
                    if (Test-Path -path "$flagDirectory\CriticalDisk$driveLetter.flag") { 
                        Remove-Item -Path "$flagDirectory\CriticalDisk$driveLetter.flag" -Force
                    }

                }
                 
            }
}

exit 0