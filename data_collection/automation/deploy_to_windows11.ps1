# Automated Deployment Script for Windows 11 VM
# Run this script on the Windows 11 VM to set up everything automatically

param(
    [string]$AutomationPath = "C:\Automation",
    [switch]$SkipSysmon = $false,
    [switch]$SkipChrome = $false
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Windows 11 VM Automation Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as administrator. Some steps may fail." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to cancel, or press Enter to continue..." -ForegroundColor Yellow
    Read-Host
}

# Step 1: Create Automation Directory
Write-Host "[1/8] Creating automation directory..." -ForegroundColor Cyan
if (-not (Test-Path $AutomationPath)) {
    New-Item -ItemType Directory -Path $AutomationPath -Force | Out-Null
    Write-Host "  Created: $AutomationPath" -ForegroundColor Green
} else {
    Write-Host "  Directory exists: $AutomationPath" -ForegroundColor Yellow
}

# Step 2: Install Sysmon
if (-not $SkipSysmon) {
    Write-Host "[2/8] Installing Sysmon..." -ForegroundColor Cyan
    try {
        $sysmonPath = "$env:USERPROFILE\Downloads\Sysmon"
        if (-not (Test-Path "$sysmonPath\Sysmon.exe")) {
            Write-Host "  Downloading Sysmon..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "$env:USERPROFILE\Downloads\Sysmon.zip" -UseBasicParsing
            Expand-Archive "$env:USERPROFILE\Downloads\Sysmon.zip" -DestinationPath $sysmonPath -Force
        }
        
        Write-Host "  Installing Sysmon..." -ForegroundColor Yellow
        & "$sysmonPath\Sysmon.exe" -i -accepteula 2>&1 | Out-Null
        
        # Download and apply config
        Write-Host "  Downloading Sysmon configuration..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "$sysmonPath\sysmonconfig.xml" -UseBasicParsing
        & "$sysmonPath\Sysmon.exe" -c "$sysmonPath\sysmonconfig.xml" 2>&1 | Out-Null
        
        Write-Host "  Sysmon installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Sysmon - $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[2/8] Skipping Sysmon installation..." -ForegroundColor Yellow
}

# Step 3: Enable PowerShell Script Block Logging
Write-Host "[3/8] Enabling PowerShell Script Block Logging..." -ForegroundColor Cyan
try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -ErrorAction SilentlyContinue
    
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1 -ErrorAction SilentlyContinue
    
    Write-Host "  PowerShell logging enabled" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Failed to enable PowerShell logging - $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Install Python
Write-Host "[4/8] Checking Python installation..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Python found: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python not found"
    }
} catch {
    Write-Host "  Python not found. Installing..." -ForegroundColor Yellow
    try {
        $pythonUrl = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"
        $pythonInstaller = "$env:USERPROFILE\Downloads\python-installer.exe"
        
        Write-Host "  Downloading Python..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        
        Write-Host "  Installing Python (this may take a few minutes)..." -ForegroundColor Yellow
        Start-Process $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait -NoNewWindow
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "  Python installed. Please restart PowerShell and run this script again." -ForegroundColor Yellow
        exit 0
    } catch {
        Write-Host "  ERROR: Failed to install Python - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Please install Python manually from https://www.python.org/downloads/" -ForegroundColor Yellow
    }
}

# Step 5: Install Chrome
if (-not $SkipChrome) {
    Write-Host "[5/8] Checking Chrome installation..." -ForegroundColor Cyan
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    if (Test-Path $chromePath) {
        Write-Host "  Chrome found" -ForegroundColor Green
    } else {
        Write-Host "  Chrome not found. Installing..." -ForegroundColor Yellow
        try {
            $chromeInstaller = "$env:USERPROFILE\Downloads\chrome-installer.exe"
            Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstaller -UseBasicParsing
            Start-Process $chromeInstaller -ArgumentList "/silent /install" -Wait -NoNewWindow
            Write-Host "  Chrome installed" -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Failed to install Chrome - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[5/8] Skipping Chrome installation..." -ForegroundColor Yellow
}

# Step 6: Install Python Dependencies
Write-Host "[6/8] Installing Python dependencies..." -ForegroundColor Cyan
$requirementsFile = Join-Path $PSScriptRoot "requirements.txt"
if (Test-Path $requirementsFile) {
    Write-Host "  Installing packages from requirements.txt..." -ForegroundColor Yellow
    pip install -r $requirementsFile --quiet
    Write-Host "  Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  WARNING: requirements.txt not found. Installing basic packages..." -ForegroundColor Yellow
    pip install selenium webdriver-manager requests pandas --quiet
}

# Step 7: Configure PowerShell Execution Policy
Write-Host "[7/8] Configuring PowerShell execution policy..." -ForegroundColor Cyan
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    Write-Host "  Execution policy configured" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Failed to set execution policy - $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 8: Create Scheduled Task
Write-Host "[8/8] Creating scheduled task..." -ForegroundColor Cyan
try {
    $taskName = "UserBehaviorSimulation"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Host "  Scheduled task already exists. Removing old task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    $scriptPath = Join-Path $AutomationPath "user_behavior_simulator.py"
    if (-not (Test-Path $scriptPath)) {
        Write-Host "  WARNING: Automation script not found at $scriptPath" -ForegroundColor Yellow
        Write-Host "  Please copy automation scripts to $AutomationPath" -ForegroundColor Yellow
    } else {
        $action = New-ScheduledTaskAction `
            -Execute "python.exe" `
            -Argument "`"$scriptPath`" --duration 24 --interval 60" `
            -WorkingDirectory $AutomationPath
        
        $trigger = New-ScheduledTaskTrigger -Daily -At 9AM
        $trigger.Repetition = New-ScheduledTaskRepetition -Interval (New-TimeSpan -Hours 1) -Duration (New-TimeSpan -Days 7)
        
        $principal = New-ScheduledTaskPrincipal `
            -UserId "$env:USERNAME" `
            -LogonType Interactive `
            -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable
        
        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Automated user behavior simulation for data collection" | Out-Null
        
        Write-Host "  Scheduled task created successfully" -ForegroundColor Green
        Write-Host "  Task will run daily at 9 AM" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Failed to create scheduled task - $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Copy automation scripts to: $AutomationPath" -ForegroundColor White
Write-Host "2. Verify scripts are in place:" -ForegroundColor White
Write-Host "   - user_behavior_simulator.py" -ForegroundColor Gray
Write-Host "   - powershell_automation.ps1" -ForegroundColor Gray
Write-Host "   - requirements.txt" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test automation manually:" -ForegroundColor White
Write-Host "   cd $AutomationPath" -ForegroundColor Gray
Write-Host "   python user_behavior_simulator.py --duration 1 --interval 30" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Start scheduled task:" -ForegroundColor White
Write-Host "   Start-ScheduledTask -TaskName UserBehaviorSimulation" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Monitor logs:" -ForegroundColor White
Write-Host "   Get-Content $AutomationPath\user_behavior.log -Tail 50 -Wait" -ForegroundColor Gray
Write-Host ""

