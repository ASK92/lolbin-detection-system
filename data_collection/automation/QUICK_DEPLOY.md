# Quick Deployment Guide - Windows 11 VM

Fast setup guide for deploying automation on Windows 11 VM.

## Method 1: Automated Setup (Recommended)

### On Windows 11 VM:

1. **Copy deployment script to VM**
   - Copy `deploy_to_windows11.ps1` to VM
   - Place in a folder (e.g., `C:\Setup\`)

2. **Run deployment script**
   ```powershell
   # Run PowerShell as Administrator
   cd C:\Setup
   .\deploy_to_windows11.ps1
   ```

3. **Copy automation scripts**
   - Copy entire `automation/` folder to `C:\Automation\`

4. **Test automation**
   ```powershell
   cd C:\Automation
   python user_behavior_simulator.py --duration 1 --interval 30
   ```

5. **Start scheduled task**
   ```powershell
   Start-ScheduledTask -TaskName UserBehaviorSimulation
   ```

## Method 2: Manual Setup

### Step 1: Install Prerequisites

```powershell
# Run as Administrator

# Install Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "$env:USERPROFILE\Downloads\Sysmon.zip"
Expand-Archive "$env:USERPROFILE\Downloads\Sysmon.zip" -DestinationPath "$env:USERPROFILE\Downloads\Sysmon"
cd "$env:USERPROFILE\Downloads\Sysmon"
.\Sysmon.exe -i -accepteula

# Download and apply config
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "sysmonconfig.xml"
.\Sysmon.exe -c sysmonconfig.xml

# Install Python
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe" -OutFile "$env:USERPROFILE\Downloads\python.exe"
Start-Process "$env:USERPROFILE\Downloads\python.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

# Install Chrome
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$env:USERPROFILE\Downloads\chrome.exe"
Start-Process "$env:USERPROFILE\Downloads\chrome.exe" -ArgumentList "/silent /install" -Wait
```

### Step 2: Copy Automation Scripts

Copy `data_collection/automation/` folder to `C:\Automation\` on VM

### Step 3: Setup Environment

```powershell
cd C:\Automation

# Install dependencies
pip install -r requirements.txt

# Set execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 4: Run Automation

```powershell
# Test run (1 hour)
python user_behavior_simulator.py --duration 1 --interval 30

# Full run (24 hours)
python user_behavior_simulator.py --duration 24 --interval 60
```

## Method 3: One-Line Setup (PowerShell)

If you have all files in `C:\Automation\`:

```powershell
# Run as Administrator
cd C:\Automation; .\setup_automation.ps1; pip install -r requirements.txt; python user_behavior_simulator.py --duration 24 --interval 60
```

## Verification

### Check if Running

```powershell
# Check Python process
Get-Process python

# Check Sysmon
Get-Service Sysmon*

# Check events
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

### View Logs

```powershell
# Automation log
Get-Content C:\Automation\user_behavior.log -Tail 20

# Activity log
Get-ChildItem C:\Automation\activity_log_*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

## Troubleshooting

### "Python not found"
- Restart PowerShell after installing Python
- Or manually add Python to PATH

### "Module not found"
```powershell
pip install -r C:\Automation\requirements.txt
```

### "ChromeDriver error"
```powershell
pip install --upgrade webdriver-manager
```

### "Execution policy error"
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Next Steps

After automation is running:

1. Monitor for 24-48 hours
2. Export Sysmon logs
3. Process logs with your scripts
4. Train models

For detailed instructions, see `WINDOWS11_DEPLOYMENT.md`


