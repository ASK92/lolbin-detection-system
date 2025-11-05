# Run Automation for 5 Days Straight
# This script ensures continuous operation for 5 days

param(
    [int]$Days = 5,
    [int]$ActivityInterval = 60
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Green
Write-Host "5-Day Continuous Automation Runner" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$DurationHours = $Days * 24
Write-Host "Duration: $Days days ($DurationHours hours)" -ForegroundColor Cyan
Write-Host "Activity Interval: $ActivityInterval seconds" -ForegroundColor Cyan
Write-Host "Estimated Activities: ~$([math]::Round($DurationHours * 3600 / $ActivityInterval))" -ForegroundColor Cyan
Write-Host ""

# Check if already running
$existingProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*user_behavior_simulator*"
}

if ($existingProcess) {
    Write-Host "WARNING: Automation may already be running!" -ForegroundColor Yellow
    Write-Host "Process ID: $($existingProcess.Id)" -ForegroundColor Yellow
    $response = Read-Host "Continue anyway? (y/n)"
    if ($response -ne 'y') {
        exit
    }
}

# Change to automation directory
$automationPath = "C:\Automation"
if (-not (Test-Path $automationPath)) {
    Write-Host "ERROR: Automation directory not found at $automationPath" -ForegroundColor Red
    Write-Host "Please copy automation scripts to $automationPath" -ForegroundColor Yellow
    exit 1
}

cd $automationPath

# Verify Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Python not found!" -ForegroundColor Red
    exit 1
}

# Verify dependencies
Write-Host "Checking dependencies..." -ForegroundColor Cyan
try {
    python -c "import selenium; import requests; import pandas" 2>&1 | Out-Null
    Write-Host "Dependencies OK" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Some dependencies missing. Installing..." -ForegroundColor Yellow
    pip install -r requirements.txt --quiet
}

# Create log directory
$logDir = "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

# Start automation
Write-Host ""
Write-Host "Starting 5-day automation..." -ForegroundColor Green
Write-Host "Log file: $automationPath\user_behavior.log" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will run for $Days days. Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# Run with output to both console and log file
$logFile = "logs\automation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
python user_behavior_simulator.py --days $Days --interval $ActivityInterval 2>&1 | Tee-Object -FilePath $logFile

Write-Host ""
Write-Host "Automation completed!" -ForegroundColor Green
Write-Host "Check logs in: $logFile" -ForegroundColor Cyan

