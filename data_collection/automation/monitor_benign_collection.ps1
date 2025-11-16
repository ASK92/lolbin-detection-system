# Monitor Benign Data Collection Script
# Checks if benign data collection is running and verifies data quality

[CmdletBinding()]
param(
    [string]$AutomationPath = "",  # Will default to script directory
    [string]$SysmonLogPath = "C:\SysmonLogs",
    [switch]$Continuous,      # Run continuously with periodic checks
    [int]$CheckInterval = 300, # Seconds between checks (default: 5 minutes)
    [switch]$AutoFix          # Attempt to fix issues automatically
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Benign Data Collection Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Automation Path: $AutomationPath" -ForegroundColor Gray
Write-Host ""

$allChecksPassed = $true
$warnings = @()
$errors = @()

# Function to check if collection process is running
function Test-CollectionProcess {
    $pidFile = Join-Path $AutomationPath "collection.pid"
    $statusFile = Join-Path $AutomationPath "collection_status.json"
    
    Write-Host "[1/8] Checking Collection Process..." -ForegroundColor Cyan
    
    # Check PID file
    if (-not (Test-Path $pidFile)) {
        Write-Host "  [FAIL] PID file not found - collection may not be running" -ForegroundColor Red
        $script:errors += "Collection process not found"
        return $false
    }
    
    $processId = Get-Content $pidFile -ErrorAction SilentlyContinue
    if (-not $processId) {
        Write-Host "  [FAIL] PID file is empty" -ForegroundColor Red
        $script:errors += "Invalid PID file"
        return $false
    }
    
    # Check if process exists
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Host "  [FAIL] Process $processId not found - collection may have crashed" -ForegroundColor Red
        $script:errors += "Collection process crashed (PID: $processId)"
        return $false
    }
    
    # Check if it's a Python process running the simulator
    $commandLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $processId" -ErrorAction SilentlyContinue).CommandLine
    if ($commandLine -notlike "*user_behavior_simulator*") {
        Write-Host "  [WARN] Process $processId exists but may not be running simulator" -ForegroundColor Yellow
        $script:warnings += "Process may not be running simulator"
    }
    
    # Check status file
    if (Test-Path $statusFile) {
        try {
            $status = Get-Content $statusFile -Raw | ConvertFrom-Json
            Write-Host "  [OK] Collection process is running (PID: $processId)" -ForegroundColor Green
            Write-Host "    Status: $($status.status)" -ForegroundColor Gray
            Write-Host "    Cycle: $($status.cycle)" -ForegroundColor Gray
            Write-Host "    Total Activities: $($status.total_activities)" -ForegroundColor Gray
            Write-Host "    Last Activity: $($status.last_activity)" -ForegroundColor Gray
            return $true
        } catch {
            Write-Host "  [WARN] Status file exists but could not be parsed" -ForegroundColor Yellow
        }
    }
    
    Write-Host "  [OK] Collection process is running (PID: $processId)" -ForegroundColor Green
    return $true
}

# Function to check automation log file
function Test-AutomationLog {
    Write-Host "[2/8] Checking Automation Log..." -ForegroundColor Cyan
    
    $logFile = Join-Path $AutomationPath "user_behavior.log"
    
    if (-not (Test-Path $logFile)) {
        Write-Host "  [WARN] Log file not found: $logFile" -ForegroundColor Yellow
        $script:warnings += "Automation log file not found"
        return $false
    }
    
    $logInfo = Get-Item $logFile
    $logSize = $logInfo.Length / 1MB
    $lastModified = $logInfo.LastWriteTime
    $ageMinutes = ((Get-Date) - $lastModified).TotalMinutes
    
    Write-Host "  [OK] Log file found" -ForegroundColor Green
    Write-Host "    Size: $([math]::Round($logSize, 2)) MB" -ForegroundColor Gray
    Write-Host "    Last Modified: $lastModified" -ForegroundColor Gray
    Write-Host "    Age: $([math]::Round($ageMinutes, 1)) minutes" -ForegroundColor Gray
    
    # Check if log is being updated (should be recent)
    if ($ageMinutes -gt 30) {
        Write-Host "  [WARN] Log file hasn't been updated in $([math]::Round($ageMinutes, 1)) minutes" -ForegroundColor Yellow
        $script:warnings += "Log file not updated recently"
    }
    
    # Check for errors in log
    $errorCount = (Select-String -Path $logFile -Pattern "ERROR|Error|error|Exception|Traceback" -ErrorAction SilentlyContinue).Count
    if ($errorCount -gt 0) {
        Write-Host "  [WARN] Found $errorCount error(s) in log file" -ForegroundColor Yellow
        $script:warnings += "Errors found in log file"
    } else {
        Write-Host "  [OK] No errors found in log file" -ForegroundColor Green
    }
    
    return $true
}

# Function to check activity logs
function Test-ActivityLogs {
    Write-Host "[3/8] Checking Activity Logs..." -ForegroundColor Cyan
    
    $activityLogs = Get-ChildItem -Path $AutomationPath -Filter "activity_log_*.json" -ErrorAction SilentlyContinue
    
    if (-not $activityLogs) {
        Write-Host "  [WARN] No activity log files found" -ForegroundColor Yellow
        $script:warnings += "No activity logs found"
        return $false
    }
    
    $totalActivities = 0
    $totalDuration = 0
    
    foreach ($log in $activityLogs) {
        try {
            $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
            $totalActivities += $data.total_activities
            $totalDuration += $data.duration_hours
        } catch {
            Write-Host "  [WARN] Could not parse $($log.Name)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "  [OK] Found $($activityLogs.Count) activity log file(s)" -ForegroundColor Green
    Write-Host "    Total Activities: $totalActivities" -ForegroundColor Gray
    Write-Host "    Total Duration: $totalDuration hours" -ForegroundColor Gray
    
    if ($totalActivities -eq 0) {
        Write-Host "  [WARN] No activities recorded" -ForegroundColor Yellow
        $script:warnings += "No activities recorded"
    }
    
    return $true
}

# Function to check Sysmon
function Test-Sysmon {
    Write-Host "[4/8] Checking Sysmon..." -ForegroundColor Cyan
    
    try {
        $sysmonService = Get-Service -Name "Sysmon" -ErrorAction SilentlyContinue
        if (-not $sysmonService) {
            Write-Host "  [FAIL] Sysmon service not found" -ForegroundColor Red
            $script:errors += "Sysmon not installed"
            return $false
        }
        
        if ($sysmonService.Status -ne "Running") {
            Write-Host "  [FAIL] Sysmon service is not running (Status: $($sysmonService.Status))" -ForegroundColor Red
            $script:errors += "Sysmon service not running"
            
            if ($AutoFix) {
                Write-Host "  Attempting to start Sysmon..." -ForegroundColor Yellow
                Start-Service -Name "Sysmon" -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                $sysmonService = Get-Service -Name "Sysmon"
                if ($sysmonService.Status -eq "Running") {
                    Write-Host "  [OK] Sysmon started successfully" -ForegroundColor Green
                }
            }
            return $false
        }
        
        Write-Host "  [OK] Sysmon is running" -ForegroundColor Green
        
        # Check event log (requires admin, may fail)
        try {
            $eventCount = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1 -ErrorAction SilentlyContinue).Count
            if ($eventCount -gt 0) {
                $totalEvents = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue).Count
                Write-Host "    Total Events: $totalEvents" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    [INFO] Cannot read Sysmon events (may need admin privileges)" -ForegroundColor Gray
        }
        
        return $true
    } catch {
        Write-Host "  [FAIL] Error checking Sysmon: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Error checking Sysmon"
        return $false
    }
}

# Function to check PowerShell logging
function Test-PowerShellLogging {
    Write-Host "[5/8] Checking PowerShell Logging..." -ForegroundColor Cyan
    
    try {
        $psEvents = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($psEvents) {
            $totalEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue).Count
            Write-Host "  [OK] PowerShell logging is enabled" -ForegroundColor Green
            Write-Host "    Total Events: $totalEvents" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "  [WARN] No PowerShell events found" -ForegroundColor Yellow
            $script:warnings += "PowerShell logging may not be enabled"
            return $false
        }
    } catch {
        Write-Host "  [WARN] Cannot check PowerShell logs: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to check disk space
function Test-DiskSpace {
    Write-Host "[6/8] Checking Disk Space..." -ForegroundColor Cyan
    
    $drive = (Get-Item $AutomationPath).PSDrive.Name
    $driveInfo = Get-PSDrive -Name $drive
    
    $freeSpaceGB = $driveInfo.Free / 1GB
    $usedSpaceGB = ($driveInfo.Used + $driveInfo.Free) / 1GB
    $percentFree = ($driveInfo.Free / ($driveInfo.Used + $driveInfo.Free)) * 100
    
    Write-Host "  Drive: $drive" -ForegroundColor Gray
    Write-Host "    Free Space: $([math]::Round($freeSpaceGB, 2)) GB ($([math]::Round($percentFree, 1))%)" -ForegroundColor Gray
    
    if ($freeSpaceGB -lt 1) {
        Write-Host "  [FAIL] Less than 1 GB free space remaining!" -ForegroundColor Red
        $script:errors += "Low disk space"
        return $false
    } elseif ($freeSpaceGB -lt 5) {
        Write-Host "  [WARN] Less than 5 GB free space remaining" -ForegroundColor Yellow
        $script:warnings += "Low disk space"
    } else {
        Write-Host "  [OK] Sufficient disk space" -ForegroundColor Green
    }
    
    return $true
}

# Function to check test files
function Test-TestFiles {
    Write-Host "[7/8] Checking Generated Test Files..." -ForegroundColor Cyan
    
    $desktop = [Environment]::GetFolderPath("Desktop")
    $testFiles = Get-ChildItem -Path $desktop -Filter "test_*.txt" -ErrorAction SilentlyContinue
    
    if ($testFiles) {
        Write-Host "  [OK] Found $($testFiles.Count) test file(s)" -ForegroundColor Green
        Write-Host "    Location: $desktop" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "  [INFO] No test files found (may be normal)" -ForegroundColor Gray
        return $true  # Not critical
    }
}

# Function to check recent activity
function Test-RecentActivity {
    Write-Host "[8/8] Checking Recent Activity..." -ForegroundColor Cyan
    
    $statusFile = Join-Path $AutomationPath "collection_status.json"
    
    if (-not (Test-Path $statusFile)) {
        Write-Host "  [WARN] Status file not found" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $status = Get-Content $statusFile -Raw | ConvertFrom-Json
        
        if ($status.last_activity) {
            $lastActivity = [DateTime]::Parse($status.last_activity)
            $minutesAgo = ((Get-Date) - $lastActivity).TotalMinutes
            
            Write-Host "  Last Activity: $($status.last_activity)" -ForegroundColor Gray
            Write-Host "    Age: $([math]::Round($minutesAgo, 1)) minutes ago" -ForegroundColor Gray
            
            if ($minutesAgo -gt 60) {
                Write-Host "  [WARN] No activity in the last hour" -ForegroundColor Yellow
                $script:warnings += "No recent activity"
                return $false
            } else {
                Write-Host "  [OK] Recent activity detected" -ForegroundColor Green
                return $true
            }
        }
    } catch {
        Write-Host "  [WARN] Could not parse status file" -ForegroundColor Yellow
        return $false
    }
}

# Main monitoring function
function Start-Monitoring {
    $checkCount = 0
    
    while ($true) {
        $checkCount++
        $checkTime = Get-Date
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Monitor Check #$checkCount" -ForegroundColor Cyan
        Write-Host "Time: $($checkTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        $script:allChecksPassed = $true
        $script:warnings = @()
        $script:errors = @()
        
        # Run all checks
        Test-CollectionProcess | Out-Null
        Write-Host ""
        Test-AutomationLog | Out-Null
        Write-Host ""
        Test-ActivityLogs | Out-Null
        Write-Host ""
        Test-Sysmon | Out-Null
        Write-Host ""
        Test-PowerShellLogging | Out-Null
        Write-Host ""
        Test-DiskSpace | Out-Null
        Write-Host ""
        Test-TestFiles | Out-Null
        Write-Host ""
        Test-RecentActivity | Out-Null
        
        # Summary
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Summary" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
            Write-Host "[OK] All checks passed!" -ForegroundColor Green
        } elseif ($errors.Count -eq 0) {
            Write-Host "[WARN] Checks passed with $($warnings.Count) warning(s)" -ForegroundColor Yellow
            foreach ($warn in $warnings) {
                Write-Host "  - $warn" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[FAIL] Found $($errors.Count) error(s) and $($warnings.Count) warning(s)" -ForegroundColor Red
            foreach ($err in $errors) {
                Write-Host "  ERROR: $err" -ForegroundColor Red
            }
            foreach ($warn in $warnings) {
                Write-Host "  WARN: $warn" -ForegroundColor Yellow
            }
        }
        
        if (-not $Continuous) {
            break
        }
        
        Write-Host ""
        Write-Host "Next check in $CheckInterval seconds..." -ForegroundColor Gray
        Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
        Start-Sleep -Seconds $CheckInterval
    }
}

# Run monitoring
Start-Monitoring

