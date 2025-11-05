# PowerShell User Behavior Automation Script
# Simulates realistic Windows user activity

param(
    [int]$DurationHours = 24,
    [int]$ActivityInterval = 60
)

$ErrorActionPreference = "SilentlyContinue"
$StartTime = Get-Date
$EndTime = $StartTime.AddHours($DurationHours)
$ActivityLog = @()

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
    $script:ActivityLog += @{
        Timestamp = $Timestamp
        Message = $Message
    }
}

function Start-WebBrowsing {
    Write-Log "Starting web browsing activity"
    $Sites = @(
        "https://www.google.com",
        "https://www.github.com",
        "https://www.microsoft.com",
        "https://www.stackoverflow.com"
    )
    $Site = Get-Random -InputObject $Sites
    Start-Process $Site
    Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 15)
}

function Start-FileOperations {
    Write-Log "Starting file operations"
    $Desktop = [Environment]::GetFolderPath("Desktop")
    $Documents = [Environment]::GetFolderPath("MyDocuments")
    
    # Create test file
    $TestFile = Join-Path $Desktop "test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    "Test file created at $(Get-Date)" | Out-File -FilePath $TestFile
    Write-Log "Created file: $TestFile"
    
    # List directory
    Get-ChildItem $Documents -Recurse -Depth 1 | Select-Object -First 10 | Out-Null
    Write-Log "Listed directory: $Documents"
    
    # Copy file
    $Files = Get-ChildItem $Desktop -File | Select-Object -First 5
    if ($Files) {
        $SourceFile = $Files | Get-Random
        $DestFile = Join-Path $Desktop "copy_$($SourceFile.Name)"
        Copy-Item $SourceFile.FullName $DestFile -ErrorAction SilentlyContinue
        Write-Log "Copied file: $($SourceFile.Name)"
    }
}

function Start-OfficeApplication {
    Write-Log "Opening Office application"
    $Apps = @(
        @{Name="Notepad"; Path="notepad.exe"},
        @{Name="Calculator"; Path="calc.exe"},
        @{Name="Paint"; Path="mspaint.exe"}
    )
    $App = Get-Random -InputObject $Apps
    Start-Process $App.Path
    Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 5)
    Stop-Process -Name $App.Name -ErrorAction SilentlyContinue -Force
}

function Start-SystemCommands {
    Write-Log "Running system commands"
    $Commands = @(
        { Get-Process | Select-Object -First 10 },
        { Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object -First 10 },
        { Get-ChildItem $env:USERPROFILE | Select-Object -First 10 },
        { Get-Date },
        { Get-ComputerInfo | Select-Object TotalPhysicalMemory, OSName },
        { ipconfig /all },
        { netstat -an | Select-Object -First 10 },
        { tasklist }
    )
    $Command = Get-Random -InputObject $Commands
    & $Command | Out-Null
}

function Start-PowerShellActivity {
    Write-Log "Running PowerShell commands"
    $PSCommands = @(
        "Get-Process | Select-Object -First 5",
        "Get-Service | Where-Object {`$_.Status -eq 'Running'} | Select-Object -First 5",
        "Get-ChildItem `$env:USERPROFILE\Documents | Select-Object -First 10",
        "Get-Date",
        "Get-EventLog -LogName Application -Newest 5"
    )
    $PSCommand = Get-Random -InputObject $PSCommands
    Invoke-Expression $PSCommand | Out-Null
}

function Start-BackgroundTasks {
    Write-Log "Running background tasks"
    # System maintenance
    Get-ChildItem $env:TEMP -Recurse | Measure-Object | Out-Null
    Write-Log "Completed system maintenance check"
}

function Select-RandomActivity {
    $Activities = @(
        @{Name="WebBrowsing"; Weight=25; Func={Start-WebBrowsing}},
        @{Name="FileOperations"; Weight=20; Func={Start-FileOperations}},
        @{Name="OfficeApplication"; Weight=15; Func={Start-OfficeApplication}},
        @{Name="SystemCommands"; Weight=15; Func={Start-SystemCommands}},
        @{Name="PowerShellActivity"; Weight=10; Func={Start-PowerShellActivity}},
        @{Name="BackgroundTasks"; Weight=15; Func={Start-BackgroundTasks}}
    )
    
    $TotalWeight = ($Activities | Measure-Object -Property Weight -Sum).Sum
    $Random = Get-Random -Minimum 0 -Maximum $TotalWeight
    $Cumulative = 0
    
    foreach ($Activity in $Activities) {
        $Cumulative += $Activity.Weight
        if ($Random -le $Cumulative) {
            return $Activity
        }
    }
    
    return $Activities[0]
}

Write-Log "Starting user behavior simulation for $DurationHours hours"
Write-Log "Activity interval: $ActivityInterval seconds"

while ((Get-Date) -lt $EndTime) {
    try {
        $Activity = Select-RandomActivity
        Write-Log "Executing: $($Activity.Name)"
        & $Activity.Func
        
        $WaitTime = Get-Random -Minimum ($ActivityInterval / 2) -Maximum ($ActivityInterval * 2)
        Write-Log "Waiting $WaitTime seconds before next activity"
        Start-Sleep -Seconds $WaitTime
    }
    catch {
        Write-Log "Error: $_"
        Start-Sleep -Seconds 30
    }
}

Write-Log "Simulation completed"

# Save activity log
$LogFile = "activity_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$ActivityLog | ConvertTo-Json | Out-File -FilePath $LogFile
Write-Log "Activity log saved to $LogFile"



