# Dataset Verification Script
# Verifies that all required data has been collected after automation deployment

[CmdletBinding()]
param(
    [string]$AutomationPath = "C:\Automation",
    [string]$SysmonLogPath = "C:\SysmonLogs",
    [int]$ExpectedDays = 5,
    [int]$ExpectedActivitiesPerDay = 1440,  # ~60 activities/hour * 24 hours
    [switch]$AutoExport,
    [switch]$NoExit,
    [switch]$RunSelfTests,
    [string[]]$FailOn = @()  # e.g. @('AutomationLog','SysmonEvents')
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Dataset Verification Report" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$allChecksPassed = $true
$scriptHadError = $false
$criticalFailed = $false

# Helper: mark a check as failed and optionally mark it critical if requested
function Mark-Failure {
    param([string]$Name)
    $script:allChecksPassed = $false
    if ($FailOn -and ($FailOn -contains $Name)) {
        $script:criticalFailed = $true
        Write-Verbose "Marked critical failure: $Name"
    } else {
        Write-Verbose "Marked non-critical failure: $Name"
    }
}

# Self-tests (quick, non-destructive)
function Run-SelfTests {
    Write-Host "Running self-tests..." -ForegroundColor Cyan
    $results = @()

    # Test: AutomationPath exists or can be created
    try {
        if (-not (Test-Path $AutomationPath)) { New-Item -ItemType Directory -Path $AutomationPath -Force | Out-Null }
        $results += @{Name='AutomationPath'; Passed=$true}
    } catch {
        $results += @{Name='AutomationPath'; Passed=$false; Error=$_.Exception.Message}
    }

    # Test: can create SysmonLogPath
    try {
        if (-not (Test-Path $SysmonLogPath)) { New-Item -ItemType Directory -Path $SysmonLogPath -Force | Out-Null }
        $results += @{Name='SysmonLogPath'; Passed=$true}
    } catch {
        $results += @{Name='SysmonLogPath'; Passed=$false; Error=$_.Exception.Message}
    }

    # Test: wevtutil is available (in PATH)
    try {
        $which = Get-Command wevtutil -ErrorAction Stop
        $results += @{Name='wevtutil'; Passed=$true}
    } catch {
        $results += @{Name='wevtutil'; Passed=$false; Error='wevtutil not found in PATH'}
    }

    foreach ($r in $results) {
        if ($r.Passed) { Write-Host "  $($r.Name): OK" -ForegroundColor Green } else { Write-Host "  $($r.Name): FAIL - $($r.Error)" -ForegroundColor Yellow }
    }

    # Return non-zero if any self-test failed
    if ($results | Where-Object { -not $_.Passed }) { return $false } else { return $true }
}

if ($RunSelfTests) {
    $ok = Run-SelfTests
    if ($ok) { Write-Host "Self-tests passed" -ForegroundColor Green } else { Write-Host "Self-tests failed" -ForegroundColor Red }
    if (-not $NoExit) { exit ([int]( -not $ok )) }
}

# Defensive: avoid division by zero later
if ($ExpectedDays -le 0) { $ExpectedDays = 1 }

# 1. Check Automation Activity Logs
Write-Host "[1/6] Checking Automation Activity Logs..." -ForegroundColor Cyan
$activityLogs = Get-ChildItem -Path $AutomationPath -Filter "activity_log_*.json" -ErrorAction SilentlyContinue

if ($activityLogs) {
    Write-Host "  [OK] Found $($activityLogs.Count) activity log file(s)" -ForegroundColor Green
    
    $totalActivities = 0
    $totalDuration = 0
    
    foreach ($log in $activityLogs) {
        try {
            $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
            $totalActivities += $data.total_activities
            $totalDuration += $data.duration_hours
            
            Write-Host "    - $($log.Name): $($data.total_activities) activities, $($data.duration_hours) hours" -ForegroundColor Gray
        } catch {
            Write-Host "    [WARN] Could not parse $($log.Name)" -ForegroundColor Yellow
        }
    }
    
    $expectedActivities = $ExpectedDays * $ExpectedActivitiesPerDay
    $coverage = [math]::Round(($totalActivities / $expectedActivities) * 100, 2)
    
    Write-Host "  Total Activities: $totalActivities (Expected: ~$expectedActivities)" -ForegroundColor $(if ($coverage -ge 80) { "Green" } else { "Yellow" })
    Write-Host "  Total Duration: $totalDuration hours (Expected: $($ExpectedDays * 24) hours)" -ForegroundColor $(if ($totalDuration -ge ($ExpectedDays * 24 * 0.8)) { "Green" } else { "Yellow" })
    Write-Host "  Coverage: $coverage%" -ForegroundColor $(if ($coverage -ge 80) { "Green" } else { "Yellow" })
    
    if ($coverage -lt 80) {
        Mark-Failure -Name "ActivityLogs"
        Write-Host "  [WARN] WARNING: Activity coverage is below 80%" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FAIL] No activity logs found!" -ForegroundColor Red
    Mark-Failure -Name "ActivityLogs"
}

Write-Host ""

# 2. Check Sysmon Logs
Write-Host "[2/6] Checking Sysmon Event Logs..." -ForegroundColor Cyan

try {
    $sysmonEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue -MaxEvents 1
    if ($sysmonEvents) {
        $totalSysmonEvents = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue).Count
        Write-Host "  [OK] Sysmon is logging events" -ForegroundColor Green
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
            Write-Host "  [WARN] WARNING: Sysmon event count is below expected minimum ($expectedMin)" -ForegroundColor Yellow
            $allChecksPassed = $false
        } elseif ($totalSysmonEvents -gt $expectedMax) {
            Write-Host "  [INFO] INFO: Sysmon event count is above expected maximum (this is OK)" -ForegroundColor Cyan
        } else {
            Write-Host "  [OK] Sysmon event count is within expected range" -ForegroundColor Green
        }
    } else {
        Write-Host "  [FAIL] No Sysmon events found!" -ForegroundColor Red
        Write-Host "    Check if Sysmon is installed and running" -ForegroundColor Yellow
        Mark-Failure -Name "SysmonEvents"
    }
} catch {
    Write-Host "  [FAIL] Could not access Sysmon logs (may need Administrator privileges)" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Mark-Failure -Name "SysmonEvents"
}

Write-Host ""

# 3. Check PowerShell Logs
Write-Host "[3/6] Checking PowerShell Event Logs..." -ForegroundColor Cyan

try {
    $psEvents = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue -MaxEvents 1
    if ($psEvents) {
        $totalPSEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue).Count
        Write-Host "  [OK] PowerShell logging is enabled" -ForegroundColor Green
        Write-Host "  Total PowerShell Events: $totalPSEvents" -ForegroundColor Cyan
        
        # Check for Event ID 4104 (Script Block Logging)
        $scriptBlockEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -FilterXPath "*[System[EventID=4104]]" -ErrorAction SilentlyContinue).Count
        Write-Host "    - Event ID 4104 (Script Blocks): $scriptBlockEvents events" -ForegroundColor Gray
        
        if ($scriptBlockEvents -eq 0) {
            Write-Host "  [WARN] WARNING: No PowerShell script block events found" -ForegroundColor Yellow
            Write-Host "    PowerShell script block logging may not be enabled" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] No PowerShell events found (may not be enabled)" -ForegroundColor Yellow
        Mark-Failure -Name "PowerShellEvents"
    }
} catch {
    Write-Host "  [WARN] Could not access PowerShell logs" -ForegroundColor Yellow
}

Write-Host ""

# 4. Check Generated Test Files
Write-Host "[4/6] Checking Generated Test Files..." -ForegroundColor Cyan

$desktop = [Environment]::GetFolderPath("Desktop")
$testFiles = Get-ChildItem -Path $desktop -Filter "test_*.txt" -ErrorAction SilentlyContinue

if ($testFiles) {
    Write-Host "  [OK] Found $($testFiles.Count) test file(s)" -ForegroundColor Green
    Write-Host "    Location: $desktop" -ForegroundColor Gray
    
    $totalSize = ($testFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "    Total Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Gray
    
    # Expected: 200-1000 files for 5 days
    $expectedMin = 200
    $expectedMax = 1000
    
    if ($testFiles.Count -lt $expectedMin) {
        Write-Host "  [WARN] WARNING: Test file count is below expected minimum ($expectedMin)" -ForegroundColor Yellow
    } elseif ($testFiles.Count -gt $expectedMax) {
        Write-Host "  [INFO] INFO: Test file count is above expected (this is OK)" -ForegroundColor Cyan
    } else {
        Write-Host "  [OK] Test file count is within expected range" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] No test files found (may be normal if file operations were not executed)" -ForegroundColor Yellow
    Mark-Failure -Name "TestFiles"
}

Write-Host ""

# 5. Check Automation Log File
Write-Host "[5/6] Checking Automation Log File..." -ForegroundColor Cyan

$logFile = Join-Path $AutomationPath "user_behavior.log"
if (Test-Path $logFile) {
    $logSize = (Get-Item $logFile).Length / 1MB
    $logLines = (Get-Content $logFile).Count
    $lastModified = (Get-Item $logFile).LastWriteTime
    
    Write-Host "  [OK] Log file found" -ForegroundColor Green
    Write-Host "    Size: $([math]::Round($logSize, 2)) MB" -ForegroundColor Gray
    Write-Host "    Lines: $logLines" -ForegroundColor Gray
    Write-Host "    Last Modified: $lastModified" -ForegroundColor Gray
    
    # Check for errors in log
    $errorCount = (Select-String -Path $logFile -Pattern "ERROR|Error|error" -ErrorAction SilentlyContinue).Count
    if ($errorCount -gt 0) {
        Write-Host "    [WARN] Found $errorCount error(s) in log file" -ForegroundColor Yellow
    } else {
        Write-Host "    [OK] No errors found in log file" -ForegroundColor Green
    }
    
    # Check for completion message
    $completed = Select-String -Path $logFile -Pattern "Simulation completed|completed" -ErrorAction SilentlyContinue
    if ($completed) {
        Write-Host "    [OK] Simulation completion detected" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] Simulation may still be running or did not complete" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FAIL] Log file not found!" -ForegroundColor Red
    Mark-Failure -Name "AutomationLog"
}

Write-Host ""

# 6. Check Exported EVTX Files
Write-Host "[6/6] Checking Exported EVTX Files..." -ForegroundColor Cyan

if (-not (Test-Path $SysmonLogPath)) {
    New-Item -ItemType Directory -Path $SysmonLogPath -Force | Out-Null
}

$evtxFiles = Get-ChildItem -Path $SysmonLogPath -Filter "*.evtx" -ErrorAction SilentlyContinue

if ($evtxFiles) {
    Write-Host "  [OK] Found $($evtxFiles.Count) exported EVTX file(s)" -ForegroundColor Green
    
    $totalEvtxSize = ($evtxFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "    Total Size: $([math]::Round($totalEvtxSize, 2)) GB" -ForegroundColor Gray
    
    foreach ($file in $evtxFiles) {
        $fileSize = $file.Length / 1MB
        Write-Host "    - $($file.Name): $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    }
} else {
    Write-Host "  [WARN] No exported EVTX files found" -ForegroundColor Yellow
    Write-Host "    You may need to export Sysmon logs manually:" -ForegroundColor Yellow

    # Build export command safely
    $exportFile = Join-Path -Path $SysmonLogPath -ChildPath ("SysmonLogs_{0}.evtx" -f (Get-Date -Format "yyyyMMdd"))
    $exportCmd = "wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"$exportFile`""
    Write-Host "    $exportCmd" -ForegroundColor Gray

    # Offer to export automatically if requested
    if ($AutoExport) {
        Write-Host "Auto-export enabled: attempting to export Sysmon log to $exportFile" -ForegroundColor Cyan
        try {
            Start-Process -FilePath "wevtutil.exe" -ArgumentList @("epl","Microsoft-Windows-Sysmon/Operational",$exportFile) -Verb RunAs -Wait -ErrorAction Stop
            Write-Host "  [OK] Exported Sysmon events to $exportFile" -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Auto-export failed (may require elevation): $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "    You can run the printed wevtutil command in an elevated shell." -ForegroundColor Yellow
            Mark-Failure -Name "ExportedEVTX"
        }
    } else {
        $ans = Read-Host "Do you want to export Sysmon logs now? (Y/N)"
        if ($ans -and $ans.ToUpper().StartsWith("Y")) {
            try {
                Start-Process -FilePath "wevtutil.exe" -ArgumentList @("epl","Microsoft-Windows-Sysmon/Operational",$exportFile) -Verb RunAs -Wait -ErrorAction Stop
                Write-Host "  [OK] Exported Sysmon events to $exportFile" -ForegroundColor Green
            } catch {
                Write-Host "  [WARN] Export failed (may require elevation): $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "    You can run the printed wevtutil command in an elevated shell." -ForegroundColor Yellow
                Mark-Failure -Name "ExportedEVTX"
            }
        } else {
            Mark-Failure -Name "ExportedEVTX"
        }
    }
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "Verification Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($allChecksPassed) {
    Write-Host "[OK] All critical checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your dataset appears to be complete. Next steps:" -ForegroundColor Cyan
    # Build safe export commands using configured SysmonLogPath
    $sysmonFinal = Join-Path -Path $SysmonLogPath -ChildPath "SysmonLogs_Final.evtx"
    $psFinal     = Join-Path -Path $SysmonLogPath -ChildPath "PowerShellLogs_Final.evtx"
    $sysmonExport = "wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"$sysmonFinal`""
    $psExport     = "wevtutil epl `"Microsoft-Windows-PowerShell/Operational`" `"$psFinal`""
    Write-Host "1. Export Sysmon logs: $sysmonExport" -ForegroundColor White
    Write-Host "2. Export PowerShell logs: $psExport" -ForegroundColor White
    Write-Host "3. Process the data using: python scripts/process_evtx_files.py" -ForegroundColor White
} else {
    Write-Host "[WARN] Some checks failed or warnings were found" -ForegroundColor Yellow
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
    "Activity Logs" = if ($activityLogs) { "[OK]" } else { "[FAIL]" }
    "Sysmon Events" = if ($sysmonEvents) { "[OK]" } else { "[FAIL]" }
    "PowerShell Events" = if ($psEvents) { "[OK]" } else { "[WARN]" }
    "Test Files" = if ($testFiles) { "[OK]" } else { "[WARN]" }
    "Automation Log" = if (Test-Path $logFile) { "[OK]" } else { "[FAIL]" }
    "Exported EVTX" = if ($evtxFiles) { "[OK]" } else { "[WARN]" }
}

foreach ($metric in $metrics.GetEnumerator()) {
    Write-Host "  $($metric.Key): $($metric.Value)" -ForegroundColor $(if ($metric.Value -eq "[OK]") { "Green" } elseif ($metric.Value -eq "[WARN]") { "Yellow" } else { "Red" })
}

Write-Host ""

# Final exit handling (no top-level try/catch to avoid parser mismatches)
if ($scriptHadError) {
    Write-Host ""
    Write-Host "Exiting with status: FAILURE (1) - unexpected error encountered" -ForegroundColor Red
    if (-not $NoExit) { exit 1 } else { return 1 }
}

if ($criticalFailed) {
    Write-Host ""
    $separator = ", "
    $failedChecks = $FailOn -join $separator
    Write-Host "Critical checks failed: $failedChecks" -ForegroundColor Red
    if (-not $NoExit) { exit 1 } else { return 1 }
}

if (-not $allChecksPassed) {
    Write-Host ""
    Write-Host "Completed with warnings (non-fatal). Exiting with status: SUCCESS (0)" -ForegroundColor Yellow
    if (-not $NoExit) { exit 0 } else { return 0 }
}

Write-Host ""
Write-Host "Exiting with status: SUCCESS (0)" -ForegroundColor Green
if (-not $NoExit) { exit 0 } else { return 0 }
