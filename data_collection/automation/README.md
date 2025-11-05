# User Behavior Automation for Data Collection

This directory contains scripts to automate realistic Windows user behavior for generating benign training data.

## Setup

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Install ChromeDriver (for Selenium)

ChromeDriver will be automatically installed when running the scripts. Alternatively:

```bash
pip install webdriver-manager
```

## Usage

### Option 1: Python Automation (Recommended)

```bash
# Run for 24 hours with 60-second intervals
python user_behavior_simulator.py --duration 24 --interval 60

# Run for 8 hours with 30-second intervals
python user_behavior_simulator.py --duration 8 --interval 30
```

### Option 2: PowerShell Automation

```powershell
# Run for 24 hours
.\powershell_automation.ps1 -DurationHours 24 -ActivityInterval 60

# Run for 8 hours
.\powershell_automation.ps1 -DurationHours 8 -ActivityInterval 30
```

### Option 3: Batch Script

```cmd
run_automation.bat
```

### Option 4: Web Browser Only

```bash
# Simulate web browsing for 30 minutes
python selenium_browser_simulator.py --duration 30
```

### Option 5: Office Applications Only

```bash
python office_automation.py
```

## Activities Simulated

The automation simulates the following realistic user activities:

1. **Web Browsing** (25% weight)
   - Visits common websites (Google, GitHub, Stack Overflow, etc.)
   - Performs searches
   - Clicks links
   - Scrolls pages

2. **File Operations** (20% weight)
   - Creates test files
   - Copies files
   - Lists directories
   - Reads files

3. **Office Applications** (15% weight)
   - Opens Notepad, Calculator, Paint
   - Creates Word documents
   - Creates Excel spreadsheets
   - Reads existing documents

4. **System Commands** (15% weight)
   - dir, tasklist, systeminfo
   - ipconfig, netstat, whoami
   - PowerShell commands

5. **PowerShell Activity** (10% weight)
   - Get-Process, Get-Service
   - Get-ChildItem, Get-Date
   - System information queries

6. **Background Tasks** (5% weight)
   - Update checks
   - File syncing
   - System maintenance

## Configuration

### Adjust Activity Weights

Edit `user_behavior_simulator.py` to change activity probabilities:

```python
activities = [
    {'name': 'Browse Web', 'func': self._browse_web, 'weight': 25},
    {'name': 'File Operations', 'func': self._file_operations, 'weight': 20},
    # ... adjust weights as needed
]
```

### Add Custom Activities

1. Create a new method in `UserBehaviorSimulator` class
2. Add it to the activities list with appropriate weight
3. Implement the activity logic

## Logging

All activities are logged to:
- Console output
- `user_behavior.log` file
- `activity_log_YYYYMMDD_HHMMSS.json` file

## Best Practices

1. **Run for Extended Periods**: Run for at least 24-48 hours to generate sufficient data
2. **Vary Intervals**: Use different activity intervals to simulate realistic patterns
3. **Mix Manual and Automated**: Occasionally perform manual activities to add variance
4. **Run During Business Hours**: Simulate activities during typical work hours for realism
5. **Monitor Resource Usage**: Ensure automation doesn't consume excessive resources

## Integration with Sysmon

The automation works with Sysmon to generate logs:

1. Install Sysmon on the Windows VM
2. Configure Sysmon to log Event IDs: 1, 7, 10, 11, 13, 22
3. Run automation scripts
4. Collect Sysmon logs using the event collector

## Troubleshooting

### Selenium Issues

If ChromeDriver fails:
- Update Chrome browser
- Check internet connection (for auto-download)
- Manually download ChromeDriver

### PowerShell Execution Policy

If PowerShell scripts are blocked:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Office Application Errors

If Office automation fails:
- Ensure Office is installed
- Check COM object permissions
- Use alternative methods (file operations)

## Output

After running, you'll have:
- Sysmon event logs (from Windows Event Log)
- Activity logs (JSON format)
- Generated test files (on Desktop/Documents)
- Process execution history

## Next Steps

1. Run automation for desired duration
2. Collect Sysmon logs using `collectors/windows_event_collector.py`
3. Process logs using `scripts/process_evtx_files.py`
4. Train models with processed data



