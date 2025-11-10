# Update Script on Windows VM

If you're getting syntax errors when running `verify_dataset.ps1`, you need to pull the latest version from GitHub.

## Quick Update

On your Windows VM, run these commands:

```powershell
# Navigate to your repository
cd C:\Users\adity\lolbin-detection-system

# Pull latest changes from GitHub
git pull origin main

# Navigate to automation directory
cd data_collection\automation

# Run the updated script
.\verify_dataset.ps1
```

## Alternative: Manual Update

If git pull doesn't work, you can manually replace the script:

1. **Download the fixed script from GitHub:**
   - Go to: https://github.com/ASK92/lolbin-detection-system/blob/main/data_collection/automation/verify_dataset.ps1
   - Click "Raw" button
   - Copy all content

2. **Replace the file on your VM:**
   ```powershell
   # Backup old version (optional)
   Copy-Item C:\Users\adity\lolbin-detection-system\data_collection\automation\verify_dataset.ps1 C:\Users\adity\lolbin-detection-system\data_collection\automation\verify_dataset.ps1.backup
   
   # Open the file in notepad and paste the new content
   notepad C:\Users\adity\lolbin-detection-system\data_collection\automation\verify_dataset.ps1
   ```

## Verify the Update

After updating, check that the script has no syntax errors:

```powershell
# Check PowerShell syntax
powershell -Command "& { $ErrorActionPreference = 'Stop'; . 'C:\Users\adity\lolbin-detection-system\data_collection\automation\verify_dataset.ps1' -WhatIf }"
```

Or simply try running it:

```powershell
cd C:\Users\adity\lolbin-detection-system\data_collection\automation
.\verify_dataset.ps1
```

## If Git Pull Fails

If you get errors during `git pull`, try:

```powershell
# Check git status
git status

# If there are local changes, stash them
git stash

# Pull again
git pull origin main

# If you stashed, restore your changes
git stash pop
```

Or reset to match remote:

```powershell
# WARNING: This will discard local changes
git fetch origin
git reset --hard origin/main
```

