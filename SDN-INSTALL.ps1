<#
.SYNOPSIS
    SDN Tool Installation Script
.DESCRIPTION
    Installs and configures the SDN Tool with required dependencies and directory structure.
.NOTES
    Version: 2.0
    Author: IT Operations Team
    Requires: PowerShell 5.1 or higher, Administrator privileges
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration
$Script:Config = @{
    SourceDir      = Get-Location
    DestinationDir = $env:USERPROFILE
    ToolBasePath   = 'C:\Util\CCD'
    ZipFileName    = 'CCD.zip'
    RequiredModule = 'ImportExcel'
    LogFile        = "$env:TEMP\SDN_Install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    PlinkUrl       = 'https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe'
    PlinkPath      = 'C:\Program Files (x86)\PuTTY'
}

#region Functions

function Write-Log {
    <#
    .SYNOPSIS
        Writes messages to console and log file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $Script:Config.LogFile -Value $logMessage -ErrorAction SilentlyContinue
    
    # Write to console with appropriate color
    $colorMap = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Level]
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
        Displays an animated progress bar
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Activity = "Processing",
        
        [Parameter()]
        [int]$TotalSteps = 20,
        
        [Parameter()]
        [int]$DelayMs = 250
    )
    
    for ($i = 0; $i -le $TotalSteps; $i++) {
        $percentComplete = [math]::Round(($i / $TotalSteps) * 100)
        $progressBar = '[' + ('=' * $i) + (' ' * ($TotalSteps - $i)) + ']'
        
        Write-Progress -Activity $Activity -Status "$percentComplete% Complete" -PercentComplete $percentComplete
        Write-Host "`r$Activity $percentComplete% $progressBar" -ForegroundColor Green -NoNewline
        
        Start-Sleep -Milliseconds $DelayMs
    }
    
    Write-Host ""
    Write-Progress -Activity $Activity -Completed
}

function Install-RequiredModule {
    <#
    .SYNOPSIS
        Installs the required PowerShell module
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )
    
    try {
        Write-Log "Checking for $ModuleName module..." -Level Info
        
        if (Get-Module -ListAvailable -Name $ModuleName) {
            Write-Log "$ModuleName module is already installed." -Level Success
            Import-Module $ModuleName -ErrorAction Stop
            return $true
        }
        
        Write-Log "Installing $ModuleName module..." -Level Warning
        Install-Module -Name $ModuleName -Scope AllUsers -Force -AllowClobber -ErrorAction Stop
        Import-Module $ModuleName -ErrorAction Stop
        
        Write-Log "$ModuleName module installed successfully." -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to install $ModuleName module: $_" -Level Error
        return $false
    }
}

function Copy-ZipFiles {
    <#
    .SYNOPSIS
        Copies all ZIP files from source to destination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        
        [Parameter(Mandatory)]
        [string]$Destination
    )
    
    try {
        $zipFiles = Get-ChildItem -Path $Source -Filter '*.zip' -ErrorAction Stop
        
        if ($zipFiles.Count -eq 0) {
            Write-Log "No ZIP files found in $Source" -Level Warning
            return $false
        }
        
        Write-Log "Found $($zipFiles.Count) ZIP file(s). Copying to $Destination..." -Level Info
        
        foreach ($zipFile in $zipFiles) {
            Copy-Item -Path $zipFile.FullName -Destination $Destination -Force -ErrorAction Stop
            Write-Log "Copied: $($zipFile.Name)" -Level Success
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to copy ZIP files: $_" -Level Error
        return $false
    }
}

function Initialize-ToolEnvironment {
    <#
    .SYNOPSIS
        Creates required directory structure and files
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath
    )
    
    try {
        # Check if already installed
        if (Test-Path -Path "$BasePath\Customers_CSV") {
            Write-Log "SDN Tool is already installed at $BasePath" -Level Warning
            return $false
        }
        
        Write-Log "Creating SDN Tool directory structure..." -Level Info
        
        # Create directories
        $directories = @(
            "$BasePath\Customers_CSV",
            "$BasePath\GiniData"
        )
        
        foreach ($dir in $directories) {
            New-Item -Path $dir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Log "Created directory: $dir" -Level Success
        }
        
        # Create credentials file
        $credentialsPath = "$BasePath\Credentials.txt"
        $credentialsContent = "nuar-username,nuar-password"
        New-Item -Path $credentialsPath -ItemType File -Force -Value $credentialsContent -ErrorAction Stop | Out-Null
        Write-Log "Created credentials template: $credentialsPath" -Level Success
        
        Write-Log "SDN Tool environment created successfully." -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to create tool environment: $_" -Level Error
        return $false
    }
}

function Expand-ToolArchive {
    <#
    .SYNOPSIS
        Extracts the tool archive to the installation directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )
    
    try {
        if (-not (Test-Path -Path $ArchivePath)) {
            Write-Log "Archive file not found: $ArchivePath" -Level Error
            return $false
        }
        
        Write-Log "Extracting archive to $DestinationPath..." -Level Info
        Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force -ErrorAction Stop
        
        Write-Log "Archive extracted successfully." -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to extract archive: $_" -Level Error
        return $false
    }
}

function Show-CompletionDialog {
    <#
    .SYNOPSIS
        Displays installation completion message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$Success
    )
    
    if ($Success) {
        [void][System.Windows.Forms.MessageBox]::Show(
            "SDN Tool has been successfully installed!`n`nLog file: $($Script:Config.LogFile)",
            'Installation Complete',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    else {
        [void][System.Windows.Forms.MessageBox]::Show(
            "Installation encountered errors.`n`nPlease review the log file: $($Script:Config.LogFile)",
            'Installation Failed',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Install-PlinkTool {
    <#
    .SYNOPSIS
        Downloads and installs PuTTY Plink tool
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        
        [Parameter(Mandatory)]
        [string]$InstallPath
    )
    
    try {
        $plinkExe = Join-Path -Path $InstallPath -ChildPath 'plink.exe'
        
        # Check if already installed
        if (Test-Path -Path $plinkExe) {
            Write-Log "Plink is already installed at $plinkExe" -Level Success
            return $true
        }
        
        Write-Log "Installing PuTTY Plink..." -Level Info
        
        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force -ErrorAction Stop | Out-Null
            Write-Log "Created directory: $InstallPath" -Level Success
        }
        
        # Download Plink
        Write-Log "Downloading Plink from $Url..." -Level Info
        Invoke-WebRequest -Uri $Url -OutFile $plinkExe -ErrorAction Stop
        Write-Log "Plink downloaded successfully." -Level Success
        
        # Add to system PATH if not already present
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        
        if ($currentPath -notlike "*$InstallPath*") {
            Write-Log "Adding Plink to system PATH..." -Level Info
            $newPath = $currentPath.TrimEnd(';') + ";$InstallPath"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
            Write-Log "Plink added to system PATH." -Level Success
            Write-Log "Note: You may need to restart your terminal for PATH changes to take effect." -Level Warning
        }
        else {
            Write-Log "Plink directory already in system PATH." -Level Success
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to install Plink: $_" -Level Error
        return $false
    }
}

#endregion

#region Main Script

try {
    Write-Log "=== SDN Tool Installation Started ===" -Level Info
    Write-Log "Log file: $($Script:Config.LogFile)" -Level Info
    
    # Step 1: Install required module
    $moduleInstalled = Install-RequiredModule -ModuleName $Script:Config.RequiredModule
    if (-not $moduleInstalled) {
        throw "Failed to install required module."
    }
    
    # Step 2: Install PuTTY Plink
    $plinkInstalled = Install-PlinkTool -Url $Script:Config.PlinkUrl -InstallPath $Script:Config.PlinkPath
    if (-not $plinkInstalled) {
        Write-Log "Plink installation failed, but continuing with main installation..." -Level Warning
    }
    
    # Step 3: Copy ZIP files
    $filesCopied = Copy-ZipFiles -Source $Script:Config.SourceDir -Destination $Script:Config.DestinationDir
    
    # Step 4: Initialize tool environment
    $envCreated = Initialize-ToolEnvironment -BasePath $Script:Config.ToolBasePath
    
    # Step 5: Extract archive
    Push-Location $Script:Config.DestinationDir
    $archiveExtracted = Expand-ToolArchive -ArchivePath ".\$($Script:Config.ZipFileName)" -DestinationPath 'C:\Util'
    Pop-Location
    
    # Step 6: Show completion progress
    Show-ProgressBar -Activity "Finalizing installation" -TotalSteps 20 -DelayMs 100
    
    # Determine overall success
    $installationSuccess = $moduleInstalled -and $archiveExtracted
    
    Write-Log "=== SDN Tool Installation Completed ===" -Level $(if ($installationSuccess) { 'Success' } else { 'Error' })
    
    # Show completion dialog
    Show-CompletionDialog -Success $installationSuccess
    
    # Exit prompt
    Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
    Read-Host
}
catch {
    Write-Log "Critical error during installation: $_" -Level Error
    Show-CompletionDialog -Success $false
    
    Write-Host "`nPress Enter to exit..." -ForegroundColor Red
    Read-Host
    exit 1
}

#endregion