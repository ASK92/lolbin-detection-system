# Fix: Selenium Installation Issue

## Problem

`selenium==4.15.2` may not be available for your Python version, causing installation errors.

## Solution

### Option 1: Use Latest Compatible Version (Recommended)

```powershell
# Install latest compatible version
pip install selenium webdriver-manager --upgrade
```

### Option 2: Install Without Version Constraints

```powershell
# Install from requirements.txt with updated versions
pip install -r requirements.txt --upgrade
```

### Option 3: Manual Installation

```powershell
# Install selenium and dependencies
pip install selenium
pip install webdriver-manager
pip install pyautogui
pip install requests
pip install beautifulsoup4
pip install schedule
pip install faker
```

### Option 4: Use Python 3.10 or 3.11

If you're using an older Python version, selenium 4.15.2 requires Python 3.8+. 

Check your Python version:
```powershell
python --version
```

If Python < 3.8, upgrade Python:
```powershell
# Download and install Python 3.11
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe" -OutFile "$env:USERPROFILE\Downloads\python.exe"
Start-Process "$env:USERPROFILE\Downloads\python.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
```

## Updated Requirements

The requirements.txt has been updated to use flexible version constraints:

```
selenium>=4.0.0
webdriver-manager>=4.0.0
```

This will install the latest compatible version for your Python version.

## Verify Installation

After installing:

```powershell
python -c "import selenium; print(selenium.__version__)"
python -c "from selenium import webdriver; print('Selenium installed successfully')"
```

## Alternative: Skip Selenium (Browser Automation Optional)

If you don't need web browsing automation, you can skip selenium:

```powershell
# Install without selenium
pip install pyautogui python-dotenv psutil requests beautifulsoup4 schedule faker
```

The automation will still work, but web browsing features will be disabled.
python -c "import selenium;"
