# Continuous Benign Data Collection Script (Label 0)
# Runs user behavior simulator continuously for benign data collection
# This script will run indefinitely until manually stopped

[CmdletBinding()]
param(
    [int]$ActivityInterval = 60,  # Seconds between activities (default: 60)
    [int]$CycleDuration = 24,     # Hours per cycle before restarting (default: 24)
    [string]$AutomationPath = "",  # Will default to script directory
    [switch]$Background,           # Run in background
    [switch]$NoExit                # Don't exit on errors, keep retrying
)

$ErrorActionPreference = "Continue"

# Set default automation path to script directory if not specified
if ([string]::IsNullOrEmpty($AutomationPath)) {
    $AutomationPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($AutomationPath)) {
        $AutomationPath = $PSScriptRoot
    }
    if ([string]::IsNullOrEmpty($AutomationPath)) {
        $AutomationPath = Get-Location
    }
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Continuous Benign Data Collection" -ForegroundColor Green
Write-Host "Label: 0 (Benign)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Create automation directory if it doesn't exist
if (-not (Test-Path $AutomationPath)) {
    Write-Host "Creating automation directory: $AutomationPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $AutomationPath -Force | Out-Null
}

Set-Location $AutomationPath

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Python not found! Please install Python." -ForegroundColor Red
    if (-not $NoExit) { exit 1 }
    return
}

# Check if enhanced simulator script exists (preferred)
$enhancedSimulatorScript = Join-Path $AutomationPath "user_behavior_simulator_enhanced.py"
$simulatorScript = Join-Path $AutomationPath "user_behavior_simulator.py"

# Prefer enhanced simulator if available
if (Test-Path $enhancedSimulatorScript) {
    $simulatorScript = $enhancedSimulatorScript
    Write-Host "Using ENHANCED simulator for better event diversity" -ForegroundColor Green
} elseif (-not (Test-Path $simulatorScript)) {
    Write-Host "ERROR: No simulator script found!" -ForegroundColor Red
    Write-Host "  Expected: $enhancedSimulatorScript" -ForegroundColor Yellow
    Write-Host "  Or: $simulatorScript" -ForegroundColor Yellow
    Write-Host "Please ensure a simulator script is in the automation directory." -ForegroundColor Yellow
    if (-not $NoExit) { exit 1 }
    return
} else {
    Write-Host "Using standard simulator (enhanced version recommended)" -ForegroundColor Yellow
}

# Check dependencies
Write-Host "Checking dependencies..." -ForegroundColor Cyan
try {
    python -c "import selenium; import requests; import pandas" 2>&1 | Out-Null
    Write-Host "Dependencies OK" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Some dependencies missing. Attempting to install..." -ForegroundColor Yellow
    $requirementsFile = Join-Path $AutomationPath "requirements.txt"
    if (Test-Path $requirementsFile) {
        pip install -r $requirementsFile --quiet
    } else {
        pip install selenium requests pandas --quiet
    }
}

# Create log directory
$logDir = Join-Path $AutomationPath "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Create status file
$statusFile = Join-Path $AutomationPath "collection_status.json"
$pidFile = Join-Path $AutomationPath "collection.pid"

# Function to update status
function Update-Status {
    param(
        [string]$Status,
        [int]$Cycle = 0,
        [int]$TotalActivities = 0,
        [string]$LastActivity = ""
    )
    $statusData = @{
        status = $Status
        cycle = $Cycle
        total_activities = $TotalActivities
        last_activity = $LastActivity
        start_time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        activity_interval = $ActivityInterval
        cycle_duration = $CycleDuration
    } | ConvertTo-Json
    $statusData | Out-File -FilePath $statusFile -Encoding UTF8
}

# Function to check if already running
function Test-CollectionRunning {
    if (Test-Path $pidFile) {
        $pidValue = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($pid) {
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
            if ($process -and $process.ProcessName -eq "python") {
                $commandLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $pid").CommandLine
                if ($commandLine -like "*user_behavior_simulator*") {
                    return $true
                }
            }
        }
    }
    return $false
}

# Check if already running
if (Test-CollectionRunning) {
    Write-Host "WARNING: Collection appears to be already running!" -ForegroundColor Yellow
    $response = Read-Host "Continue anyway? (y/n)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        exit
    }
}

# Save current PID
$currentPID = $PID
$currentPID | Out-File -FilePath $pidFile -Encoding ASCII

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Simulator: $(Split-Path -Leaf $simulatorScript)" -ForegroundColor White
Write-Host "  Activity Interval: $ActivityInterval seconds (base, varies by time of day)" -ForegroundColor White
Write-Host "  Cycle Duration: $CycleDuration hours" -ForegroundColor White
Write-Host "  Automation Path: $AutomationPath" -ForegroundColor White
Write-Host "  Process ID: $currentPID" -ForegroundColor White
Write-Host ""
if ($simulatorScript -like "*enhanced*") {
    Write-Host "Enhanced Features:" -ForegroundColor Cyan
    Write-Host "  - Time-based activity patterns" -ForegroundColor Gray
    Write-Host "  - LOLBin commands (legitimate usage)" -ForegroundColor Gray
    Write-Host "  - Network operations" -ForegroundColor Gray
    Write-Host "  - Registry operations" -ForegroundColor Gray
    Write-Host "  - More diverse system commands" -ForegroundColor Gray
    Write-Host ""
}
Write-Host "Starting continuous benign data collection..." -ForegroundColor Green
Write-Host "This will run indefinitely. Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# Initialize status
Update-Status -Status "Starting" -Cycle 0

$cycleCount = 0
$totalActivities = 0

# Main loop - runs continuously
while ($true) {
    $cycleCount++
    $cycleStartTime = Get-Date
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Cycle $cycleCount - Starting" -ForegroundColor Cyan
    Write-Host "Start Time: $($cycleStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "Duration: $CycleDuration hours" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Update-Status -Status "Running" -Cycle $cycleCount -TotalActivities $totalActivities
    
    # Build command
    $pythonArgs = @(
        $simulatorScript,
        "--duration", $CycleDuration,
        "--interval", $ActivityInterval
    )
    
    try {
        if ($Background) {
            # Run in background
            $process = Start-Process -FilePath "python.exe" `
                -ArgumentList $pythonArgs `
                -WorkingDirectory $AutomationPath `
                -WindowStyle Hidden `
                -PassThru `
                -NoNewWindow
            
            Write-Host "Collection started in background (PID: $($process.Id))" -ForegroundColor Green
            $process.WaitForExit()
            $exitCode = $process.ExitCode
        } else {
            # Run in foreground
            $process = Start-Process -FilePath "python.exe" `
                -ArgumentList $pythonArgs `
                -WorkingDirectory $AutomationPath `
                -PassThru `
                -NoNewWindow `
                -Wait
            
            $exitCode = $process.ExitCode
        }
        
        $cycleEndTime = Get-Date
        $cycleDuration = ($cycleEndTime - $cycleStartTime).TotalHours
        
        # Count activities from log files
        $activityLogs = Get-ChildItem -Path $AutomationPath -Filter "activity_log_*.json" -ErrorAction SilentlyContinue
        if ($activityLogs) {
            $cycleActivities = 0
            foreach ($log in $activityLogs) {
                try {
                    $logData = Get-Content $log.FullName -Raw | ConvertFrom-Json
                    $cycleActivities += $logData.total_activities
                } catch {
                    # Ignore parse errors
                }
            }
            $totalActivities = $cycleActivities
        }
        
        Write-Host ""
        Write-Host "Cycle $cycleCount completed" -ForegroundColor Green
        Write-Host "  Duration: $([math]::Round($cycleDuration, 2)) hours" -ForegroundColor White
        Write-Host "  Activities: $totalActivities" -ForegroundColor White
        Write-Host "  Exit Code: $exitCode" -ForegroundColor White
        Write-Host ""
        
        Update-Status -Status "Completed" -Cycle $cycleCount -TotalActivities $totalActivities -LastActivity $cycleEndTime.ToString("yyyy-MM-dd HH:mm:ss")
        
        if ($exitCode -ne 0 -and -not $NoExit) {
            Write-Host "ERROR: Cycle $cycleCount exited with code $exitCode" -ForegroundColor Red
            Write-Host "Stopping collection." -ForegroundColor Yellow
            break
        }
        
        # Brief pause before next cycle
        Write-Host "Waiting 10 seconds before starting next cycle..." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
        
    } catch {
        Write-Host "ERROR in cycle $cycleCount : $($_.Exception.Message)" -ForegroundColor Red
        Update-Status -Status "Error" -Cycle $cycleCount -TotalActivities $totalActivities
        
        if (-not $NoExit) {
            Write-Host "Stopping collection due to error." -ForegroundColor Yellow
            break
        }
        
        Write-Host "Retrying in 60 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 60
    }
}

# Cleanup
if (Test-Path $pidFile) {
    Remove-Item $pidFile -Force
}

Update-Status -Status "Stopped" -Cycle $cycleCount -TotalActivities $totalActivities

Write-Host ""
Write-Host "Collection stopped." -ForegroundColor Yellow
Write-Host "Total cycles completed: $cycleCount" -ForegroundColor Cyan
Write-Host "Total activities: $totalActivities" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status file: $statusFile" -ForegroundColor Gray
Write-Host "Logs directory: $logDir" -ForegroundColor Gray

