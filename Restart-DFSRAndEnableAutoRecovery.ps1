####################################################
#
# Title: Restart-DFSRAndEnableAutoRecovery
# Date Created : 2017-12-28
# Last Edit: 2017-12-29
# Author : Andrew Ellis
# GitHub: https://github.com/AndrewEllis93/PowerShell-Scripts
#
# Nice and short and simple. It restarts the DFSR service on all domain controllers (I schedule this to run nightly. This isn't really necessary but I have found it to prevent some misc issues that crop up once in a blue moon) and enables DFSR auto-recovery, which for whatever reason is disabled on domain controllers by default.
#
####################################################

#Sets screen buffer from 120 width to 500 width. This stops truncation in the log.
$pshost = get-host
$pswindow = $pshost.ui.rawui

$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 500
$pswindow.buffersize = $newsize

$newsize = $pswindow.windowsize
$newsize.height = 50
$newsize.width = 500
$pswindow.windowsize = $newsize

#Log Parameters.
$LogDirectory =  "C:\Temp"
$LogRetentionDays = 30

#Starts logging.
New-Item -ItemType directory -Path $LogDirectory -Force | Out-Null
$Today = Get-Date -Format M-d-y
Start-Transcript -Append -Path $LogDirectory\RestartDFSRLog.$Today.log | Out-Null

#Purges log files older than X days
$RetentionDate = (Get-Date).AddDays(-$LogRetentionDays)
Get-ChildItem -Path $LogDirectory -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $RetentionDate } | Remove-Item -Force

#Gets all DCs, restarts the DFSR service, and enables DFSR auto recovery, which is turned off by default for who knows what reason. 
Write-Output "Getting list of DCs..."
$DCs = Get-ADGroupMember 'Domain Controllers'

ForEach ($DC in $DCs)
{
    $Output = "Restarting DFSR service on " + $DC.Name + "..."
    Write-Output $Output
    Invoke-Command -ComputerName $DC.Name -ScriptBlock {Restart-Service DFSR}
    Write-Output ("Enabling DFSR auto recovery on " + $DC.Name + "...")
    Invoke-Command -ComputerName $DC.Name -ScriptBlock {cmd.exe /c wmic /namespace:\\root\microsoftdfs path dfsrmachineconfig set StopReplicationOnAutoRecovery=FALSE}
}

#Stops logging.
Stop-Transcript
