# Antivirus Blocking Scripts - Fix Guide

## Issue
Your antivirus software is blocking the attack generation scripts because they contain malicious patterns (which is expected - they're designed to generate attack data).

## Solution

### Option 1: Add Exclusion (Recommended for Test VM)

1. **Windows Defender:**
   ```powershell
   # Run as Administrator
   Add-MpPreference -ExclusionPath "C:\Users\adity\lolbin-detection-system\data_collection\automation"
   ```

2. **Or via GUI:**
   - Open Windows Security
   - Go to Virus & threat protection
   - Click "Manage settings" under Virus & threat protection settings
   - Scroll to Exclusions
   - Click "Add or remove exclusions"
   - Add folder: `C:\Users\adity\lolbin-detection-system\data_collection\automation`

### Option 2: Temporarily Disable Real-time Protection (Test VM Only!)

```powershell
# Run as Administrator
Set-MpPreference -DisableRealtimeMonitoring $true
```

**⚠️ WARNING: Only do this on an isolated test VM!**

### Option 3: Use Alternative Approach

The attacks will still generate Sysmon events even if they fail. The important thing is that the processes are created (Event ID 1), which is what we need for training data.

## Important Note

**The attacks don't need to succeed!** Even failed commands generate Sysmon Event ID 1 (Process Creation) events, which is exactly what we need for ML training. The command failures are expected and normal - what matters is that Sysmon logs the process creation attempts.

## Verify It's Working

Even with antivirus blocking, check if Sysmon is logging:

```powershell
# Check recent Sysmon events
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10 | Format-List TimeCreated, Id, Message
```

If you see Event ID 1 events being created, the attacks are working for data collection purposes!









