# Quick Status Check Script
# Run this to verify automation is running correctly

Write-Host "========================================" -ForegroundColor Green
Write-Host "Automation Status Check" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Python process is running
$pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*user_behavior*" -or $_.Path -like "*python*"
}

if ($pythonProcess) {
    Write-Host "✓ Python process is RUNNING" -ForegroundColor Green
    Write-Host "  Process ID: $($pythonProcess.Id)" -ForegroundColor Cyan
    Write-Host "  Started: $($pythonProcess.StartTime)" -ForegroundColor Cyan
    $runtime = (Get-Date) - $pythonProcess.StartTime
    Write-Host "  Runtime: $($runtime.Days) days, $($runtime.Hours) hours, $($runtime.Minutes) minutes" -ForegroundColor Cyan
} else {
    Write-Host "✗ Python process NOT FOUND" -ForegroundColor Red
    Write-Host "  Automation may have stopped or not started correctly" -ForegroundColor Yellow
}

Write-Host ""

# Check for log files
$logFiles = Get-ChildItem -Path "C:\Automation" -Filter "user_behavior.log" -ErrorAction SilentlyContinue
if ($logFiles) {
    Write-Host "✓ Log file found: user_behavior.log" -ForegroundColor Green
    $latestLog = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "  Last updated: $($latestLog.LastWriteTime)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Last 10 log entries:" -ForegroundColor Yellow
    Get-Content $latestLog.FullName -Tail 10 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Log file NOT FOUND" -ForegroundColor Red
    Write-Host "  Check if script is running from correct directory" -ForegroundColor Yellow
}

Write-Host ""

# Check for activity logs
$activityLogs = Get-ChildItem -Path "C:\Automation" -Filter "activity_log_*.json" -ErrorAction SilentlyContinue
if ($activityLogs) {
    Write-Host "✓ Activity logs found: $($activityLogs.Count) files" -ForegroundColor Green
    $latestActivity = $activityLogs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "  Latest: $($latestActivity.Name)" -ForegroundColor Cyan
    Write-Host "  Last updated: $($latestActivity.LastWriteTime)" -ForegroundColor Cyan
    
    try {
        $activityData = Get-Content $latestActivity.FullName -Raw | ConvertFrom-Json
        Write-Host "  Total activities: $($activityData.total_activities)" -ForegroundColor Cyan
        Write-Host "  Duration: $($activityData.duration_hours) hours" -ForegroundColor Cyan
    } catch {
        Write-Host "  (Could not parse activity log)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ No activity logs yet (may be too early)" -ForegroundColor Yellow
}

Write-Host ""

# Check Sysmon events
try {
    $sysmonCount = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue -MaxEvents 1).Count
    if ($sysmonCount -gt 0) {
        Write-Host "✓ Sysmon is logging events" -ForegroundColor Green
        $recentEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100 -ErrorAction SilentlyContinue
        Write-Host "  Recent events (last 100): $($recentEvents.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠ Sysmon may not be logging" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Could not check Sysmon (may need Administrator privileges)" -ForegroundColor Yellow
}

Write-Host ""

# Check disk space
$disk = Get-PSDrive C
$freePercent = [math]::Round(($disk.Free / ($disk.Used + $disk.Free)) * 100, 2)
Write-Host "Disk Space (C:\):" -ForegroundColor Yellow
Write-Host "  Free: $([math]::Round($disk.Free / 1GB, 2)) GB ($freePercent%)" -ForegroundColor $(if ($freePercent -lt 10) { "Red" } else { "Cyan" })

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

if (-not $pythonProcess) {
    Write-Host "1. Start automation: python user_behavior_simulator.py --days 5" -ForegroundColor White
}

if ($freePercent -lt 10) {
    Write-Host "2. WARNING: Low disk space! Clean up old files" -ForegroundColor Red
}

Write-Host "3. Check logs periodically: Get-Content user_behavior.log -Tail 20" -ForegroundColor White
Write-Host "4. Monitor progress: Get-Content activity_log_*.json | ConvertFrom-Json | Select total_activities" -ForegroundColor White
Write-Host "5. Leave the script running - it will continue for the configured duration" -ForegroundColor White

Write-Host ""

