# Fix: Missing Calculator and Chrome

## Issues Fixed

The automation script has been updated to handle missing applications gracefully:

### 1. Calculator (calc.exe)

**Problem**: `calc.exe` may not be available in all Windows installations.

**Solution**: The script now:
- Checks multiple Calculator locations:
  - `calc.exe` (in PATH)
  - `C:\Windows\System32\calc.exe`
  - `C:\Windows\System32\CalculatorApp.exe` (Windows 10/11 modern Calculator)
- Falls back to PowerShell: `Start-Process Calculator`
- Gracefully skips if Calculator is not available

### 2. Chrome Browser

**Problem**: Chrome may not be installed on the VM.

**Solution**: The script now:
- Checks if Chrome is installed before attempting to use Selenium
- Checks multiple Chrome installation paths:
  - `C:\Program Files\Google\Chrome\Application\chrome.exe`
  - `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`
  - `%USERPROFILE%\AppData\Local\Google\Chrome\Application\chrome.exe`
- Falls back to default browser (Edge) using PowerShell:
  - `Start-Process "https://www.google.com"`
- Continues working even without Chrome

## How It Works Now

### Calculator

The script will:
1. Try to find Calculator in common locations
2. If found, open it normally
3. If not found, use PowerShell to launch Calculator app
4. If that fails, skip Calculator and continue

### Browser

The script will:
1. Check if Chrome is installed
2. If Chrome exists and Selenium is available:
   - Use Selenium with Chrome for automated browsing
3. If Chrome doesn't exist or Selenium fails:
   - Use PowerShell to open default browser (usually Edge)
   - Open websites in the default browser
   - Continue with other activities

## No Action Required

The script now handles these issues automatically. You don't need to:
- Install Chrome (optional - script will use default browser)
- Enable Calculator (script will find it or use PowerShell)
- Make any changes to your VM

## Optional: Install Chrome (If You Want Selenium Automation)

If you want automated browser interactions with Selenium, you can install Chrome:

```powershell
# Download and install Chrome
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$env:USERPROFILE\Downloads\chrome-installer.exe"
Start-Process "$env:USERPROFILE\Downloads\chrome-installer.exe" -ArgumentList "/silent /install" -Wait

# Verify installation
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

## Optional: Enable Calculator (If Missing)

If Calculator is not available, you can enable it:

```powershell
# Reinstall Calculator app (Windows 10/11)
Get-AppxPackage *calculator* | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}

# Or use legacy Calculator
# Calculator should be available at C:\Windows\System32\calc.exe
```

## Verification

The script will now:
- Continue running even if Calculator or Chrome are missing
- Log warnings/debug messages when falling back to alternatives
- Generate activities using available applications
- Not crash or stop due to missing applications

## Summary

**You don't need to do anything!** The script has been updated to:
- Handle missing Calculator gracefully
- Handle missing Chrome gracefully
- Use alternatives automatically
- Continue running without errors

Your automation should continue working normally even without these applications.

