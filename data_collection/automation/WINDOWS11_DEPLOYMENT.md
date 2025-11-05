# Windows 11 VM Automation Deployment Guide

Complete guide for deploying user behavior automation on a Windows 11 VM.

## Prerequisites

- Windows 11 VM (local or Azure)
- Administrator access
- Internet connection for downloads
- At least 2GB free disk space

## Step 1: Prepare Windows 11 VM

### Initial Setup

1. **Complete Windows 11 Setup**
   - Finish initial Windows configuration
   - Create administrator account
   - Enable Remote Desktop (if needed)

2. **Install Windows Updates**
   ```powershell
   # Run as Administrator
   Get-WindowsUpdate
   Install-WindowsUpdate -AcceptAll -AutoReboot
   ```

3. **Disable Windows Defender (Optional - for testing only)**
   ```powershell
   # Run as Administrator
   Set-MpPreference -DisableRealtimeMonitoring $true
   ```
   **Note**: Only disable for isolated test VMs. Keep enabled for production.

## Step 2: Install Sysmon

### Download and Install

1. **Download Sysmon**
   ```powershell
   # Run PowerShell as Administrator
   Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "$env:USERPROFILE\Downloads\Sysmon.zip"
   Expand-Archive "$env:USERPROFILE\Downloads\Sysmon.zip" -DestinationPath "$env:USERPROFILE\Downloads\Sysmon"
   ```

2. **Download Sysmon Configuration**
   ```powershell
   cd "$env:USERPROFILE\Downloads\Sysmon"
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "sysmonconfig.xml"
   ```

3. **Install Sysmon**
   ```powershell
   .\Sysmon.exe -i -accepteula
   ```

4. **Apply Configuration**
   ```powershell
   .\Sysmon.exe -c sysmonconfig.xml
   ```

5. **Verify Installation**
   ```powershell
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
   ```

### Configure Sysmon Event IDs

Ensure these Event IDs are logged:
- Event ID 1: Process creation
- Event ID 7: Image loaded
- Event ID 10: Process access
- Event ID 11: File creation
- Event ID 13: Registry value set
- Event ID 22: DNS query

## Step 3: Enable PowerShell Script Block Logging

```powershell
# Run as Administrator
# Enable Script Block Logging
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1

# Enable Module Logging
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1

# Verify
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
```

## Step 4: Install Prerequisites

### Install Python 3.11

1. **Download Python**
   ```powershell
   Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe" -OutFile "$env:USERPROFILE\Downloads\python-installer.exe"
   ```

2. **Install Python**
   ```powershell
   # Silent install with PATH
   Start-Process "$env:USERPROFILE\Downloads\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
   ```

3. **Verify Installation**
   ```powershell
   # Close and reopen PowerShell, then:
   python --version
   pip --version
   ```

### Install Google Chrome

```powershell
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$env:USERPROFILE\Downloads\chrome-installer.exe"
Start-Process "$env:USERPROFILE\Downloads\chrome-installer.exe" -ArgumentList "/silent /install" -Wait
```

### Install Git (Optional - for cloning repository)

```powershell
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe" -OutFile "$env:USERPROFILE\Downloads\git-installer.exe"
Start-Process "$env:USERPROFILE\Downloads\git-installer.exe" -ArgumentList "/SILENT" -Wait
```

## Step 5: Copy Automation Scripts to VM

### Option A: Using RDP Clipboard

1. **On your local machine:**
   - Zip the `data_collection/automation/` folder
   - Copy the zip file

2. **On Windows 11 VM:**
   - Paste in Downloads folder
   - Extract to `C:\Automation\`

### Option B: Using Shared Folder (VMware/VirtualBox)

1. **Enable Shared Folder** in VM settings
2. **Copy automation folder** to shared location
3. **On VM:** Copy from shared folder to `C:\Automation\`

### Option C: Using Git Clone

```powershell
# On Windows 11 VM
cd C:\
git clone https://github.com/ASK92/lolbin-detection-system.git Automation
cd Automation\data_collection\automation
```

### Option D: Using USB/Network Drive

1. Copy automation folder to USB drive
2. Insert USB in VM
3. Copy to `C:\Automation\`

### Option E: Using Azure Portal (if Azure VM)

1. **Upload files via Azure Portal**
   - Go to VM > Files
   - Upload zip file
   - Extract on VM

2. **Or use Azure File Share**
   - Create Storage Account
   - Create File Share
   - Mount on VM
   - Copy files

## Step 6: Setup Automation Environment

### Run Setup Script

```powershell
# Navigate to automation directory
cd C:\Automation

# Run setup script (if available)
.\setup_automation.ps1

# Or manually install dependencies
pip install -r requirements.txt
```

### Configure PowerShell Execution Policy

```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Verify Setup

```powershell
# Check Python
python --version

# Check packages
pip list | Select-String "selenium|requests|pandas"

# Check Chrome
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

## Step 7: Run Automation

### Option 1: Run Directly (Interactive)

```powershell
cd C:\Automation

# Run for 24 hours
python user_behavior_simulator.py --duration 24 --interval 60

# Run for 5 days (120 hours) - RECOMMENDED for immediate dataset
python user_behavior_simulator.py --days 5 --interval 60

# Or use the convenience script
.\run_5days.ps1
```

**To run in background for 5 days:**
```powershell
Start-Process python.exe -ArgumentList "C:\Automation\user_behavior_simulator.py --days 5 --interval 60" -WindowStyle Hidden
```

### Option 2: Create Scheduled Task (Recommended)

```powershell
# Run as Administrator
# For 5-day continuous run:
$Action = New-ScheduledTaskAction `
    -Execute "python.exe" `
    -Argument "C:\Automation\user_behavior_simulator.py --days 5 --interval 60" `
    -WorkingDirectory "C:\Automation"

# For 24-hour run:
# $Action = New-ScheduledTaskAction `
#     -Execute "python.exe" `
#     -Argument "C:\Automation\user_behavior_simulator.py --duration 24 --interval 60" `
#     -WorkingDirectory "C:\Automation"

$Trigger = New-ScheduledTaskTrigger -Daily -At 9AM
$Trigger.Repetition = New-ScheduledTaskRepetition -Interval (New-TimeSpan -Hours 1) -Duration (New-TimeSpan -Days 7)

$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "UserBehaviorSimulation" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Automated user behavior simulation for data collection"

# Start task immediately
Start-ScheduledTask -TaskName "UserBehaviorSimulation"
```

### Option 3: Use PowerShell Script

```powershell
cd C:\Automation
.\powershell_automation.ps1 -DurationHours 24 -ActivityInterval 60
```

### Option 4: Run as Windows Service (Advanced)

```powershell
# Install NSSM (Non-Sucking Service Manager)
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "$env:USERPROFILE\Downloads\nssm.zip"
Expand-Archive "$env:USERPROFILE\Downloads\nssm.zip" -DestinationPath "$env:USERPROFILE\Downloads\nssm"

# Install as service
cd "$env:USERPROFILE\Downloads\nssm\nssm-2.24\win64"
.\nssm.exe install UserBehaviorSimulation "C:\Python311\python.exe" "C:\Automation\user_behavior_simulator.py --duration 168 --interval 60"
.\nssm.exe start UserBehaviorSimulation
```

## Step 8: Monitor Automation

### Check if Running

```powershell
# Check Python processes
Get-Process python | Where-Object {$_.Path -like "*Automation*"}

# Check scheduled task
Get-ScheduledTask -TaskName "UserBehaviorSimulation"

# View task status
Get-ScheduledTaskInfo -TaskName "UserBehaviorSimulation"
```

### View Logs

```powershell
# View automation log
Get-Content C:\Automation\user_behavior.log -Tail 50 -Wait

# View activity log
Get-ChildItem C:\Automation\activity_log_*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Monitor Sysmon Events

```powershell
# View recent Sysmon events
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 50 | Format-Table -AutoSize

# Count events
(Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational").Count

# Monitor in real-time
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -Wait | ForEach-Object { Write-Host "$($_.TimeCreated) - Event ID: $($_.Id)" }
```

## Step 9: Collect Event Logs

### Option 1: Export EVTX Files

```powershell
# Export Sysmon log
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs_$(Get-Date -Format 'yyyyMMdd').evtx"

# Export PowerShell script block log
wevtutil epl "Microsoft-Windows-PowerShell/Operational" "C:\PowerShellLogs_$(Get-Date -Format 'yyyyMMdd').evtx"
```

### Option 2: Use Event Collector

On your host machine, configure the event collector to connect to the VM:

```powershell
# On VM: Enable remote event logging
winrm quickconfig -force

# On host: Use windows_event_collector.py
python collectors/windows_event_collector.py --mode realtime --backend-url http://your-backend-url:8000
```

### Option 3: Manual Collection

1. **Open Event Viewer**
   - Run `eventvwr.msc`
   - Navigate to: Applications and Services Logs > Microsoft > Windows > Sysmon > Operational

2. **Export Logs**
   - Right-click "Operational"
   - Select "Save All Events As..."
   - Save as EVTX file

## Step 10: Verify Data Collection

### Check Generated Files

```powershell
# Check test files created
Get-ChildItem $env:USERPROFILE\Desktop\test_*.txt
Get-ChildItem $env:USERPROFILE\Documents\automation_docs

# Check activity logs
Get-ChildItem C:\Automation\activity_log_*.json
```

### Verify Event Count

```powershell
# Count Sysmon events
$eventCount = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational").Count
Write-Host "Total Sysmon events: $eventCount"

# Check event types
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | 
    Group-Object Id | 
    Select-Object Count, Name | 
    Sort-Object Count -Descending
```

### Expected Volume

After 24 hours of automation:
- **Sysmon events**: 30,000-50,000 events
- **Test files**: 50-100 files
- **Activity log entries**: 500-1000 entries

## Troubleshooting

### Automation Not Starting

**Check Python:**
```powershell
python --version
where.exe python
```

**Check Dependencies:**
```powershell
pip list
pip install -r C:\Automation\requirements.txt
```

**Check Execution Policy:**
```powershell
Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Selenium/Chrome Issues

**Update ChromeDriver:**
```powershell
pip install --upgrade webdriver-manager
```

**Check Chrome:**
```powershell
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

**Manual ChromeDriver:**
```powershell
Invoke-WebRequest -Uri "https://chromedriver.storage.googleapis.com/LATEST_RELEASE" -OutFile "version.txt"
$version = Get-Content "version.txt"
Invoke-WebRequest -Uri "https://chromedriver.storage.googleapis.com/$version/chromedriver_win32.zip" -OutFile "chromedriver.zip"
Expand-Archive chromedriver.zip -DestinationPath C:\Automation
```

### Sysmon Not Logging

**Check Service:**
```powershell
Get-Service Sysmon*
```

**Restart Sysmon:**
```powershell
Restart-Service Sysmon*
```

**Check Event Log:**
```powershell
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1
```

**Reinstall if needed:**
```powershell
cd C:\Sysmon
.\Sysmon.exe -u
.\Sysmon.exe -i -accepteula
```

### Low Event Volume

**Increase Activity Frequency:**
```powershell
# Reduce interval (more frequent activities)
python user_behavior_simulator.py --duration 24 --interval 30
```

**Run Multiple Instances:**
```powershell
# Run browser simulator separately
Start-Process python.exe -ArgumentList "C:\Automation\selenium_browser_simulator.py --duration 60" -WindowStyle Hidden

# Run main simulator
python user_behavior_simulator.py --duration 24 --interval 60
```

## Best Practices

### 1. Run During Business Hours

Simulate realistic usage patterns:
- **Weekdays**: 9 AM - 5 PM (high activity)
- **Weekends**: 10 AM - 2 PM (light activity)
- **Nights**: No automation (VM can sleep)

### 2. Vary Activity Patterns

```powershell
# Create different activity profiles
# Profile 1: Heavy browsing
python user_behavior_simulator.py --duration 8 --interval 30

# Profile 2: Office work
python office_automation.py

# Profile 3: System administration
# Use PowerShell automation script
```

### 3. Monitor Resource Usage

```powershell
# Check CPU/Memory
Get-Process python | Select-Object CPU, WorkingSet

# Check disk space
Get-PSDrive C | Select-Object Used, Free
```

### 4. Regular Maintenance

```powershell
# Clean up test files weekly
Get-ChildItem $env:USERPROFILE\Desktop\test_*.txt | Remove-Item -Force

# Archive old logs
Compress-Archive -Path "C:\Automation\activity_log_*.json" -DestinationPath "C:\Automation\archive_$(Get-Date -Format 'yyyyMM').zip"
```

## Quick Start Checklist

- [ ] Windows 11 VM ready
- [ ] Sysmon installed and configured
- [ ] PowerShell script block logging enabled
- [ ] Python 3.11 installed
- [ ] Chrome browser installed
- [ ] Automation scripts copied to `C:\Automation\`
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Execution policy set (RemoteSigned)
- [ ] Automation running (scheduled task or manual)
- [ ] Monitoring logs and events
- [ ] Collecting data periodically

## Next Steps

After collecting data:

1. **Export Event Logs** (Step 9)
2. **Process Logs** using `scripts/process_evtx_files.py`
3. **Label Data** (benign = 0)
4. **Train Models** using processed data
5. **Test System** with trained models

## Support

For issues:
- Check logs: `C:\Automation\user_behavior.log`
- Check Sysmon: Event Viewer > Sysmon > Operational
- Review this guide's troubleshooting section

