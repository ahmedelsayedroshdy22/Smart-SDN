
Write-Host "Please wait while your SDN tool is being updated with the latest Gini Data ...." -ForegroundColor Yellow 

# Define the URL and destination path
$Url = "https://gini.equant.com/reports/xtra/asyncjobs/3ef414b68e06878acb65bff67b90b026/Gini-Xtra-All-Equipment.txt.gz"
$DestinationPath = "C:\Util\CCD\GiniData\AllGiniAssets.gz"

try {
    # Create a web client object
    $WebClient = New-Object System.Net.WebClient

    # Optional: Bypass SSL certificate validation (use with caution)
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    # Download the file
    $WebClient.DownloadFile($Url, $DestinationPath)
    Write-Output "File downloaded successfully to $DestinationPath"
} catch {
    Write-Error "Failed to download file: $_"
} finally {
    # Clean up
    if ($WebClient) {
        $WebClient.Dispose()
    }
}

#######################################################################################################

#### Unzipping the zip file downloaded from gini ###########

$gzipFile = "C:\Util\CCD\GiniData\AllGiniAssets.gz"
$outputFile = "C:\Util\CCD\GiniData\AllGiniAssets"

# Unzip the .gz file
$gzipStream = [System.IO.Compression.GzipStream]::new([System.IO.FileStream]::new($gzipFile, [System.IO.FileMode]::Open), [System.IO.Compression.CompressionMode]::Decompress)
$fileStream = [System.IO.FileStream]::new($outputFile, [System.IO.FileMode]::Create)
$gzipStream.CopyTo($fileStream)
$gzipStream.Close()
$fileStream.Close()

######################################################################################################



###############Converting the file to text file ########################

$extractedFile = "C:\Util\CCD\GiniData\AllGiniAssets"
$txtFile = "C:\Util\CCD\GiniData\AllGiniAssets.txt"

# Convert the extracted file to .txt
Get-Content $extractedFile | Set-Content $txtFile



#######################################################################

 Write-Host "Loading ........" -ForegroundColor Magenta


################Converting the text file to Excel file #####################3
# Define paths
$SourcePath = "C:\Util\CCD\GiniData\AllGiniAssets.txt"
$DestinationPath = "C:\Util\CCD\GiniData\AllGiniAssets.xlsx" 
# Remove the existing file if it exists
if (Test-Path $DestinationPath) {
    Remove-Item $DestinationPath -Recurse -Force
}
# Create Excel COM object
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $false
$Workbook = $Excel.Workbooks.Add()
$Worksheet = $Workbook.Worksheets.Item(1)

# Read the text file
$Content = Get-Content -Path $SourcePath

# Split the content into rows and columns
for ($i = 0; $i -lt $Content.Length; $i++) {
    $RowData = $Content[$i] -split "\t"  # Adjust delimiter if needed


    #$RowData = $RowData[0..1] + $RowData[3..($RowData.Length - 1)]

    for ($j = 0; $j -lt $RowData.Length; $j++) {
        $Worksheet.Cells.Item($i + 1, $j + 1) = $RowData[$j]
    }
}

# Save the workbook
$Workbook.SaveAs($DestinationPath) 
$Excel.Quit()

# Release COM objects
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Worksheet)
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbook)
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel)


###############################################################################################3


###### Deleting unwanted rows from the excel file #####################################

$ExcelFilePath = "C:\Util\CCD\GiniData\AllGiniAssets.xlsx"
$ColumnsToDelete = @(4 , 5 , 6,10,11,12 ,14,16,17 ,18 ,19 ,20 ,22 ,2,13,21,25,26 ,27,28 ,31 ,32 ,33,34,35,36,37,38,39,40)  # Specify the column numbers to delete (e.g., 3, 5, 7)

# Create Excel COM object
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $false
$Workbook = $Excel.Workbooks.Open($ExcelFilePath)
$Worksheet = $Workbook.Worksheets.Item(1)

# Sort the columns in descending order to avoid shifting issues
$ColumnsToDelete = $ColumnsToDelete | Sort-Object -Descending

# Delete the specified columns
foreach ($Column in $ColumnsToDelete) {
    $Worksheet.Columns.Item($Column).Delete()
}

# Save and close the workbook
$Workbook.Save()
$Workbook.Close()
$Excel.Quit()

##########################################################################################