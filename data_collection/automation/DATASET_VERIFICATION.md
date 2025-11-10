# Dataset Verification Guide

Complete guide for verifying that all required data has been collected after automation deployment.

## Quick Verification

Run the automated verification script:

```powershell
cd C:\Automation
.\verify_dataset.ps1
```

Or with custom parameters:

```powershell
.\verify_dataset.ps1 -ExpectedDays 5 -ExpectedActivitiesPerDay 1440
```

## Manual Verification Steps

### 1. Check Automation Activity Logs

**Location**: `C:\Automation\activity_log_*.json`

**What to check:**
- Number of activity log files
- Total activities recorded
- Total duration (should match your run duration)

```powershell
# Count activity logs
Get-ChildItem C:\Automation\activity_log_*.json | Measure-Object

# Check total activities
$logs = Get-ChildItem C:\Automation\activity_log_*.json
$total = 0
foreach ($log in $logs) {
    $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
    $total += $data.total_activities
    Write-Host "$($log.Name): $($data.total_activities) activities, $($data.duration_hours) hours"
}
Write-Host "Total: $total activities"
```

**Expected for 5 days:**
- ~7,200 activities (with 60-second intervals)
- ~14,400 activities (with 30-second intervals)
- 120 hours total duration

### 2. Check Sysmon Event Logs

**Location**: Windows Event Viewer → `Microsoft-Windows-Sysmon/Operational`

**What to check:**
- Total event count
- Key Event IDs (1, 7, 10, 11, 13, 22)
- Event time range

```powershell
# Check total Sysmon events (requires Administrator)
$total = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue).Count
Write-Host "Total Sysmon Events: $total"

# Check specific Event IDs
$eventIds = @(1, 7, 10, 11, 13, 22)
foreach ($eventId in $eventIds) {
    $count = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=$eventId]]" -ErrorAction SilentlyContinue).Count
    Write-Host "Event ID $eventId : $count events"
}

# Check time range
$events = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1 -ErrorAction SilentlyContinue
if ($events) {
    $first = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -Oldest -ErrorAction SilentlyContinue)[0]
    $last = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -Newest -ErrorAction SilentlyContinue)[0]
    Write-Host "First Event: $($first.TimeCreated)"
    Write-Host "Last Event: $($last.TimeCreated)"
    Write-Host "Duration: $(($last.TimeCreated - $first.TimeCreated).TotalDays) days"
}
```

**Expected for 5 days:**
- 50,000-200,000 total events
- Event ID 1 (Process Creation): 5,000-20,000 events
- Event ID 7 (Image Loaded): 20,000-100,000 events
- Event ID 11 (File Created): 1,000-5,000 events

### 3. Check PowerShell Event Logs

**Location**: Windows Event Viewer → `Microsoft-Windows-PowerShell/Operational`

**What to check:**
- Event ID 4104 (Script Block Logging)
- Total PowerShell events

```powershell
# Check PowerShell events (requires Administrator)
$total = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue).Count
Write-Host "Total PowerShell Events: $total"

# Check script block events
$scriptBlocks = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -FilterXPath "*[System[EventID=4104]]" -ErrorAction SilentlyContinue).Count
Write-Host "Script Block Events (4104): $scriptBlocks"
```

**Expected for 5 days:**
- 1,000-5,000 PowerShell events
- 500-2,000 script block events (Event ID 4104)

### 4. Check Generated Test Files

**Location**: `%USERPROFILE%\Desktop\test_*.txt`

**What to check:**
- Number of test files
- File sizes
- File timestamps

```powershell
# Count test files
$desktop = [Environment]::GetFolderPath("Desktop")
$files = Get-ChildItem -Path $desktop -Filter "test_*.txt"
Write-Host "Test Files: $($files.Count)"

# Check file sizes
$totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Total Size: $([math]::Round($totalSize, 2)) MB"

# Check time range
if ($files) {
    $oldest = ($files | Sort-Object LastWriteTime)[0]
    $newest = ($files | Sort-Object LastWriteTime -Descending)[0]
    Write-Host "Oldest: $($oldest.LastWriteTime)"
    Write-Host "Newest: $($newest.LastWriteTime)"
}
```

**Expected for 5 days:**
- 200-1,000 test files
- Files spanning the entire automation duration

### 5. Check Automation Log File

**Location**: `C:\Automation\user_behavior.log`

**What to check:**
- Log file exists and has content
- No critical errors
- Completion message

```powershell
$logFile = "C:\Automation\user_behavior.log"
if (Test-Path $logFile) {
    $size = (Get-Item $logFile).Length / 1MB
    $lines = (Get-Content $logFile).Count
    Write-Host "Log Size: $([math]::Round($size, 2)) MB"
    Write-Host "Log Lines: $lines"
    
    # Check for errors
    $errors = Select-String -Path $logFile -Pattern "ERROR|Error|error"
    Write-Host "Errors: $($errors.Count)"
    
    # Check for completion
    $completed = Select-String -Path $logFile -Pattern "Simulation completed"
    if ($completed) {
        Write-Host "Status: Completed"
    } else {
        Write-Host "Status: May still be running"
    }
    
    # Show last 10 lines
    Write-Host "`nLast 10 lines:"
    Get-Content $logFile -Tail 10
}
```

### 6. Check Exported EVTX Files

**Location**: `C:\SysmonLogs\*.evtx`

**What to check:**
- EVTX files exported
- File sizes
- File count

```powershell
$evtxFiles = Get-ChildItem C:\SysmonLogs\*.evtx -ErrorAction SilentlyContinue
if ($evtxFiles) {
    Write-Host "EVTX Files: $($evtxFiles.Count)"
    $totalSize = ($evtxFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "Total Size: $([math]::Round($totalSize, 2)) GB"
} else {
    Write-Host "No EVTX files found. Export logs:"
    Write-Host "wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"C:\SysmonLogs\SysmonLogs_Final.evtx`""
}
```

## Export Logs for Processing

### Export Sysmon Logs

```powershell
# Create export directory
New-Item -ItemType Directory -Path "C:\SysmonLogs" -Force

# Export Sysmon log
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\SysmonLogs_Final_$(Get-Date -Format 'yyyyMMdd').evtx"

# Verify export
Get-Item "C:\SysmonLogs\SysmonLogs_Final_*.evtx" | Select-Object Name, Length, LastWriteTime
```

### Export PowerShell Logs

```powershell
# Export PowerShell log
wevtutil epl "Microsoft-Windows-PowerShell/Operational" "C:\SysmonLogs\PowerShellLogs_Final_$(Get-Date -Format 'yyyyMMdd').evtx"
```

### Export All Relevant Logs

```powershell
# Export all logs
$date = Get-Date -Format 'yyyyMMdd'
$exportPath = "C:\SysmonLogs"

wevtutil epl "Microsoft-Windows-Sysmon/Operational" "$exportPath\SysmonLogs_$date.evtx"
wevtutil epl "Microsoft-Windows-PowerShell/Operational" "$exportPath\PowerShellLogs_$date.evtx"
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "$exportPath\SysmonLogs_ProcessCreation_$date.evtx" /q:"*[System[EventID=1]]"
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "$exportPath\SysmonLogs_ImageLoaded_$date.evtx" /q:"*[System[EventID=7]]"
```

## Data Quality Checklist

### Minimum Requirements

- [ ] At least 1 activity log file exists
- [ ] Total activities >= 5,000 (for 5-day run)
- [ ] Sysmon events >= 50,000
- [ ] Automation log file exists
- [ ] No critical errors in log file

### Recommended Requirements

- [ ] Activity coverage >= 80% of expected
- [ ] Sysmon events >= 100,000
- [ ] PowerShell script block events >= 500
- [ ] Test files >= 200
- [ ] EVTX files exported
- [ ] Logs span full duration (5 days)

### Quality Indicators

**Good Quality:**
- ✓ High activity count (>= 7,000 for 5 days)
- ✓ High Sysmon event count (>= 100,000)
- ✓ Diverse event types (all key Event IDs present)
- ✓ Consistent activity throughout duration
- ✓ No critical errors in logs

**Poor Quality:**
- ✗ Low activity count (< 3,000 for 5 days)
- ✗ Low Sysmon event count (< 20,000)
- ✗ Missing event types
- ✗ Large gaps in activity timeline
- ✗ Many errors in logs

## Processing the Data

After verification, process the data:

```bash
# On your host machine
python scripts/process_evtx_files.py \
    --input-dir C:\SysmonLogs \
    --output-dir data/processed/ \
    --label 0
```

## Troubleshooting

### Low Activity Count

**Possible causes:**
- Automation stopped early
- Errors prevented activities
- VM went to sleep

**Solutions:**
- Check automation log for errors
- Verify automation is still running
- Check VM power settings

### Low Sysmon Event Count

**Possible causes:**
- Sysmon not running
- Sysmon configuration issues
- Event log full

**Solutions:**
- Verify Sysmon service: `Get-Service Sysmon`
- Check Sysmon configuration
- Clear old events if log is full

### Missing PowerShell Events

**Possible causes:**
- Script block logging not enabled
- PowerShell logging disabled

**Solutions:**
- Enable script block logging
- Check Group Policy settings

## Summary

**Quick Check:**
```powershell
.\verify_dataset.ps1
```

**Expected Results for 5-Day Run:**
- 7,200+ activities
- 100,000+ Sysmon events
- 1,000+ PowerShell events
- 200+ test files
- Complete automation log

If all checks pass, your dataset is ready for processing!

