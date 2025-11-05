"""
Office Application Automation
Automates Microsoft Office applications for realistic usage
"""

import subprocess
import time
import random
import os
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class OfficeAutomation:
    """Automates Office applications"""
    
    def __init__(self):
        self.documents_path = Path(os.path.expanduser('~')) / 'Documents'
        self.desktop_path = Path(os.path.expanduser('~')) / 'Desktop'
    
    def create_word_document(self):
        """Create a Word document using PowerShell"""
        try:
            filename = f"document_{int(time.time())}.docx"
            filepath = self.documents_path / filename
            
            # Create Word document using COM
            ps_script = f"""
            $word = New-Object -ComObject Word.Application
            $word.Visible = $true
            $doc = $word.Documents.Add()
            $doc.Content.Text = "Document created at $(Get-Date)"
            $doc.SaveAs([ref]"{filepath}")
            $doc.Close()
            $word.Quit()
            """
            
            subprocess.run(['powershell', '-Command', ps_script], 
                         timeout=30, check=False)
            logger.info(f"Created Word document: {filename}")
            time.sleep(2)
            
        except Exception as e:
            logger.error(f"Failed to create Word document: {e}")
    
    def create_excel_spreadsheet(self):
        """Create an Excel spreadsheet"""
        try:
            filename = f"spreadsheet_{int(time.time())}.xlsx"
            filepath = self.documents_path / filename
            
            ps_script = f"""
            $excel = New-Object -ComObject Excel.Application
            $excel.Visible = $true
            $workbook = $excel.Workbooks.Add()
            $worksheet = $workbook.ActiveSheet
            $worksheet.Cells.Item(1,1) = "Data"
            $worksheet.Cells.Item(2,1) = "Value 1"
            $worksheet.Cells.Item(3,1) = "Value 2"
            $workbook.SaveAs("{filepath}")
            $workbook.Close()
            $excel.Quit()
            """
            
            subprocess.run(['powershell', '-Command', ps_script],
                         timeout=30, check=False)
            logger.info(f"Created Excel spreadsheet: {filename}")
            time.sleep(2)
            
        except Exception as e:
            logger.error(f"Failed to create Excel spreadsheet: {e}")
    
    def open_notepad(self):
        """Open and use Notepad"""
        try:
            # Create a text file
            filename = f"note_{int(time.time())}.txt"
            filepath = self.desktop_path / filename
            
            with open(filepath, 'w') as f:
                f.write(f"Note created at {time.ctime()}\n")
                f.write("This is a test note.\n")
            
            # Open in Notepad
            subprocess.Popen(['notepad.exe', str(filepath)])
            time.sleep(random.uniform(3, 8))
            
            # Close Notepad
            subprocess.run(['taskkill', '/F', '/IM', 'notepad.exe'],
                         check=False, timeout=5)
            
            logger.info(f"Opened Notepad: {filename}")
            
        except Exception as e:
            logger.error(f"Failed to open Notepad: {e}")
    
    def open_calculator(self):
        """Open Calculator"""
        try:
            subprocess.Popen(['calc.exe'])
            time.sleep(random.uniform(2, 5))
            subprocess.run(['taskkill', '/F', '/IM', 'Calculator.exe'],
                         check=False, timeout=5)
            logger.info("Opened Calculator")
        except Exception as e:
            logger.error(f"Failed to open Calculator: {e}")
    
    def open_paint(self):
        """Open Paint"""
        try:
            subprocess.Popen(['mspaint.exe'])
            time.sleep(random.uniform(3, 8))
            subprocess.run(['taskkill', '/F', '/IM', 'mspaint.exe'],
                         check=False, timeout=5)
            logger.info("Opened Paint")
        except Exception as e:
            logger.error(f"Failed to open Paint: {e}")
    
    def read_documents(self):
        """Read existing documents"""
        try:
            # Find text files
            text_files = list(self.documents_path.glob('*.txt'))[:5]
            
            if text_files:
                filepath = random.choice(text_files)
                
                # Open with default application
                subprocess.Popen(['start', str(filepath)], shell=True)
                time.sleep(random.uniform(3, 8))
                
                logger.info(f"Read document: {filepath.name}")
        except Exception as e:
            logger.error(f"Failed to read documents: {e}")
    
    def run_random_activity(self):
        """Run a random Office activity"""
        activities = [
            self.open_notepad,
            self.open_calculator,
            self.open_paint,
            self.read_documents,
            self.create_word_document,
            self.create_excel_spreadsheet
        ]
        
        activity = random.choice(activities)
        activity()


def main():
    """Main entry point"""
    automation = OfficeAutomation()
    
    for _ in range(10):
        automation.run_random_activity()
        time.sleep(random.uniform(5, 15))


if __name__ == '__main__':
    main()


