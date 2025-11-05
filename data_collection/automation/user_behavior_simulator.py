"""
Windows User Behavior Simulator
Automates realistic user activity for generating benign training data
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


class UserBehaviorSimulator:
    """Simulates realistic Windows user behavior"""
    
    def __init__(self, duration_hours: int = 24, activity_interval: int = 60):
        self.duration_hours = duration_hours
        self.activity_interval = activity_interval  # seconds between activities
        self.start_time = datetime.now()
        self.end_time = self.start_time + timedelta(hours=duration_hours)
        self.activities = []
        self.activity_count = 0
        self.error_count = 0
        self.max_errors = 100  # Maximum consecutive errors before stopping
        
    def run(self):
        """Run the simulation"""
        logger.info(f"Starting user behavior simulation for {self.duration_hours} hours")
        logger.info(f"Activity interval: {self.activity_interval} seconds")
        
        while datetime.now() < self.end_time:
            try:
                # Select random activity
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
                
                # Save progress every 500 activities (for long runs)
                if self.activity_count % 500 == 0:
                    self._save_activity_log()
                
                # Wait before next activity
                wait_time = random.randint(
                    self.activity_interval // 2,
                    self.activity_interval * 2
                )
                logger.debug(f"Waiting {wait_time} seconds before next activity")
                time.sleep(wait_time)
                
            except KeyboardInterrupt:
                logger.info("Simulation interrupted by user")
                break
            except Exception as e:
                self.error_count += 1
                logger.error(f"Error executing activity ({self.error_count}/{self.max_errors}): {e}")
                
                # Stop if too many consecutive errors
                if self.error_count >= self.max_errors:
                    logger.error(f"Too many consecutive errors ({self.error_count}). Stopping simulation.")
                    break
                
                time.sleep(30)
        
        logger.info("Simulation completed")
        self._save_activity_log()
    
    def _select_activity(self):
        """Select a random activity based on weighted probabilities"""
        activities = [
            {'name': 'Browse Web', 'func': self._browse_web, 'weight': 25},
            {'name': 'File Operations', 'func': self._file_operations, 'weight': 20},
            {'name': 'Open Office App', 'func': self._open_office_app, 'weight': 15},
            {'name': 'System Commands', 'func': self._system_commands, 'weight': 15},
            {'name': 'PowerShell Activity', 'func': self._powershell_activity, 'weight': 10},
            {'name': 'Read Documents', 'func': self._read_documents, 'weight': 10},
            {'name': 'Background Tasks', 'func': self._background_tasks, 'weight': 5},
        ]
        
        # Weighted random selection
        total_weight = sum(a['weight'] for a in activities)
        rand = random.uniform(0, total_weight)
        cumulative = 0
        
        for activity in activities:
            cumulative += activity['weight']
            if rand <= cumulative:
                return activity
        
        return activities[0]
    
    def _browse_web(self):
        """Simulate web browsing"""
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
            
            # Visit common websites
            sites = [
                'https://www.google.com',
                'https://www.github.com',
                'https://www.stackoverflow.com',
                'https://www.microsoft.com',
                'https://www.reddit.com',
                'https://news.ycombinator.com'
            ]
            
            site = random.choice(sites)
            logger.info(f"Browsing to {site}")
            driver.get(site)
            
            # Simulate reading time
            time.sleep(random.randint(5, 15))
            
            # Scroll
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2);")
            time.sleep(2)
            
            # Search on Google
            if 'google' in driver.current_url.lower():
                try:
                    search_box = driver.find_element(By.NAME, 'q')
                    search_terms = ['python', 'machine learning', 'cybersecurity', 'windows']
                    search_box.send_keys(random.choice(search_terms))
                    search_box.send_keys(Keys.RETURN)
                    time.sleep(random.randint(3, 8))
                except:
                    pass
            
            driver.quit()
            
        except ImportError:
            logger.warning("Selenium not available, using PowerShell for web browsing")
            sites = [
                'https://www.google.com',
                'https://www.github.com',
                'https://www.microsoft.com'
            ]
            site = random.choice(sites)
            subprocess.run(['powershell', '-Command', f'Start-Process "{site}"'], 
                         timeout=30, check=False)
            time.sleep(random.randint(5, 10))
    
    def _file_operations(self):
        """Simulate file operations"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        documents = os.path.join(os.path.expanduser('~'), 'Documents')
        
        operations = [
            self._create_test_file,
            self._copy_file,
            self._list_directory,
            self._read_file
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
        
        logger.info(f"Created file: {filename}")
        time.sleep(1)
    
    def _copy_file(self):
        """Copy a file"""
        desktop = os.path.join(os.path.expanduser('~'), 'Desktop')
        files = [f for f in os.listdir(desktop) if os.path.isfile(os.path.join(desktop, f))]
        
        if files:
            source = os.path.join(desktop, random.choice(files))
            dest = os.path.join(desktop, f"copy_{os.path.basename(source)}")
            try:
                subprocess.run(['copy', source, dest], shell=True, check=False)
                logger.info(f"Copied file: {os.path.basename(source)}")
            except:
                pass
    
    def _list_directory(self):
        """List directory contents"""
        directories = [
            os.path.join(os.path.expanduser('~'), 'Desktop'),
            os.path.join(os.path.expanduser('~'), 'Documents'),
            os.path.join(os.path.expanduser('~'), 'Downloads')
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
                    content = f.read(100)  # Read first 100 chars
                logger.info(f"Read file: {os.path.basename(filepath)}")
                time.sleep(1)
            except:
                pass
    
    def _open_office_app(self):
        """Open Office applications"""
        apps = [
            ('notepad', 'notepad.exe'),
            ('calculator', 'calc.exe'),
            ('paint', 'mspaint.exe'),
            ('wordpad', 'wordpad.exe')
        ]
        
        app_name, app_path = random.choice(apps)
        logger.info(f"Opening {app_name}")
        
        try:
            subprocess.Popen([app_path], shell=True)
            time.sleep(random.randint(2, 5))
            
            # Close after a bit
            subprocess.run(['taskkill', '/F', '/IM', os.path.basename(app_path)], 
                         check=False, timeout=5)
        except:
            pass
    
    def _system_commands(self):
        """Run benign system commands"""
        commands = [
            ('dir', ['dir', os.path.expanduser('~')]),
            ('tasklist', ['tasklist']),
            ('systeminfo', ['systeminfo', '/FO', 'CSV']),
            ('ipconfig', ['ipconfig', '/all']),
            ('netstat', ['netstat', '-an']),
            ('whoami', ['whoami']),
            ('get-date', ['powershell', '-Command', 'Get-Date']),
            ('get-process', ['powershell', '-Command', 'Get-Process | Select-Object -First 10'])
        ]
        
        cmd_name, cmd = random.choice(commands)
        logger.info(f"Running command: {cmd_name}")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _powershell_activity(self):
        """Run benign PowerShell commands"""
        ps_commands = [
            'Get-Process | Select-Object -First 5',
            'Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object -First 5',
            'Get-ChildItem $env:USERPROFILE\Documents | Select-Object -First 10',
            'Get-Date',
            'Get-ComputerInfo | Select-Object -Property TotalPhysicalMemory,OSName',
            '$env:USERNAME',
            'Get-EventLog -LogName Application -Newest 5',
            'Get-NetIPAddress | Select-Object -First 5'
        ]
        
        cmd = random.choice(ps_commands)
        logger.info(f"Running PowerShell: {cmd[:50]}...")
        
        try:
            subprocess.run(['powershell', '-Command', cmd], 
                         capture_output=True, timeout=10)
            time.sleep(1)
        except:
            pass
    
    def _read_documents(self):
        """Read documents"""
        documents = os.path.join(os.path.expanduser('~'), 'Documents')
        
        try:
            files = [f for f in os.listdir(documents) 
                    if f.endswith(('.txt', '.doc', '.docx', '.pdf'))][:10]
            
            if files:
                filepath = os.path.join(documents, random.choice(files))
                logger.info(f"Reading document: {os.path.basename(filepath)}")
                
                # Try to open with default application
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
    
    parser = argparse.ArgumentParser(description='Windows User Behavior Simulator')
    parser.add_argument('--duration', type=int, default=24, 
                       help='Duration in hours (default: 24). Use 120 for 5 days.')
    parser.add_argument('--interval', type=int, default=60,
                       help='Activity interval in seconds (default: 60)')
    parser.add_argument('--days', type=int, default=None,
                       help='Duration in days (alternative to --duration). Use 5 for 5 days.')
    
    args = parser.parse_args()
    
    # Calculate duration
    if args.days:
        duration_hours = args.days * 24
    else:
        duration_hours = args.duration
    
    logger.info(f"Starting simulation for {duration_hours} hours ({duration_hours/24:.1f} days)")
    logger.info(f"Activity interval: {args.interval} seconds")
    logger.info(f"Estimated activities: ~{duration_hours * 3600 / args.interval}")
    
    simulator = UserBehaviorSimulator(
        duration_hours=duration_hours,
        activity_interval=args.interval
    )
    
    simulator.run()


if __name__ == '__main__':
    main()



