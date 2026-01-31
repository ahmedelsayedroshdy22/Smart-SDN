

Param(
  [Parameter(Mandatory=$false)]
  [string]$IP,
  [Parameter(Mandatory=$true)]
  [string]$Choice,
  [Parameter(Mandatory=$false)]
  [string]$ID,
  [Parameter(Mandatory=$false)]
  [string]$INI_PARAM,
  [Parameter(Mandatory=$false)]
  [string]$UserName,
  [Parameter(Mandatory=$false)]
  [string]$Password
)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Status"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Loading......"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(50, 30)
$form.Controls.Add($label)


Write-Host " IP Passed is : $IP"


Write-Host " ID Passed is testbranch : $ID"

Write-Host " Choice  Passed is : $Choice"

cd "C:\Util\CCD"


switch ($Choice) {
    "1" {

$form.Show()
        
$cred = "puso7259" + ":" + "Rw49iuMzJm"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))

$result=.\curl.exe --location --request GET "https://$IP/api/v1/alarms/active?limit=50" -k --header "Authorization: Basic $($cred_encoded)" --connect-timeout 15





if ($result -match "Object Not Found") {

$msg="Sorry, can't get the information as this is a MP that has no APIs."
   $msg | Out-GridView -Title "GW Details for active alarms"
} 


if ($Error[0].Exception -like "*(28) SSL connection timeout*"){

    
$myVariable = Write-Output "SBC IP : $IP is not reachable no HTTPS connectivity" 
$myVariable | Out-GridView -Title "GW Details Alarms "

}


else {


$jsonObject = $result | ConvertFrom-Json

 $result = $jsonObject.alarms   
 
 $result |  Out-GridView -Title "GW Details for active alarms"

}


$form.Close()

}

    "2" {
   $form.Show()
        
$cred = "puso7259" + ":" + "Rw49iuMzJm"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))

$result=.\curl.exe --location --request GET "https://$IP/api/v1/files/ini" -k --header "Authorization: Basic $($cred_encoded)" --connect-timeout 15

if ($result -match "Object Not Found") {
    $msg = "Sorry, can't get the information as this is a MP that has no APIs."
    $msg | Out-GridView -Title "GW Details for INI"
}
elseif ($result -eq $null) {
    $myVariable = Write-Output "SBC IP : $IP is not reachable no HTTPS connectivity"
    $myVariable | Out-GridView -Title "GW Details for INI"
}


else {
    $result | Out-GridView -Title "INI View"
}

$form.Close()

    }


    "3" {

   
$cred = "puso7259" + ":" + "Rw49iuMzJm"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))
 
 
$result=.\curl.exe --location --request GET  "https://$IP/api/v1/alarms/history?limit=50" -k --header "Authorization: Basic $($cred_encoded)" --connect-timeout 15
 
 if ($result -match "Object Not Found") {

$msg="Sorry, can't get the information as this is a MP that has no APIs."
   $msg | Out-GridView -Title "GW Details for history alarms"
} 

if ($Error[0].Exception -like "*(28) SSL connection timeout*"){

    
$myVariable = Write-Output "SBC IP : $IP is not reachable no HTTPS connectivity" 
$myVariable | Out-GridView -Title "GW Details for History Alarms "

}


else {
$jsonObject = $result | ConvertFrom-Json
$result = $jsonObject.alarms | select  description ,idv
 

$result |  Out-GridView -Title "History Alarms"
}
        


    }


    "4" {
    $form.Show()


$cred = "puso7259" + ":" + "Rw49iuMzJm"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))
 
 
$result=.\curl.exe --location --request GET  "https://$IP/api/v1/kpi/current/system/cpuStats/cpu/0/cpuUtilization" -k --header "Authorization: Basic $($cred_encoded)" --connect-timeout 15
 if ($result -match "Object Not Found") {

$msg="Sorry, can't get the information as this is a MP that has no APIs."
   $msg | Out-GridView -Title "GW Details for CPU"
} 


if ($Error[0].Exception -like "*(28) SSL connection timeout*"){

    
$myVariable = Write-Output "SBC IP : $IP is not reachable no HTTPS connectivity" 
$myVariable | Out-GridView -Title "GW Details for CPU "

}



 else{
$jsonObject = $result | ConvertFrom-Json
$result = $jsonObject | select  Value ,Id
$result |  Out-GridView -Title "CPU Utilization : Value in % "
}

 $form.Close()
    }


    "5" {

   $ssh = "plink puso7259@$IP  -pw Rw49iuMzJm"

Start-Process  powershell.exe 

start-sleep -Seconds 4



foreach ($c in $ssh.GetEnumerator()){

[System.Windows.Forms.SendKeys]::SendWait("$c")
start-sleep -Milliseconds 20

}



[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    
    


     
    }


    "6" {
    $form.Show()
    
$cred = "puso7259" + ":" + "Rw49iuMzJm"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))

$result=.\curl.exe --location --request GET "https://$IP/api/v1/alarms/active/$ID" -k --header "Authorization: Basic $($cred_encoded)" --connect-timeout 15



$jsonObject = $result | ConvertFrom-Json
$result = $jsonObject  
$form.Close() 
    
    $result |  Out-GridView -Title "Alarm Details for ID : $ID "
    
    
    }

    "7"{
    $form.Show()
$cred = "puso7259" + ":" + "Rw49iuMzJm"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))

$Global:INI_Param_Value=@()


$ChosenGWs= Import-Csv .\GWs_SelectedForComparison.csv

$Global:INI_Param_Value+="
[All copy rights reserved to Ahmed Zayed 2024]
##############################################

"

foreach($i in $ChosenGWs.'Admin IP address'){

$result=.\curl.exe --location --request GET "https://$i/api/v1/files/ini" -k --header "Authorization: Basic $($cred_encoded)"  --connect-timeout 15

$result

if($result -match "Object Not Found"){
$Global:INI_Param_Value+="

#######################################################################################                                                                                
#                         DEVICE REPORT - MediaPack API Availability                 
#                                                                                
#  Device IP: $i                                               
#  Status: No APIs available for the MediaPack device.                                                                                                                     
#  Please verify the device's configuration and API access.                                                                                                              
#######################################################################################

"
}

if($result -eq $null){
$Global:INI_Param_Value+="
#######################################################################################                                                                                
#                         DEVICE REPORT - Connectivity Issue                                                                                                          
#  Device IP: $i                                                
#  Status: Device is not reachable due to no HTTPS connection.                                                                                                             
#  Please verify network connectivity and ensure HTTPS access is enabled.             
#######################################################################################
"
}


Write-Host "GW IP : $i" -ForegroundColor Yellow

$result | Out-File  .\General-ini.txt

$ini= gc .\General-ini.txt

$specific_line = $ini | Where-Object {$_ -like "*$INI_PARAM*" }   #deh hna lazm a pass el value $INI_PARAM mn el sdn tool fel button bta3 magenta el hgebo mn text field gded hb3t feeh bas el choice w ini param

if(($result -ne $null) -and ($result -notlike "*Not Found*") ){
$Global:INI_Param_Value+="
#######################################################################################
#  DEVICE REPORT - IP Information                                                                                          
#  Device IP: $i                                                
#######################################################################################
"
}


$Global:INI_Param_Value+=$specific_line


}
$form.Close()


$Global:INI_Param_Value |  Out-GridView -Title "$INI_PARAM : Parameter Comparison Results :  "

}




"8"{
$form.Show()

$cred = "$UserName" + ":" + "$Password"
$cred_encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))

$Global:TestResults=@()


$ChosenGWs= Import-Csv .\GWs_SelectedToBeTested.csv
$currentDate = Get-Date -Format "yyyy-MM-dd_HH"
foreach($i in $ChosenGWs){

$result=.\curl.exe --location --request GET "https://$($i.'Admin IP address')/api/v1/status" -k --header "Authorization: Basic $($cred_encoded)"  --connect-timeout 15

$jsonObject = $result | ConvertFrom-Json

if ($result -match "Object Not Found") {
    $myVariable = Write-Output "SBC Name: $($i.Equipment) IP: $($i.'Admin IP address') MediaPack Failed at Testing"
    $Global:TestResults += $myVariable
} 
elseif ($jsonObject.operationalState -match "UNLOCKED") {
    Write-Host "$($jsonObject.operationalState)" -ForegroundColor Yellow
    $myVariable = Write-Output "SBC Name: $($i.Equipment) IP: $($i.'Admin IP address') Login Test Success!"
    $Global:TestResults += $myVariable
} 
elseif ($result -eq $null) {
    Write-Host "No HTTPS connectivity the SBC is not reachable" -ForegroundColor Yellow
    $myVariable = Write-Output "SBC Name: $($i.Equipment) IP: $($i.'Admin IP address') is not reachable no HTTPS connectivity"
    $Global:TestResults += $myVariable
} 
elseif ($jsonObject.Errors.ErrorValue -like "*Unauthorized Request*") {
    Write-Host "UserName or password is invalid" -ForegroundColor Yellow
    $myVariable = Write-Output "SBC Name: $($i.Equipment) IP: $($i.'Admin IP address') Login Test Failed"
    $Global:TestResults += $myVariable
} 
else {
    $myVariable = Write-Output "SBC Name: $($i.Equipment) IP: $($i.'Admin IP address') Login Test Failed!"
    $Global:TestResults += $myVariable
}



}

$form.Close()

$fileName = "Test_LoginOutput_$currentDate.txt"
$Global:TestResults| Out-File  -FilePath $fileName 

$Global:TestResults | Out-GridView -Title 'Test Results'


} 





    default {
        Write-Host "DUMMY "
    }
}
