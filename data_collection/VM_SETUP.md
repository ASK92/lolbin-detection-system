# Windows VM Setup Guide for Data Collection

This guide walks you through setting up a Windows VM for automated user behavior data collection.

## Prerequisites

- Virtualization software (VMware, VirtualBox, Hyper-V, or Azure)
- Windows 10/11 ISO or Azure subscription
- At least 4GB RAM allocated to VM
- 50GB+ disk space

## Quick Links

- **Windows 11 Deployment**: See `automation/WINDOWS11_DEPLOYMENT.md` for complete Windows 11 setup
- **Quick Deployment**: See `automation/QUICK_DEPLOY.md` for fast setup
- **Automated Setup**: Use `automation/deploy_to_windows11.ps1` script

## Step 1: Create Windows VM

### Option A: Local VM (VMware/VirtualBox)

1. **Create New VM**
   - Allocate: 4GB RAM, 50GB disk
   - Network: NAT or Bridged
   - Enable virtualization features

2. **Install Windows**
   - Install Windows 10/11
   - Use evaluation license or valid license
   - Set up local user account

3. **Install Guest Additions/Tools**
   - VMware Tools or VirtualBox Guest Additions
   - Enables better integration

### Option B: Azure VM (Student Account Compatible)

**Yes, Azure student accounts work!** You get $100 credit for 12 months.

See **`AZURE_STUDENT_SETUP.md`** for detailed Azure student account setup instructions.

Quick start:
```bash
# Login to Azure
az login

# Create resource group
az group create --name lolbin-vm-rg --location eastus

# Create VM (B2s size recommended - ~$30/month)
az vm create \
  --resource-group lolbin-vm-rg \
  --name lolbin-windows-vm \
  --image Win2022Datacenter \
  --size Standard_B2s \
  --admin-username azureuser \
  --admin-password YourPassword123! \
  --public-ip-sku Standard \
  --nsg-rule RDP

# Get public IP
az vm show -d -g lolbin-vm-rg -n lolbin-windows-vm --query publicIps -o tsv
```

**Cost Notes:**
- B2s VM: ~$0.04/hour (~$30/month if 24/7)
- With $100 credit: Can run for 2-3 months
- **Tip**: Stop VM when not in use to save credits
- Use auto-shutdown feature to stop VM at night

**Full guide**: See `AZURE_STUDENT_SETUP.md` for complete instructions.

## Step 2: Install Sysmon

1. **Download Sysmon**
   ```powershell
   # Download Sysmon
   Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "Sysmon.zip"
   Expand-Archive Sysmon.zip
   ```

2. **Download Sysmon Configuration**
   ```powershell
   # Download SwiftOnSecurity config
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "sysmonconfig.xml"
   ```

3. **Install Sysmon**
   ```powershell
   cd Sysmon
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

## Step 3: Enable PowerShell Script Block Logging

1. **Via Group Policy** (if available):
   - Open Group Policy Editor (gpedit.msc)
   - Navigate to: Computer Configuration > Administrative Templates > Windows Components > Windows PowerShell
   - Enable "Turn on PowerShell Script Block Logging"
   - Enable "Turn on Module Logging"

2. **Via Registry**:
   ```powershell
   # Enable Script Block Logging
   New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force
   Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1
   
   # Enable Module Logging
   New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force
   Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1
   ```

## Step 4: Install Automation Tools

1. **Install Python**
   ```powershell
   # Download Python installer
   Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe" -OutFile "python-installer.exe"
   
   # Install Python
   .\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
   ```

2. **Install Chrome Browser**
   ```powershell
   Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "chrome-installer.exe"
   .\chrome-installer.exe /silent /install
   ```

3. **Install Automation Scripts**
   ```powershell
   # Copy automation scripts to VM
   # Use RDP, SCP, or shared folder
   ```

## Step 5: Configure Automation

1. **Copy Automation Scripts**
   - Copy `data_collection/automation/` directory to VM
   - Place in `C:\Automation\` or similar

2. **Install Python Dependencies**
   ```powershell
   cd C:\Automation
   pip install -r requirements.txt
   ```

3. **Configure PowerShell Execution Policy**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Step 6: Run Automation

### Option 1: Scheduled Task (Recommended)

1. **Create Scheduled Task**
   ```powershell
   $Action = New-ScheduledTaskAction -Execute "python.exe" -Argument "C:\Automation\user_behavior_simulator.py --duration 24 --interval 60" -WorkingDirectory "C:\Automation"
   $Trigger = New-ScheduledTaskTrigger -Daily -At 9AM
   $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
   Register-ScheduledTask -TaskName "UserBehaviorSimulation" -Action $Action -Trigger $Trigger -Principal $Principal
   ```

2. **Start Task**
   ```powershell
   Start-ScheduledTask -TaskName "UserBehaviorSimulation"
   ```

### Option 2: Manual Run

```powershell
cd C:\Automation
python user_behavior_simulator.py --duration 24 --interval 60
```

### Option 3: Background Service

```powershell
# Run as background job
Start-Process python.exe -ArgumentList "C:\Automation\user_behavior_simulator.py --duration 48 --interval 60" -WindowStyle Hidden
```

## Step 7: Monitor and Collect Data

1. **Monitor Sysmon Logs**
   ```powershell
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100 | Format-Table -AutoSize
   ```

2. **Check Automation Logs**
   ```powershell
   Get-Content C:\Automation\user_behavior.log -Tail 50
   ```

3. **Collect Event Logs**
   - Use event collector on host machine
   - Or export EVTX files manually

## Step 8: Verify Data Collection

1. **Check Event Count**
   ```powershell
   (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational").Count
   ```

2. **Verify Event Types**
   ```powershell
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | 
     Group-Object Id | 
     Select-Object Count, Name | 
     Sort-Object Count -Descending
   ```

3. **Check File Operations**
   ```powershell
   Get-ChildItem $env:USERPROFILE\Desktop\test_*.txt
   ```

## Troubleshooting

### Sysmon Not Logging

1. Check Sysmon service:
   ```powershell
   Get-Service Sysmon
   ```

2. Check event log:
   ```powershell
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1
   ```

3. Reinstall Sysmon if needed

### Automation Not Running

1. Check Python installation:
   ```powershell
   python --version
   ```

2. Check dependencies:
   ```powershell
   pip list
   ```

3. Check execution policy:
   ```powershell
   Get-ExecutionPolicy
   ```

### Low Event Volume

1. Increase activity frequency (reduce interval)
2. Run multiple automation instances
3. Add more activity types
4. Run for longer duration

## Security Considerations

1. **Isolate VM**: Keep VM isolated from production networks
2. **No Sensitive Data**: Don't use real credentials or sensitive data
3. **Snapshot Before**: Take VM snapshot before running automation
4. **Monitor Resources**: Watch CPU/memory usage
5. **Clean Up**: Remove test files after data collection

## Next Steps

After collecting data:

1. Export Sysmon logs to EVTX files
2. Process logs using `scripts/process_evtx_files.py`
3. Label events as benign (label=0)
4. Combine with malicious samples
5. Train ML models

## Automation Schedule Example

For a week-long collection:

```powershell
# Monday-Friday: 9AM-5PM (business hours)
# Weekend: 10AM-2PM (light activity)
# Total: ~40 hours of active collection
```

Adjust activity intervals:
- Business hours: 30-60 seconds
- Off hours: 120-300 seconds
- Night: No automation (VM can sleep)

