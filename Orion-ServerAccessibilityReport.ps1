#This script is meant ot act on a CSV report exported from SoloarWinds Orion of all the active servers in an environment.
#It appempts to map the ipc$ share on each to check for soft-locked servers that are still responding to ping but otherwise are hung, then sends an email report.
#Be sure to set the email variables as well as the path to the working directory that Orion dumps the CSV to.

#Email Variables
$emailSMTP = "smtp.example.local"
$emailTo = "serverteam@example.local"
$emailFrom = "noreply@example.local"
$emailSubject = "Server Accessibility Report"

#File Variables
#Path to the working directory where the CSV from orion can be found. This can be a UNC path.
$path = "\\sevrer\share\path"
$onlineList = "$path\Online.txt"
$offlineList = "$path\Offline.txt"
$combinedList = "$path\Combined.txt"
$logFile = "$path\ServerAccessibilityReport.log"

#Check for and delete all but the most recent CSV from Orion.
$csvs = Get-ChildItem -Path $path -Filter *.csv
$csvCount = $csvs.Count -1
$csvs | Sort CreationTime -Descending | Select -Last $csvCount | Remove-Item -Force

#Delete txt files form last run if they didn't get cleaned up
Remove-Item $onlineList -ErrorAction SilentlyContinue
Remove-Item $offlineList -ErrorAction SilentlyContinue
Remove-Item $combinedList -ErrorAction SilentlyContinue

#Import the last CSV
$inputFile = (Get-Item $path\*.csv).FullName
$orionDate = (Get-Item $inputFile).CreationTime
$serverList = Import-CSV "$inputFile"

#Flush DNS before running
ipconfig /flushdns

#loop throug list of servers attempting to map \ipc$
#Check error status and output to appropriate list
foreach ($server in $($serverList.'Node Name')) {
    net use "\\$server\ipc$"
    if ($?) {
        $server | Out-File -Append $onlineList
    } else {
        $server | Out-File -Append $offlineList
    }
}

#Unmap all drives
net use * /d /y

"**** SERVER ACCESSIBILITY REPORT ****<br>"                | Out-File -Append $combinedList
"Orion's Server List Date:<br>"                            | Out-File -Append $combinedList
"$orionDate<br>"                                           | Out-File -Append $combinedList
"<br>"                                                     | Out-File -Append $combinedList
"-- NOT ACCESSIBLE --<br>"                                 | Out-File -Append $combinedList

foreach ($line in Get-Content $offlineList) {
    "$line<br>"                                            | Out-File -Append $combinedList  
}

"<br>"                                                     | Out-File -Append $combinedList
"-- ACCESSIBLE --<br>"                                     | Out-File -Append $combinedList

foreach ($line in Get-Content $onlineList) {
    "$line<br>"                                            | Out-File -Append $combinedList  
} 

"<br>"                                                     | Out-File -Append $combinedList
"**** END OF REPORT ****<br>"                              | Out-File -Append $combinedList
"<br>"                                                     | Out-File -Append $combinedList
"Path for Server List pickup is:<br>"                      | Out-File -Append $combinedList
"$inputFile<br>"                                           | Out-File -Append $combinedList
"<br>"                                                     | Out-File -Append $combinedList
"Email autogenerated from $(hostname) in $runningTime<br>" | Out-File -Append $combinedList

$emailBody = Get-Content $combinedList

#email using bmail app
Send-MailMessage -BodyAsHtml -Body "$emailBody" -To $emailTo -From $emailFrom -Subject $emailSubject -SmtpServer $emailSMTP

#Sleep before deleting files
Start-Sleep 10

#Cleanup
Remove-Item $onlineList -ErrorAction SilentlyContinue
Remove-Item $offlineList -ErrorAction SilentlyContinue
Remove-Item $combinedList -ErrorAction SilentlyContinue

"Script Ran successfully at $(Get-Date)" | Out-File -Append $logFile