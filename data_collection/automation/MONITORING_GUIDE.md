# Automation Monitoring Guide

## Your Script is Running! ✓

If you see Python processes running, your automation is active and collecting data.

## What to Do Now

### ✅ LEAVE IT RUNNING

**Yes, you should leave the script running!** It will continue automatically for the configured duration (5 days if you used `--days 5`).

### What Happens Next

The script will:
- Run continuously for the configured duration (24 hours by default, or 5 days if you used `--days 5`)
- Generate activities automatically every 60 seconds (or your configured interval)
- Save progress every 500 activities
- Log all activities to `user_behavior.log`
- Create activity log files in JSON format

### You Can Safely:

1. **Close the terminal window** - The script will continue running
2. **Disconnect from RDP** - But make sure you run it as a service or scheduled task if you want it to continue after disconnection
3. **Let it run overnight** - It will continue automatically
4. **Check on it periodically** - Use the monitoring commands below

### DON'T:

- Don't restart the VM unless necessary
- Don't stop the Python process manually (unless you want to stop it)
- Don't close the terminal if you want to see live logs (but it's safe to close)

## How to Check Status

### Quick Check (Current Directory)

```powershell
# Check if Python is running
Get-Process python -ErrorAction SilentlyContinue

# Check recent log entries
Get-Content user_behavior.log -Tail 20

# Check activity count (if log exists)
Get-Content activity_log_*.json | ConvertFrom-Json | Select-Object total_activities
```

### Detailed Status Check

```powershell
# Run the status check script
cd C:\Automation
.\CHECK_STATUS.ps1
```

### Monitor in Real-Time

```powershell
# Watch log file in real-time
Get-Content user_behavior.log -Tail 50 -Wait

# Check activity progress
Get-Content activity_log_*.json -Raw | ConvertFrom-Json | 
    Select-Object @{Name="Activities";Expression={$_.total_activities}}, 
                  @{Name="Duration(hours)";Expression={$_.duration_hours}},
                  @{Name="StartTime";Expression={$_.start_time}}
```

## What You Should See

### In the Log File (`user_behavior.log`)

You should see entries like:
```
2025-11-05 18:39:31,123 - INFO - Starting simulation for 120 hours (5.0 days)
2025-11-05 18:39:31,456 - INFO - Activity #1: Browse Web
2025-11-05 18:40:15,789 - INFO - Activity #2: Open Notepad
2025-11-05 18:41:02,345 - INFO - Activity #3: Run PowerShell Command
...
2025-11-05 19:15:30,567 - INFO - Progress: 100 activities completed | Elapsed: 0:36:00 | Remaining: 4 days, 23:24:00
```

### Progress Reports

Every 100 activities, you'll see:
- Total activities completed
- Elapsed time
- Remaining time

Every 500 activities, the script will:
- Save activity log to JSON file
- Log: "Activity log saved to activity_log_YYYYMMDD_HHMMSS.json"

## Expected Timeline

### For 5-Day Run (120 hours):

- **Day 1**: ~1,440 activities
- **Day 2**: ~2,880 activities (cumulative)
- **Day 3**: ~4,320 activities (cumulative)
- **Day 4**: ~5,760 activities (cumulative)
- **Day 5**: ~7,200 activities (total)

### For 24-Hour Run:

- **Hour 1**: ~60 activities
- **Hour 12**: ~720 activities
- **Hour 24**: ~1,440 activities (total)

## Troubleshooting

### If Script Stops

**Check the log:**
```powershell
Get-Content user_behavior.log -Tail 100
```

**Look for errors:**
- "Too many consecutive errors" - Something is blocking activities
- "KeyboardInterrupt" - Script was stopped manually
- "Error executing activity" - Individual activity failed (script continues)

**Restart if needed:**
```powershell
python user_behavior_simulator.py --days 5 --interval 60
```

### If You Want to Stop It

**Press Ctrl+C** in the terminal where it's running, or:
```powershell
# Find and stop the process
Get-Process python | Where-Object {$_.Path -like "*python*"} | Stop-Process
```

### If VM Goes to Sleep

**Disable sleep (run as Administrator):**
```powershell
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
```

## After It Completes

### Collect the Data

```powershell
# Export Sysmon logs
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs_$(Get-Date -Format 'yyyyMMdd').evtx"

# Check activity logs
Get-ChildItem activity_log_*.json

# Review final log
Get-Content user_behavior.log -Tail 50
```

### Process the Data

```bash
# On your host machine
python scripts/process_evtx_files.py --input-dir <path-to-evtx> --output-dir data/processed/ --label 0
```

## Summary

**YES - LEAVE IT RUNNING!**

The script is designed to run continuously for the configured duration. You can:
- Close the terminal (if you want)
- Check on it periodically
- Let it run overnight
- Monitor progress using the commands above

**Just make sure:**
- The VM doesn't go to sleep
- You have enough disk space
- Sysmon is running and logging
- The VM stays powered on

The script will automatically:
- Continue running
- Save progress periodically
- Handle errors gracefully
- Complete when the duration is reached

