# Benign Data Collection Guide

This guide explains how to run continuous benign data collection (Label 0) and monitor it.

## Scripts

1. **`run_benign_collection.ps1`** - Continuous benign data collection script
2. **`monitor_benign_collection.ps1`** - Monitoring script to verify everything is running

## Quick Start

### Step 1: Start Benign Data Collection

```powershell
cd C:\Automation
.\run_benign_collection.ps1
```

This will:
- Run the user behavior simulator continuously
- Create cycles of 24 hours each (configurable)
- Generate activity logs and system events
- Run indefinitely until you stop it (Ctrl+C)

### Step 2: Monitor Collection (in another terminal)

```powershell
cd C:\Automation
.\monitor_benign_collection.ps1
```

This will:
- Check if collection is running
- Verify log files are being created
- Check Sysmon and PowerShell logging
- Monitor disk space
- Show summary of all checks

## Advanced Usage

### Run Collection in Background

```powershell
.\run_benign_collection.ps1 -Background
```

### Customize Activity Interval

```powershell
# More frequent activities (30 seconds)
.\run_benign_collection.ps1 -ActivityInterval 30

# Less frequent activities (120 seconds)
.\run_benign_collection.ps1 -ActivityInterval 120
```

### Customize Cycle Duration

```powershell
# 12-hour cycles
.\run_benign_collection.ps1 -CycleDuration 12

# 48-hour cycles
.\run_benign_collection.ps1 -CycleDuration 48
```

### Continuous Monitoring

```powershell
# Monitor every 5 minutes (default)
.\monitor_benign_collection.ps1 -Continuous

# Monitor every 10 minutes
.\monitor_benign_collection.ps1 -Continuous -CheckInterval 600
```

### Auto-Fix Issues

```powershell
# Automatically attempt to fix issues (e.g., restart Sysmon)
.\monitor_benign_collection.ps1 -Continuous -AutoFix
```

## Parameters

### run_benign_collection.ps1

- `-ActivityInterval <int>` - Seconds between activities (default: 60)
- `-CycleDuration <int>` - Hours per cycle before restarting (default: 24)
- `-AutomationPath <string>` - Path to automation directory (default: C:\Automation)
- `-Background` - Run in background (hidden window)
- `-NoExit` - Don't exit on errors, keep retrying

### monitor_benign_collection.ps1

- `-AutomationPath <string>` - Path to automation directory (default: C:\Automation)
- `-SysmonLogPath <string>` - Path to Sysmon logs (default: C:\SysmonLogs)
- `-Continuous` - Run continuously with periodic checks
- `-CheckInterval <int>` - Seconds between checks (default: 300 = 5 minutes)
- `-AutoFix` - Attempt to fix issues automatically

## What Gets Collected

### Activity Logs
- Location: `C:\Automation\activity_log_*.json`
- Contains: Detailed activity records with timestamps

### Automation Log
- Location: `C:\Automation\user_behavior.log`
- Contains: Real-time log of all activities and errors

### Sysmon Events
- Location: Windows Event Log
- Event IDs: 1 (Process Creation), 7 (Image Load), 10 (Process Access), 11 (File Creation), 13 (Registry), 22 (DNS Query)

### PowerShell Events
- Location: Windows Event Log
- Event ID: 4104 (Script Block Logging)

### Status File
- Location: `C:\Automation\collection_status.json`
- Contains: Current status, cycle count, activity count

## Monitoring Checks

The monitor script checks:

1. **Collection Process** - Is the Python process running?
2. **Automation Log** - Is the log file being updated?
3. **Activity Logs** - Are activity logs being created?
4. **Sysmon** - Is Sysmon service running?
5. **PowerShell Logging** - Is PowerShell logging enabled?
6. **Disk Space** - Is there enough free space?
7. **Test Files** - Are test files being generated?
8. **Recent Activity** - Has there been activity in the last hour?

## Troubleshooting

### Collection Not Starting

1. Check if Python is installed:
   ```powershell
   python --version
   ```

2. Check if dependencies are installed:
   ```powershell
   python -c "import selenium; import requests; import pandas"
   ```

3. Check if simulator script exists:
   ```powershell
   Test-Path C:\Automation\user_behavior_simulator.py
   ```

### Collection Stopped Unexpectedly

1. Check the automation log:
   ```powershell
   Get-Content C:\Automation\user_behavior.log -Tail 50
   ```

2. Check status file:
   ```powershell
   Get-Content C:\Automation\collection_status.json
   ```

3. Check if process is still running:
   ```powershell
   Get-Content C:\Automation\collection.pid
   Get-Process -Id (Get-Content C:\Automation\collection.pid)
   ```

### Low Activity Count

- Check if activities are being logged
- Verify automation log for errors
- Check if VM/system went to sleep
- Verify activity interval is appropriate

### Sysmon Not Logging

1. Check Sysmon service:
   ```powershell
   Get-Service Sysmon
   ```

2. Restart Sysmon if needed:
   ```powershell
   Restart-Service Sysmon
   ```

## Best Practices

1. **Run in a VM** - Isolate the data collection environment
2. **Monitor Regularly** - Use the monitor script to check status
3. **Export Logs Periodically** - Export Sysmon logs regularly
4. **Keep VM Running** - Don't let the VM sleep or hibernate
5. **Check Disk Space** - Ensure sufficient space for logs
6. **Document Issues** - Note any errors or warnings

## Expected Output

### After Running Collection

- Activity logs: `activity_log_YYYYMMDD_HHMMSS.json`
- Automation log: `user_behavior.log`
- Status file: `collection_status.json`
- PID file: `collection.pid`

### Expected Event Counts (per 24 hours)

- Sysmon Events: 5,000-10,000
- PowerShell Events: 100-500
- Activities: 1,440 (at 60-second interval)

## Next Steps

Once you have sufficient benign data:

1. Export Sysmon logs:
   ```powershell
   wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\Benign_$(Get-Date -Format 'yyyyMMdd').evtx"
   ```

2. Process the data:
   ```bash
   python scripts/process_evtx_files.py --input-dir C:\SysmonLogs --output-dir data/processed/benign --label 0
   ```

3. Then collect malicious data (LOLBin attacks) with label 1












