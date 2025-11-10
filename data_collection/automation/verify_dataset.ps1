# Dataset Verification Script
# Verifies that all required data has been collected after automation deployment

param(
    [string]$AutomationPath = "C:\Automation",
    [string]$SysmonLogPath = "C:\SysmonLogs",
    [int]$ExpectedDays = 5,
    [int]$ExpectedActivitiesPerDay = 1440  # ~60 activities/hour * 24 hours
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Dataset Verification Report" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$allChecksPassed = $true

# 1. Check Automation Activity Logs
Write-Host "[1/6] Checking Automation Activity Logs..." -ForegroundColor Cyan
$activityLogs = Get-ChildItem -Path $AutomationPath -Filter "activity_log_*.json" -ErrorAction SilentlyContinue

if ($activityLogs) {
    Write-Host "  ✓ Found $($activityLogs.Count) activity log file(s)" -ForegroundColor Green
    
    $totalActivities = 0
    $totalDuration = 0
    
    foreach ($log in $activityLogs) {
        try {
            $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
            $totalActivities += $data.total_activities
            $totalDuration += $data.duration_hours
            
            Write-Host "    - $($log.Name): $($data.total_activities) activities, $($data.duration_hours) hours" -ForegroundColor Gray
        } catch {
            Write-Host "    ⚠ Could not parse $($log.Name)" -ForegroundColor Yellow
        }
    }
    
    $expectedActivities = $ExpectedDays * $ExpectedActivitiesPerDay
    $coverage = [math]::Round(($totalActivities / $expectedActivities) * 100, 2)
    
    Write-Host "  Total Activities: $totalActivities (Expected: ~$expectedActivities)" -ForegroundColor $(if ($coverage -ge 80) { "Green" } else { "Yellow" })
    Write-Host "  Total Duration: $totalDuration hours (Expected: $($ExpectedDays * 24) hours)" -ForegroundColor $(if ($totalDuration -ge ($ExpectedDays * 24 * 0.8)) { "Green" } else { "Yellow" })
    Write-Host "  Coverage: $coverage%" -ForegroundColor $(if ($coverage -ge 80) { "Green" } else { "Yellow" })
    
    if ($coverage -lt 80) {
        $allChecksPassed = $false
        Write-Host "  ⚠ WARNING: Activity coverage is below 80%" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ No activity logs found!" -ForegroundColor Red
    $allChecksPassed = $false
}

Write-Host ""

# 2. Check Sysmon Logs
Write-Host "[2/6] Checking Sysmon Event Logs..." -ForegroundColor Cyan

try {
    $sysmonEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue -MaxEvents 1
    if ($sysmonEvents) {
        $totalSysmonEvents = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue).Count
        Write-Host "  ✓ Sysmon is logging events" -ForegroundColor Green
        Write-Host "  Total Sysmon Events: $totalSysmonEvents" -ForegroundColor Cyan
        
        # Check for key event IDs
        $eventIds = @(1, 7, 10, 11, 13, 22)
        foreach ($eventId in $eventIds) {
            $count = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=$eventId]]" -ErrorAction SilentlyContinue).Count
            Write-Host "    - Event ID $eventId : $count events" -ForegroundColor Gray
        }
        
        # Expected: 50,000-200,000 events for 5 days
        $expectedMin = 50000
        $expectedMax = 200000
        
        if ($totalSysmonEvents -lt $expectedMin) {
            Write-Host "  ⚠ WARNING: Sysmon event count is below expected minimum ($expectedMin)" -ForegroundColor Yellow
            $allChecksPassed = $false
        } elseif ($totalSysmonEvents -gt $expectedMax) {
            Write-Host "  ℹ INFO: Sysmon event count is above expected maximum (this is OK)" -ForegroundColor Cyan
        } else {
            Write-Host "  ✓ Sysmon event count is within expected range" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ No Sysmon events found!" -ForegroundColor Red
        Write-Host "    Check if Sysmon is installed and running" -ForegroundColor Yellow
        $allChecksPassed = $false
    }
} catch {
    Write-Host "  ✗ Could not access Sysmon logs (may need Administrator privileges)" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Yellow
    $allChecksPassed = $false
}

Write-Host ""

# 3. Check PowerShell Logs
Write-Host "[3/6] Checking PowerShell Event Logs..." -ForegroundColor Cyan

try {
    $psEvents = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue -MaxEvents 1
    if ($psEvents) {
        $totalPSEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue).Count
        Write-Host "  ✓ PowerShell logging is enabled" -ForegroundColor Green
        Write-Host "  Total PowerShell Events: $totalPSEvents" -ForegroundColor Cyan
        
        # Check for Event ID 4104 (Script Block Logging)
        $scriptBlockEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -FilterXPath "*[System[EventID=4104]]" -ErrorAction SilentlyContinue).Count
        Write-Host "    - Event ID 4104 (Script Blocks): $scriptBlockEvents events" -ForegroundColor Gray
        
        if ($scriptBlockEvents -eq 0) {
            Write-Host "  ⚠ WARNING: No PowerShell script block events found" -ForegroundColor Yellow
            Write-Host "    PowerShell script block logging may not be enabled" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠ No PowerShell events found (may not be enabled)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠ Could not access PowerShell logs" -ForegroundColor Yellow
}

Write-Host ""

# 4. Check Generated Test Files
Write-Host "[4/6] Checking Generated Test Files..." -ForegroundColor Cyan

$desktop = [Environment]::GetFolderPath("Desktop")
$testFiles = Get-ChildItem -Path $desktop -Filter "test_*.txt" -ErrorAction SilentlyContinue

if ($testFiles) {
    Write-Host "  ✓ Found $($testFiles.Count) test file(s)" -ForegroundColor Green
    Write-Host "    Location: $desktop" -ForegroundColor Gray
    
    $totalSize = ($testFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "    Total Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Gray
    
    # Expected: 200-1000 files for 5 days
    $expectedMin = 200
    $expectedMax = 1000
    
    if ($testFiles.Count -lt $expectedMin) {
        Write-Host "  ⚠ WARNING: Test file count is below expected minimum ($expectedMin)" -ForegroundColor Yellow
    } elseif ($testFiles.Count -gt $expectedMax) {
        Write-Host "  ℹ INFO: Test file count is above expected (this is OK)" -ForegroundColor Cyan
    } else {
        Write-Host "  ✓ Test file count is within expected range" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠ No test files found (may be normal if file operations weren't executed)" -ForegroundColor Yellow
}

Write-Host ""

# 5. Check Automation Log File
Write-Host "[5/6] Checking Automation Log File..." -ForegroundColor Cyan

$logFile = Join-Path $AutomationPath "user_behavior.log"
if (Test-Path $logFile) {
    $logSize = (Get-Item $logFile).Length / 1MB
    $logLines = (Get-Content $logFile).Count
    $lastModified = (Get-Item $logFile).LastWriteTime
    
    Write-Host "  ✓ Log file found" -ForegroundColor Green
    Write-Host "    Size: $([math]::Round($logSize, 2)) MB" -ForegroundColor Gray
    Write-Host "    Lines: $logLines" -ForegroundColor Gray
    Write-Host "    Last Modified: $lastModified" -ForegroundColor Gray
    
    # Check for errors in log
    $errorCount = (Select-String -Path $logFile -Pattern "ERROR|Error|error" -ErrorAction SilentlyContinue).Count
    if ($errorCount -gt 0) {
        Write-Host "    ⚠ Found $errorCount error(s) in log file" -ForegroundColor Yellow
    } else {
        Write-Host "    ✓ No errors found in log file" -ForegroundColor Green
    }
    
    # Check for completion message
    $completed = Select-String -Path $logFile -Pattern "Simulation completed|completed" -ErrorAction SilentlyContinue
    if ($completed) {
        Write-Host "    ✓ Simulation completion detected" -ForegroundColor Green
    } else {
        Write-Host "    ⚠ Simulation may still be running or didn't complete" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Log file not found!" -ForegroundColor Red
    $allChecksPassed = $false
}

Write-Host ""

# 6. Check Exported EVTX Files
Write-Host "[6/6] Checking Exported EVTX Files..." -ForegroundColor Cyan

if (-not (Test-Path $SysmonLogPath)) {
    New-Item -ItemType Directory -Path $SysmonLogPath -Force | Out-Null
}

$evtxFiles = Get-ChildItem -Path $SysmonLogPath -Filter "*.evtx" -ErrorAction SilentlyContinue

if ($evtxFiles) {
    Write-Host "  ✓ Found $($evtxFiles.Count) exported EVTX file(s)" -ForegroundColor Green
    
    $totalEvtxSize = ($evtxFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "    Total Size: $([math]::Round($totalEvtxSize, 2)) GB" -ForegroundColor Gray
    
    foreach ($file in $evtxFiles) {
        $fileSize = $file.Length / 1MB
        Write-Host "    - $($file.Name): $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ No exported EVTX files found" -ForegroundColor Yellow
    Write-Host "    You may need to export Sysmon logs manually:" -ForegroundColor Yellow
    Write-Host "    wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"$SysmonLogPath\SysmonLogs_$(Get-Date -Format 'yyyyMMdd').evtx`"" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "Verification Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($allChecksPassed) {
    Write-Host "✓ All critical checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your dataset appears to be complete. Next steps:" -ForegroundColor Cyan
    Write-Host "1. Export Sysmon logs: wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"C:\SysmonLogs\SysmonLogs_Final.evtx`"" -ForegroundColor White
    Write-Host "2. Export PowerShell logs: wevtutil epl `"Microsoft-Windows-PowerShell/Operational`" `"C:\SysmonLogs\PowerShellLogs_Final.evtx`"" -ForegroundColor White
    Write-Host "3. Process the data using: python scripts/process_evtx_files.py" -ForegroundColor White
} else {
    Write-Host "⚠ Some checks failed or warnings were found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Cyan
    Write-Host "- Check if automation is still running" -ForegroundColor White
    Write-Host "- Verify Sysmon is installed and running" -ForegroundColor White
    Write-Host "- Check automation log for errors" -ForegroundColor White
    Write-Host "- Ensure sufficient disk space" -ForegroundColor White
}

Write-Host ""

# Data Quality Metrics
Write-Host "Data Quality Metrics:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$metrics = @{
    "Activity Logs" = if ($activityLogs) { "✓" } else { "✗" }
    "Sysmon Events" = if ($sysmonEvents) { "✓" } else { "✗" }
    "PowerShell Events" = if ($psEvents) { "✓" } else { "⚠" }
    "Test Files" = if ($testFiles) { "✓" } else { "⚠" }
    "Automation Log" = if (Test-Path $logFile) { "✓" } else { "✗" }
    "Exported EVTX" = if ($evtxFiles) { "✓" } else { "⚠" }
}

foreach ($metric in $metrics.GetEnumerator()) {
    Write-Host "  $($metric.Key): $($metric.Value)" -ForegroundColor $(if ($metric.Value -eq "✓") { "Green" } elseif ($metric.Value -eq "⚠") { "Yellow" } else { "Red" })
}

Write-Host ""

