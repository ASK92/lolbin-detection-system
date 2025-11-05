# 5-Day Continuous Automation Guide

Complete guide for running automation continuously for 5 days to collect immediate dataset.

## Quick Start

### Option 1: Simple PowerShell Script (Easiest)

```powershell
cd C:\Automation
.\run_5days.ps1
```

### Option 2: Direct Command

```powershell
cd C:\Automation
python user_behavior_simulator.py --days 5 --interval 60
```

### Option 3: Batch File

```cmd
cd C:\Automation
run_5days.bat
```

## Configuration for 5 Days

### Recommended Settings

**Duration**: 5 days (120 hours)
```powershell
python user_behavior_simulator.py --days 5 --interval 60
```

**Activity Interval**: 60 seconds (default)
- Lower interval (30-45 seconds) = More activities, higher data volume
- Higher interval (90-120 seconds) = Fewer activities, lower resource usage

**For Maximum Data Collection:**
```powershell
# More frequent activities (30 second intervals)
python user_behavior_simulator.py --days 5 --interval 30

# This will generate approximately 14,400 activities over 5 days
```

## Running as Background Service

### Option 1: Hidden Process

```powershell
Start-Process python.exe -ArgumentList "C:\Automation\user_behavior_simulator.py --days 5 --interval 60" -WindowStyle Hidden
```

### Option 2: Scheduled Task (Best for Long Runs)

```powershell
# Run as Administrator
$Action = New-ScheduledTaskAction `
    -Execute "python.exe" `
    -Argument "C:\Automation\user_behavior_simulator.py --days 5 --interval 60" `
    -WorkingDirectory "C:\Automation"

$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
$Trigger.Repetition = New-ScheduledTaskRepetition -Duration (New-TimeSpan -Days 5) -Interval (New-TimeSpan -Hours 1)

$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName "UserBehaviorSimulation5Days" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "5-day continuous user behavior simulation"

Start-ScheduledTask -TaskName "UserBehaviorSimulation5Days"
```

### Option 3: Windows Service (Most Reliable)

```powershell
# Install NSSM
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "$env:USERPROFILE\Downloads\nssm.zip"
Expand-Archive "$env:USERPROFILE\Downloads\nssm.zip" -DestinationPath "$env:USERPROFILE\Downloads\nssm"

# Install as service
cd "$env:USERPROFILE\Downloads\nssm\nssm-2.24\win64"
.\nssm.exe install UserBehaviorSimulation5Days "python.exe" "C:\Automation\user_behavior_simulator.py --days 5 --interval 60"
.\nssm.exe set UserBehaviorSimulation5Days AppDirectory "C:\Automation"
.\nssm.exe set UserBehaviorSimulation5Days AppStdout "C:\Automation\logs\service_stdout.log"
.\nssm.exe set UserBehaviorSimulation5Days AppStderr "C:\Automation\logs\service_stderr.log"
.\nssm.exe start UserBehaviorSimulation5Days
```

## Monitoring During 5-Day Run

### Check if Running

```powershell
# Check Python process
Get-Process python | Where-Object {$_.CommandLine -like "*user_behavior*"}

# Check scheduled task
Get-ScheduledTaskInfo -TaskName "UserBehaviorSimulation5Days"

# Check service
Get-Service UserBehaviorSimulation5Days
```

### Monitor Logs

```powershell
# View real-time log
Get-Content C:\Automation\user_behavior.log -Tail 50 -Wait

# Check activity count
$log = Get-Content C:\Automation\activity_log_*.json -Raw | ConvertFrom-Json
$log.total_activities

# Check Sysmon events
(Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational").Count
```

### Monitor Resource Usage

```powershell
# Check CPU/Memory
Get-Process python | Select-Object CPU, WorkingSet, @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet/1MB,2)}}

# Check disk space
Get-PSDrive C | Select-Object Used, Free, @{Name="Free(%)";Expression={[math]::Round(($_.Free/($_.Used+$_.Free))*100,2)}}
```

## Expected Data Volume

### After 5 Days (120 hours)

**With 60-second intervals:**
- **Activities**: ~7,200 activities
- **Sysmon Events**: 50,000-100,000 events
- **Test Files**: 200-500 files
- **Activity Log**: ~7,200 entries

**With 30-second intervals:**
- **Activities**: ~14,400 activities
- **Sysmon Events**: 100,000-200,000 events
- **Test Files**: 400-1000 files
- **Activity Log**: ~14,400 entries

## Troubleshooting

### If Process Stops

**Check logs:**
```powershell
Get-Content C:\Automation\user_behavior.log -Tail 100
```

**Restart if needed:**
```powershell
# Restart scheduled task
Restart-ScheduledTask -TaskName "UserBehaviorSimulation5Days"

# Or restart service
Restart-Service UserBehaviorSimulation5Days
```

### If VM Sleeps/Hibernates

**Disable sleep:**
```powershell
# Run as Administrator
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
```

### If Disk Space Low

**Clean up old files:**
```powershell
# Remove old test files (keep last 100)
Get-ChildItem $env:USERPROFILE\Desktop\test_*.txt | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip 100 | 
    Remove-Item -Force

# Archive old logs
Compress-Archive -Path "C:\Automation\activity_log_*.json" -DestinationPath "C:\Automation\archive_$(Get-Date -Format 'yyyyMMdd').zip"
```

### If Chrome Crashes

**Automation will continue** - Selenium errors are caught and the script continues with other activities.

## Best Practices for 5-Day Run

1. **Disable Windows Updates**
   ```powershell
   # Run as Administrator
   Set-Service -Name wuauserv -StartupType Disabled
   ```

2. **Disable Sleep/Hibernate**
   ```powershell
   powercfg /change standby-timeout-ac 0
   ```

3. **Monitor Daily**
   - Check logs once per day
   - Verify Sysmon is logging
   - Check disk space

4. **Export Logs Periodically**
   ```powershell
   # Export Sysmon logs daily
   $date = Get-Date -Format 'yyyyMMdd'
   wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs_$date.evtx"
   ```

5. **Keep VM Running**
   - Don't restart VM
   - Don't close RDP session (or use service mode)
   - Ensure stable network connection

## After 5 Days

### Collect Data

```powershell
# Export final Sysmon log
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs_Final_$(Get-Date -Format 'yyyyMMdd').evtx"

# Export PowerShell logs
wevtutil epl "Microsoft-Windows-PowerShell/Operational" "C:\PowerShellLogs_Final_$(Get-Date -Format 'yyyyMMdd').evtx"

# Archive activity logs
Compress-Archive -Path "C:\Automation\activity_log_*.json" -DestinationPath "C:\Automation\final_archive.zip"
```

### Process Data

```bash
# On your host machine
python scripts/process_evtx_files.py --input-dir <path-to-evtx> --output-dir data/processed/ --label 0
```

## Summary

For immediate 5-day dataset collection:

```powershell
# 1. Setup (one-time)
cd C:\Automation
.\setup_automation.ps1
pip install -r requirements.txt

# 2. Run for 5 days
python user_behavior_simulator.py --days 5 --interval 60

# 3. Monitor (optional)
Get-Content user_behavior.log -Tail 50 -Wait
```

**Command for 5 days:**
```powershell
python user_behavior_simulator.py --days 5 --interval 60
```

This will run continuously for 120 hours (5 days) generating approximately 7,200 activities and 50,000-100,000 Sysmon events.

