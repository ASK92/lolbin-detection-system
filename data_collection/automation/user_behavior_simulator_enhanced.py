"""
Enhanced Windows User Behavior Simulator
Improved diversity with more activity types, time-based patterns, and LOLBin usage
"""

import random
import time
import subprocess
import os
import sys
from datetime import datetime, timedelta
from typing import List, Dict
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('user_behavior.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class EnhancedUserBehaviorSimulator:
    """Enhanced simulator with better diversity and time-based patterns"""
    
    def __init__(self, duration_hours: int = 24, activity_interval: int = 60):
        self.duration_hours = duration_hours
        self.base_activity_interval = activity_interval
        self.start_time = datetime.now()
        self.end_time = self.start_time + timedelta(hours=duration_hours)
        self.activities = []
        self.activity_count = 0
        self.error_count = 0
        self.max_errors = 100
        
    def _get_time_based_interval(self) -> int:
        """Get activity interval based on time of day"""
        current_hour = datetime.now().hour
        
        # Business hours (9 AM - 5 PM): More frequent activities
        if 9 <= current_hour <= 17:
            base = self.base_activity_interval * 0.7  # 30% faster
        # Evening (5 PM - 10 PM): Moderate
        elif 17 < current_hour <= 22:
            base = self.base_activity_interval * 1.0
        # Night (10 PM - 6 AM): Less frequent
        elif 22 < current_hour or current_hour < 6:
            base = self.base_activity_interval * 1.5  # 50% slower
        # Morning (6 AM - 9 AM): Moderate
        else:
            base = self.base_activity_interval * 1.2
        
        # Add randomness
        return int(random.uniform(base * 0.5, base * 2.0))
    
    def _get_time_based_weights(self) -> List[Dict]:
        """Get activity weights based on time of day"""
        current_hour = datetime.now().hour
        is_weekend = datetime.now().weekday() >= 5
        
        # Base weights
        base_activities = [
            {'name': 'Browse Web', 'func': self._browse_web, 'weight': 20},
            {'name': 'File Operations', 'func': self._file_operations, 'weight': 18},
            {'name': 'Open Office App', 'func': self._open_office_app, 'weight': 12},
            {'name': 'System Commands', 'func': self._system_commands, 'weight': 12},
            {'name': 'PowerShell Activity', 'func': self._powershell_activity, 'weight': 10},
            {'name': 'LOLBin Commands', 'func': self._lolbin_commands, 'weight': 8},  # NEW
            {'name': 'Network Operations', 'func': self._network_operations, 'weight': 8},  # NEW
            {'name': 'Registry Operations', 'func': self._registry_operations, 'weight': 5},  # NEW
            {'name': 'Read Documents', 'func': self._read_documents, 'weight': 5},
            {'name': 'Background Tasks', 'func': self._background_tasks, 'weight': 2},
        ]
        
        # Adjust weights based on time
        if 9 <= current_hour <= 17:  # Business hours
            # More office apps, file ops, network
            for activity in base_activities:
                if activity['name'] in ['Open Office App', 'File Operations', 'Network Operations']:
                    activity['weight'] = int(activity['weight'] * 1.5)
                elif activity['name'] == 'Browse Web':
                    activity['weight'] = int(activity['weight'] * 1.2)
        elif 22 < current_hour or current_hour < 6:  # Night
            # More background tasks, less office apps
            for activity in base_activities:
                if activity['name'] == 'Background Tasks':
                    activity['weight'] = int(activity['weight'] * 2.0)
                elif activity['name'] in ['Open Office App', 'Browse Web']:
                    activity['weight'] = int(activity['weight'] * 0.7)
        
        return base_activities
    
    def run(self):
        """Run the simulation"""
        logger.info(f"Starting ENHANCED user behavior simulation for {self.duration_hours} hours")
        logger.info(f"Base activity interval: {self.base_activity_interval} seconds")
        
        while datetime.now() < self.end_time:
            try:
                # Select random activity with time-based weights
                activity = self._select_activity()
                self.activity_count += 1
                
                # Log progress every 100 activities
                if self.activity_count % 100 == 0:
                    elapsed = datetime.now() - self.start_time
                    remaining = self.end_time - datetime.now()
                    logger.info(f"Progress: {self.activity_count} activities completed | "
                              f"Elapsed: {elapsed} | Remaining: {remaining}")
                
                logger.info(f"Activity #{self.activity_count}: {activity['name']}")
                
                # Execute activity
                activity['func']()
                
                # Reset error count on success
                self.error_count = 0
                
                # Log activity
                self.activities.append({
                    'timestamp': datetime.now().isoformat(),
                    'activity': activity['name'],
                    'activity_number': self.activity_count
                })
                
                # Save progress every 500 activities
                if self.activity_count % 500 == 0:
                    self._save_activity_log()
                
                # Wait with time-based interval
                wait_time = self._get_time_based_interval()
                logger.debug(f"Waiting {wait_time} seconds before next activity")
                time.sleep(wait_time)
                
            except KeyboardInterrupt:
                logger.info("Simulation interrupted by user")
                break
            except Exception as e:
                self.error_count += 1
                logger.error(f"Error executing activity ({self.error_count}/{self.max_errors}): {e}")
                
                if self.error_count >= self.max_errors:
                    logger.error(f"Too many consecutive errors ({self.error_count}). Stopping simulation.")
                    break
                
                time.sleep(30)
        
        logger.info("Simulation completed")
        self._save_activity_log()
    
    def _select_activity(self):
        """Select a random activity based on time-based weighted probabilities"""
        activities = self._get_time_based_weights()
        
        # Weighted random selection
        total_weight = sum(a['weight'] for a in activities)
        rand = random.uniform(0, total_weight)
        cumulative = 0
        
        for activity in activities:
            cumulative += activity['weight']
            if rand <= cumulative:
                return activity
        
        return activities[0]
    
    # ========== NEW ACTIVITY METHODS ==========
    
    def _lolbin_commands(self):
        """Run legitimate LOLBin commands (for diversity)"""
        lolbin_activities = [
            self._certutil_legitimate,
            self._wmic_legitimate,
            self._regsvr32_legitimate,
            self._bitsadmin_legitimate,
            self._schtasks_legitimate,
            self._sc_legitimate,
            self._rundll32_legitimate,
            self._mshta_legitimate,
        ]
        
        activity = random.choice(lolbin_activities)
        activity()
    
    def _certutil_legitimate(self):
        """Legitimate certutil usage"""
        logger.info("Running certutil (legitimate)")
        try:
            # Check certificate store
            subprocess.run(['certutil', '-store', '-user', 'My'], 
                         capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _wmic_legitimate(self):
        """Legitimate WMIC usage"""
        logger.info("Running WMIC (legitimate)")
        wmic_commands = [
            ['wmic', 'os', 'get', 'Caption,Version'],
            ['wmic', 'cpu', 'get', 'Name'],
            ['wmic', 'diskdrive', 'get', 'Size'],
            ['wmic', 'process', 'get', 'Name,ProcessId', '/format:csv'],
        ]
        try:
            cmd = random.choice(wmic_commands)
            subprocess.run(cmd, capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _regsvr32_legitimate(self):
        """Legitimate regsvr32 usage (query only)"""
        logger.info("Running regsvr32 query (legitimate)")
        try:
            # Just query, don't actually register
            subprocess.run(['regsvr32', '/?'], capture_output=True, timeout=5)
            time.sleep(1)
        except:
            pass
    
    def _bitsadmin_legitimate(self):
        """Legitimate BITSAdmin usage"""
        logger.info("Running BITSAdmin (legitimate)")
        try:
            # List transfers
            subprocess.run(['bitsadmin', '/list', '/allusers'], 
                         capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _schtasks_legitimate(self):
        """Legitimate Task Scheduler usage"""
        logger.info("Running schtasks (legitimate)")
        try:
            # Query tasks
            subprocess.run(['schtasks', '/query', '/fo', 'LIST'], 
                         capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _sc_legitimate(self):
        """Legitimate SC (Service Control) usage"""
        logger.info("Running sc query (legitimate)")
        try:
            # Query services
            subprocess.run(['sc', 'query', 'type=', 'service', 'state=', 'all'], 
                         capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _rundll32_legitimate(self):
        """Legitimate rundll32 usage"""
        logger.info("Running rundll32 (legitimate)")
        try:
            # Print help
            subprocess.run(['rundll32', 'printui.dll,PrintUIEntry', '/?'], 
                         capture_output=True, timeout=5)
            time.sleep(1)
        except:
            pass
    
    def _mshta_legitimate(self):
        """Legitimate mshta usage (query only)"""
        logger.info("Running mshta query (legitimate)")
        try:
            # Just show help
            subprocess.run(['mshta', '/?'], capture_output=True, timeout=5)
            time.sleep(1)
        except:
            pass
    
    def _network_operations(self):
        """Network-related operations"""
        network_activities = [
            self._ping_hosts,
            self._nslookup_domains,
            self._net_commands,
            self._curl_requests,
        ]
        
        activity = random.choice(network_activities)
        activity()
    
    def _ping_hosts(self):
        """Ping common hosts"""
        logger.info("Pinging hosts")
        hosts = ['8.8.8.8', '1.1.1.1', 'google.com', 'microsoft.com']
        try:
            host = random.choice(hosts)
            subprocess.run(['ping', '-n', '2', host], 
                         capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _nslookup_domains(self):
        """DNS lookups"""
        logger.info("Performing DNS lookup")
        domains = ['google.com', 'github.com', 'microsoft.com', 'stackoverflow.com']
        try:
            domain = random.choice(domains)
            subprocess.run(['nslookup', domain], capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _net_commands(self):
        """NET commands"""
        logger.info("Running NET command")
        net_cmds = [
            ['net', 'user'],
            ['net', 'localgroup'],
            ['net', 'share'],
            ['net', 'statistics', 'workstation'],
        ]
        try:
            cmd = random.choice(net_cmds)
            subprocess.run(cmd, capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _curl_requests(self):
        """CURL requests"""
        logger.info("Making CURL request")
        urls = [
            'https://www.google.com',
            'https://www.github.com',
            'https://www.microsoft.com',
        ]
        try:
            url = random.choice(urls)
            subprocess.run(['curl', '-s', '-o', 'nul', url], 
                         capture_output=True, timeout=15)
            time.sleep(1)
        except:
            pass
    
    def _registry_operations(self):
        """Registry operations (read-only)"""
        registry_activities = [
            self._reg_query,
            self._reg_export,
        ]
        
        activity = random.choice(registry_activities)
        activity()
    
    def _reg_query(self):
        """Query registry"""
        logger.info("Querying registry")
        queries = [
            ['reg', 'query', 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion'],
            ['reg', 'query', 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion'],
            ['reg', 'query', 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'],
        ]
        try:
            query = random.choice(queries)
            subprocess.run(query, capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _reg_export(self):
        """Export registry (small key)"""
        logger.info("Exporting registry key")
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        export_file = os.path.join(desktop, f'reg_export_{random.randint(1000,9999)}.reg')
        try:
            subprocess.run(['reg', 'export', 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run', 
                          export_file, '/y'], capture_output=True, timeout=10)
            time.sleep(1)
            # Clean up
            if os.path.exists(export_file):
                os.remove(export_file)
        except:
            pass
    
    # ========== ENHANCED EXISTING METHODS ==========
    
    def _system_commands(self):
        """Run diverse system commands"""
        commands = [
            ('dir', ['dir', os.path.expanduser('~'), '/s', '/b']),
            ('tasklist', ['tasklist', '/v']),
            ('systeminfo', ['systeminfo']),
            ('ipconfig', ['ipconfig', '/all']),
            ('netstat', ['netstat', '-an']),
            ('whoami', ['whoami', '/all']),
            ('get-date', ['powershell', '-Command', 'Get-Date']),
            ('get-process', ['powershell', '-Command', 'Get-Process | Select-Object -First 20']),
            ('get-service', ['powershell', '-Command', 'Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object -First 10']),
            ('get-eventlog', ['powershell', '-Command', 'Get-EventLog -LogName System -Newest 5']),
        ]
        
        cmd_name, cmd = random.choice(commands)
        logger.info(f"Running command: {cmd_name}")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            time.sleep(1)
        except:
            pass
    
    def _powershell_activity(self):
        """Run diverse PowerShell commands"""
        ps_commands = [
            'Get-Process | Select-Object -First 10 | Format-Table',
            'Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object -First 10',
            'Get-ChildItem $env:USERPROFILE\Documents | Select-Object -First 15',
            'Get-Date -Format "yyyy-MM-dd HH:mm:ss"',
            'Get-ComputerInfo | Select-Object -Property TotalPhysicalMemory,OSName,WindowsVersion',
            '$env:USERNAME; $env:COMPUTERNAME',
            'Get-EventLog -LogName Application -Newest 5 | Format-List',
            'Get-NetIPAddress | Select-Object -First 10',
            'Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption,Version',
            'Get-ChildItem $env:TEMP | Measure-Object -Property Length -Sum',
            'Get-Content $env:USERPROFILE\Documents\*.txt -ErrorAction SilentlyContinue | Select-Object -First 5',
            'Test-Connection -ComputerName google.com -Count 2',
        ]
        
        cmd = random.choice(ps_commands)
        logger.info(f"Running PowerShell: {cmd[:60]}...")
        
        try:
            subprocess.run(['powershell', '-Command', cmd], 
                         capture_output=True, timeout=15)
            time.sleep(1)
        except:
            pass
    
    # ========== KEEP EXISTING METHODS ==========
    
    def _check_chrome_installed(self):
        """Check if Chrome is installed"""
        chrome_paths = [
            'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
            os.path.expanduser('~\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe')
        ]
        return any(os.path.exists(path) for path in chrome_paths)
    
    def _browse_web(self):
        """Simulate web browsing"""
        chrome_paths = [
            'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
            os.path.expanduser('~\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe')
        ]
        chrome_installed = any(os.path.exists(path) for path in chrome_paths)
        
        if chrome_installed:
            try:
                from selenium import webdriver
                from selenium.webdriver.common.by import By
                from selenium.webdriver.common.keys import Keys
                from selenium.webdriver.chrome.service import Service
                from webdriver_manager.chrome import ChromeDriverManager
                
                options = webdriver.ChromeOptions()
                options.add_argument('--start-maximized')
                options.add_argument('--disable-blink-features=AutomationControlled')
                options.add_experimental_option("excludeSwitches", ["enable-automation"])
                options.add_experimental_option('useAutomationExtension', False)
                
                driver = webdriver.Chrome(
                    service=Service(ChromeDriverManager().install()),
                    options=options
                )
                
                sites = [
                    'https://www.google.com',
                    'https://www.github.com',
                    'https://www.stackoverflow.com',
                    'https://www.microsoft.com',
                    'https://www.reddit.com',
                    'https://news.ycombinator.com',
                    'https://www.python.org',
                    'https://www.wikipedia.org',
                ]
                
                site = random.choice(sites)
                logger.info(f"Browsing to {site} (Chrome)")
                driver.get(site)
                time.sleep(random.randint(5, 15))
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2);")
                time.sleep(2)
                
                if 'google' in driver.current_url.lower():
                    try:
                        search_box = driver.find_element(By.NAME, 'q')
                        search_terms = ['python', 'machine learning', 'cybersecurity', 'windows', 'automation']
                        search_box.send_keys(random.choice(search_terms))
                        search_box.send_keys(Keys.RETURN)
                        time.sleep(random.randint(3, 8))
                    except:
                        pass
                
                driver.quit()
                return
                
            except ImportError:
                logger.debug("Selenium not available, falling back to PowerShell")
            except Exception as e:
                logger.debug(f"Chrome/Selenium failed: {e}, falling back to PowerShell")
        
        logger.info("Using default browser (PowerShell)")
        sites = [
            'https://www.google.com',
            'https://www.github.com',
            'https://www.microsoft.com',
            'https://www.stackoverflow.com',
            'https://www.python.org',
        ]
        site = random.choice(sites)
        try:
            subprocess.run(['powershell', '-Command', f'Start-Process "{site}"'], 
                         timeout=30, check=False)
            time.sleep(random.randint(5, 10))
            time.sleep(5)
            try:
                subprocess.run(['powershell', '-Command', 
                              'Get-Process msedge,chrome,firefox -ErrorAction SilentlyContinue | Stop-Process -Force'], 
                             check=False, timeout=5)
            except:
                pass
        except Exception as e:
            logger.debug(f"Browser fallback failed: {e}")
    
    def _file_operations(self):
        """Simulate file operations"""
        operations = [
            self._create_test_file,
            self._copy_file,
            self._list_directory,
            self._read_file,
            self._move_file,
            self._delete_file,
        ]
        
        operation = random.choice(operations)
        operation()
    
    def _create_test_file(self):
        """Create a test file"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        filename = f"test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        filepath = os.path.join(desktop, filename)
        
        with open(filepath, 'w') as f:
            f.write(f"Test file created at {datetime.now()}\n")
            f.write("This is a benign test file for data collection.\n")
            f.write(f"Random content: {random.randint(1000, 9999)}\n")
        
        logger.info(f"Created file: {filename}")
        time.sleep(1)
    
    def _copy_file(self):
        """Copy a file"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        files = [f for f in os.listdir(desktop) if os.path.isfile(os.path.join(desktop, f)) and f.endswith('.txt')]
        
        if files:
            source = os.path.join(desktop, random.choice(files))
            dest = os.path.join(desktop, f"copy_{os.path.basename(source)}")
            try:
                subprocess.run(['copy', source, dest], shell=True, check=False)
                logger.info(f"Copied file: {os.path.basename(source)}")
            except:
                pass
    
    def _move_file(self):
        """Move a file"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        files = [f for f in os.listdir(desktop) if os.path.isfile(os.path.join(desktop, f)) and f.startswith('copy_')]
        
        if files:
            source = os.path.join(desktop, random.choice(files))
            dest = os.path.join(desktop, f"moved_{os.path.basename(source)}")
            try:
                os.rename(source, dest)
                logger.info(f"Moved file: {os.path.basename(source)}")
            except:
                pass
    
    def _delete_file(self):
        """Delete a test file"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        files = [f for f in os.listdir(desktop) if os.path.isfile(os.path.join(desktop, f)) and (f.startswith('test_') or f.startswith('moved_'))]
        
        if files and random.random() < 0.3:  # Only delete 30% of the time
            filepath = os.path.join(desktop, random.choice(files))
            try:
                os.remove(filepath)
                logger.info(f"Deleted file: {os.path.basename(filepath)}")
            except:
                pass
    
    def _list_directory(self):
        """List directory contents"""
        directories = [
            os.path.join(os.path.expanduser('~'), 'Desktop'),
            os.path.join(os.path.expanduser('~'), 'Documents'),
            os.path.join(os.path.expanduser('~'), 'Downloads'),
            os.path.join(os.path.expanduser('~'), 'Pictures'),
        ]
        
        dir_path = random.choice(directories)
        try:
            files = os.listdir(dir_path)
            logger.info(f"Listed directory: {dir_path} ({len(files)} items)")
            time.sleep(1)
        except:
            pass
    
    def _read_file(self):
        """Read a file"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        files = [f for f in os.listdir(desktop) if f.endswith('.txt')]
        
        if files:
            filepath = os.path.join(desktop, random.choice(files))
            try:
                with open(filepath, 'r') as f:
                    content = f.read(100)
                logger.info(f"Read file: {os.path.basename(filepath)}")
                time.sleep(1)
            except:
                pass
    
    def _open_office_app(self):
        """Open Office applications"""
        apps = []
        
        if self._check_app_exists('notepad.exe'):
            apps.append(('notepad', 'notepad.exe'))
        
        calc_paths = [
            'calc.exe',
            'C:\\Windows\\System32\\calc.exe',
            'C:\\Windows\\System32\\CalculatorApp.exe'
        ]
        calc_path = self._find_app(calc_paths)
        if calc_path:
            apps.append(('calculator', calc_path))
        
        if self._check_app_exists('mspaint.exe'):
            apps.append(('paint', 'mspaint.exe'))
        
        if self._check_app_exists('wordpad.exe'):
            apps.append(('wordpad', 'wordpad.exe'))
        
        if not apps:
            logger.info("No standard apps found, using PowerShell Calculator")
            try:
                subprocess.run(['powershell', '-Command', 'Start-Process Calculator'], 
                             check=False, timeout=5)
                time.sleep(random.randint(2, 5))
            except:
                pass
            return
        
        app_name, app_path = random.choice(apps)
        logger.info(f"Opening {app_name}")
        
        try:
            subprocess.Popen([app_path], shell=True)
            time.sleep(random.randint(2, 5))
            
            process_name = os.path.basename(app_path)
            if process_name == 'calc.exe':
                process_name = 'Calculator.exe'
            subprocess.run(['taskkill', '/F', '/IM', process_name], 
                         check=False, timeout=5)
        except Exception as e:
            logger.debug(f"Could not open {app_name}: {e}")
    
    def _check_app_exists(self, app_name):
        """Check if an application exists"""
        try:
            result = subprocess.run(['where', app_name], 
                                  capture_output=True, timeout=5, check=False)
            if result.returncode == 0:
                return True
            
            system_paths = [
                'C:\\Windows\\System32',
                'C:\\Windows',
                'C:\\Windows\\SystemApps'
            ]
            for path in system_paths:
                full_path = os.path.join(path, app_name)
                if os.path.exists(full_path):
                    return True
            return False
        except:
            return False
    
    def _find_app(self, paths):
        """Find first available app from list of paths"""
        for path in paths:
            try:
                if os.path.exists(path):
                    return path
                result = subprocess.run(['where', path], 
                                      capture_output=True, timeout=5, check=False)
                if result.returncode == 0:
                    return path
            except:
                continue
        return None
    
    def _read_documents(self):
        """Read documents"""
        documents = os.path.join(os.path.expanduser('~'), 'Documents')
        
        try:
            files = [f for f in os.listdir(documents) 
                    if f.endswith(('.txt', '.doc', '.docx', '.pdf'))][:10]
            
            if files:
                filepath = os.path.join(documents, random.choice(files))
                logger.info(f"Reading document: {os.path.basename(filepath)}")
                subprocess.Popen(['start', filepath], shell=True)
                time.sleep(random.randint(3, 8))
        except:
            pass
    
    def _background_tasks(self):
        """Simulate background tasks"""
        tasks = [
            self._check_updates,
            self._sync_files,
            self._system_maintenance
        ]
        
        task = random.choice(tasks)
        task()
    
    def _check_updates(self):
        """Check for updates"""
        logger.info("Checking for updates")
        try:
            subprocess.run(['powershell', '-Command', 
                          'Get-WUList | Select-Object -First 5'], 
                         capture_output=True, timeout=30)
        except:
            pass
    
    def _sync_files(self):
        """Simulate file sync"""
        logger.info("Syncing files")
        time.sleep(2)
    
    def _system_maintenance(self):
        """Run system maintenance"""
        logger.info("Running system maintenance")
        try:
            subprocess.run(['powershell', '-Command', 
                          'Get-ChildItem $env:TEMP -Recurse | Measure-Object'], 
                         capture_output=True, timeout=30)
        except:
            pass
    
    def _save_activity_log(self):
        """Save activity log"""
        log_file = f"activity_log_{self.start_time.strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            import json
            log_data = {
                'start_time': self.start_time.isoformat(),
                'end_time': datetime.now().isoformat(),
                'total_activities': self.activity_count,
                'duration_hours': self.duration_hours,
                'activities': self.activities
            }
            with open(log_file, 'w') as f:
                json.dump(log_data, f, indent=2)
            logger.info(f"Activity log saved to {log_file} ({len(self.activities)} activities)")
        except Exception as e:
            logger.error(f"Failed to save activity log: {e}")


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Enhanced Windows User Behavior Simulator')
    parser.add_argument('--duration', type=int, default=24, 
                       help='Duration in hours (default: 24)')
    parser.add_argument('--interval', type=int, default=60,
                       help='Base activity interval in seconds (default: 60)')
    parser.add_argument('--days', type=int, default=None,
                       help='Duration in days (alternative to --duration)')
    
    args = parser.parse_args()
    
    if args.days:
        duration_hours = args.days * 24
    else:
        duration_hours = args.duration
    
    logger.info(f"Starting ENHANCED simulation for {duration_hours} hours ({duration_hours/24:.1f} days)")
    logger.info(f"Base activity interval: {args.interval} seconds")
    logger.info(f"Estimated activities: ~{duration_hours * 3600 / args.interval}")
    
    simulator = EnhancedUserBehaviorSimulator(
        duration_hours=duration_hours,
        activity_interval=args.interval
    )
    
    simulator.run()


if __name__ == '__main__':
    main()








