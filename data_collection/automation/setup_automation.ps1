# Setup Script for User Behavior Automation
# Run this on the Windows VM to set up automation environment

Write-Host "Setting up User Behavior Automation Environment..." -ForegroundColor Green

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Warning: Not running as administrator. Some features may not work." -ForegroundColor Yellow
}

# 1. Check Python installation
Write-Host "`n[1/6] Checking Python installation..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python not found. Please install Python 3.10 or higher." -ForegroundColor Red
    Write-Host "Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# 2. Install Python dependencies
Write-Host "`n[2/6] Installing Python dependencies..." -ForegroundColor Cyan
$requirementsFile = Join-Path $PSScriptRoot "requirements.txt"
if (Test-Path $requirementsFile) {
    pip install -r $requirementsFile
    Write-Host "Dependencies installed." -ForegroundColor Green
} else {
    Write-Host "requirements.txt not found. Skipping." -ForegroundColor Yellow
}

# 3. Check Chrome installation
Write-Host "`n[3/6] Checking Chrome installation..." -ForegroundColor Cyan
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    Write-Host "Chrome found." -ForegroundColor Green
} else {
    Write-Host "Chrome not found. Selenium web browsing will not work." -ForegroundColor Yellow
    Write-Host "Download from: https://www.google.com/chrome/" -ForegroundColor Yellow
}

# 4. Configure PowerShell execution policy
Write-Host "`n[4/6] Configuring PowerShell execution policy..." -ForegroundColor Cyan
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "Execution policy configured." -ForegroundColor Green
} catch {
    Write-Host "Failed to set execution policy. Run as administrator." -ForegroundColor Yellow
}

# 5. Create directories
Write-Host "`n[5/6] Creating directories..." -ForegroundColor Cyan
$directories = @(
    "$env:USERPROFILE\Desktop\test_files",
    "$env:USERPROFILE\Documents\automation_docs"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Green
    }
}

# 6. Verify Sysmon (optional)
Write-Host "`n[6/6] Checking Sysmon..." -ForegroundColor Cyan
$sysmonService = Get-Service -Name "Sysmon*" -ErrorAction SilentlyContinue
if ($sysmonService) {
    Write-Host "Sysmon found: $($sysmonService.Name)" -ForegroundColor Green
    Write-Host "Status: $($sysmonService.Status)" -ForegroundColor Green
} else {
    Write-Host "Sysmon not found. Install Sysmon for event logging." -ForegroundColor Yellow
    Write-Host "Download from: https://docs.microsoft.com/sysinternals/downloads/sysmon" -ForegroundColor Yellow
}

Write-Host "`nSetup completed!" -ForegroundColor Green
Write-Host "`nTo start automation, run:" -ForegroundColor Cyan
Write-Host "  python user_behavior_simulator.py --duration 24 --interval 60" -ForegroundColor White
Write-Host "`nOr use PowerShell:" -ForegroundColor Cyan
Write-Host "  .\powershell_automation.ps1 -DurationHours 24 -ActivityInterval 60" -ForegroundColor White



