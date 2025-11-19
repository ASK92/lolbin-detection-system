# Quick Fix Guide - Antivirus & Access Denied Issues

## 🚨 Immediate Fix (Run as Administrator)

### Step 1: Open PowerShell as Administrator
1. Press `Windows + X`
2. Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
3. Navigate to the automation directory:
   ```powershell
   cd C:\Users\adity\lolbin-detection-system\data_collection\automation
   ```

### Step 2: Run the Fix Script
```powershell
.\fix_all_issues.ps1
```

This will:
- ✅ Add antivirus exclusion for the automation folder
- ✅ Fix file permissions
- ✅ Fix PowerShell execution policy

## 🔧 Manual Fixes (If Script Doesn't Work)

### Fix 1: Antivirus Exclusion (Windows Defender)

**Option A: PowerShell (Run as Admin)**
```powershell
Add-MpPreference -ExclusionPath "C:\Users\adity\lolbin-detection-system\data_collection\automation"
Add-MpPreference -ExclusionProcess "powershell.exe"
```

**Option B: GUI Method**
1. Open **Windows Security** (search in Start menu)
2. Go to **Virus & threat protection**
3. Click **Manage settings** under Virus & threat protection settings
4. Scroll down to **Exclusions**
5. Click **Add or remove exclusions**
6. Click **Add an exclusion** → **Folder**
7. Browse to: `C:\Users\adity\lolbin-detection-system\data_collection\automation`
8. Click **Select Folder**

### Fix 2: Temporarily Disable Real-time Protection (Test VM Only!)

⚠️ **WARNING: Only do this on an isolated test VM!**

```powershell
# Run as Administrator
Set-MpPreference -DisableRealtimeMonitoring $true
```

To re-enable later:
```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
```

### Fix 3: Fix Access Denied Errors

**Run PowerShell as Administrator:**
```powershell
# Fix permissions for automation folder
$path = "C:\Users\adity\lolbin-detection-system\data_collection\automation"
$acl = Get-Acl $path
$permission = "$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl -Path $path -AclObject $acl

# Fix permissions for Sysmon logs
$sysmonPath = "C:\SysmonLogs"
if (-not (Test-Path $sysmonPath)) {
    New-Item -ItemType Directory -Path $sysmonPath -Force
}
$acl = Get-Acl $sysmonPath
$acl.SetAccessRule($accessRule)
Set-Acl -Path $sysmonPath -AclObject $acl
```

### Fix 4: PowerShell Execution Policy

```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## ✅ Verify Fixes

After running fixes, test:

```powershell
# Test 1: Check if script is accessible
Test-Path "C:\Users\adity\lolbin-detection-system\data_collection\automation\generate_malicious_lolbin_attacks.ps1"

# Test 2: Check antivirus exclusions
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath

# Test 3: Try running a simple attack
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 5 -SkipConfirmation
```

## 🎯 Quick One-Liner Fix (Copy-Paste)

Run this in PowerShell as Administrator:

```powershell
cd C:\Users\adity\lolbin-detection-system\data_collection\automation; Add-MpPreference -ExclusionPath $PWD; Add-MpPreference -ExclusionProcess "powershell.exe"; $acl = Get-Acl $PWD; $permission = "$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"; $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission; $acl.SetAccessRule($accessRule); Set-Acl -Path $PWD -AclObject $acl; Write-Host "Fixed! Try running the attack script now." -ForegroundColor Green
```

## 📋 Checklist

- [ ] Opened PowerShell as Administrator
- [ ] Ran `.\fix_all_issues.ps1` OR manually added exclusions
- [ ] Verified script file is accessible
- [ ] Tried running attack script again
- [ ] If still blocked, temporarily disabled real-time protection (test VM only!)

## 🆘 Still Having Issues?

1. **Check if Windows Defender is the issue:**
   ```powershell
   Get-MpComputerStatus
   ```

2. **Check if another antivirus is installed:**
   - Check installed programs
   - May need to add exclusions there too

3. **Check file permissions:**
   ```powershell
   icacls "C:\Users\adity\lolbin-detection-system\data_collection\automation"
   ```

4. **Check if Sysmon is running:**
   ```powershell
   Get-Service Sysmon
   ```

## 💡 Alternative: Use Advanced Script Only

If the standard script keeps getting blocked, you can use just the advanced script:

```powershell
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 1000 -IncludeObfuscation -IncludePolymorphic
```

This will generate plenty of attack data even without the standard script!







