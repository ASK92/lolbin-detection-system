#!/usr/bin/env python3
"""
Process EVTX files and label by date
- Events until November 16, 2025 22:00:00 = Benign (label 0)
- Events from November 16, 2025 22:01:00 to November 17, 2025 23:59:59 = Malicious (label 1)
- Events from November 18, 2025 00:00:00 onwards = Benign (label 0)
"""

import argparse
import csv
from pathlib import Path
from datetime import datetime, timedelta
import sys

try:
    import Evtx.Evtx as evtx
    EVTX_AVAILABLE = True
except ImportError:
    EVTX_AVAILABLE = False
    print("ERROR: python-evtx library not available. Install with: pip install python-evtx")
    sys.exit(1)

def parse_event_record(record) -> dict:
    """Parse EVTX record to event data."""
    import xml.etree.ElementTree as ET
    
    xml = record.xml()
    root = ET.fromstring(xml)
    
    event_data = {}
    
    # Extract Event ID
    system = root.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}System')
    if system is not None:
        event_id_elem = system.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}EventID')
        if event_id_elem is not None:
            event_data['event_id'] = event_id_elem.text
        
        # Extract timestamp
        time_created = system.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}TimeCreated')
        if time_created is not None:
            event_data['timestamp'] = time_created.get('SystemTime', datetime.now().isoformat())
    
    # Extract event data
    event_data_elem = root.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}EventData')
    if event_data_elem is not None:
        for data in event_data_elem.findall('.//{http://schemas.microsoft.com/win/2004/08/events/event}Data'):
            name = data.get('Name')
            value = data.text
            
            if name == 'CommandLine':
                event_data['command_line'] = value
            elif name == 'Image':
                event_data['process_name'] = value
            elif name == 'ParentImage':
                event_data['parent_image'] = value
            elif name == 'User':
                event_data['user'] = value
            elif name == 'IntegrityLevel':
                event_data['integrity_level'] = value
    
    # Only return events with command line
    if event_data.get('command_line'):
        return event_data
    
    return None

def parse_evtx_file(evtx_path: str, malicious_start: datetime, malicious_end: datetime) -> tuple:
    """Parse EVTX file and extract events, labeling by date."""
    benign_events = []
    malicious_events = []
    
    with evtx.Evtx(evtx_path) as log:
        for record in log.records():
            try:
                event_data = parse_event_record(record)
                if event_data:
                    # Parse timestamp
                    try:
                        event_time = datetime.fromisoformat(event_data['timestamp'].replace('Z', '+00:00'))
                        # Remove timezone for comparison
                        event_time_naive = event_time.replace(tzinfo=None)
                        malicious_start_naive = malicious_start.replace(tzinfo=None)
                        malicious_end_naive = malicious_end.replace(tzinfo=None)
                        
                        # Label based on date windows:
                        # - Until Nov 16 22:00:00 (inclusive) = Benign
                        # - Nov 16 22:01:00 to Nov 17 23:59:59 (inclusive) = Malicious
                        # - Nov 18 00:00:00 onwards = Benign
                        if malicious_start_naive <= event_time_naive <= malicious_end_naive:
                            event_data['label'] = 1  # Malicious
                            malicious_events.append(event_data)
                        else:
                            event_data['label'] = 0  # Benign
                            benign_events.append(event_data)
                    except Exception as e:
                        # If timestamp parsing fails, skip the event
                        continue
            except Exception as e:
                continue
    
    return benign_events, malicious_events

def save_events_to_csv(events: list, output_path: str):
    """Save events to CSV file."""
    if not events:
        print(f"No events to save to {output_path}")
        return
    
    fieldnames = ['event_id', 'timestamp', 'process_name', 'command_line', 
                  'parent_image', 'user', 'integrity_level', 'label']
    
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for event in events:
            row = {
                'event_id': event.get('event_id', ''),
                'timestamp': event.get('timestamp', ''),
                'process_name': event.get('process_name', ''),
                'command_line': event.get('command_line', ''),
                'parent_image': event.get('parent_image', ''),
                'user': event.get('user', ''),
                'integrity_level': event.get('integrity_level', ''),
                'label': event.get('label', 0)
            }
            writer.writerow(row)
    
    print(f"Saved {len(events)} events to {output_path}")

def main():
    parser = argparse.ArgumentParser(description='Process EVTX files and label by date')
    parser.add_argument('--input-dir', type=str, required=True, help='Input directory containing EVTX files')
    parser.add_argument('--benign-output', type=str, required=True, help='Output file for benign events (CSV)')
    parser.add_argument('--malicious-output', type=str, required=True, help='Output file for malicious events (CSV)')
    parser.add_argument('--malicious-start', type=str, default='2025-11-16 22:01:00', 
                       help='Malicious window start (YYYY-MM-DD HH:MM:SS). Default: 2025-11-16 22:01:00')
    parser.add_argument('--malicious-end', type=str, default='2025-11-17 23:59:59', 
                       help='Malicious window end (YYYY-MM-DD HH:MM:SS). Default: 2025-11-17 23:59:59')
    parser.add_argument('--file-filter', type=str, default='', 
                       help='Only process files containing this string in the filename')
    
    args = parser.parse_args()
    
    if not EVTX_AVAILABLE:
        print("ERROR: python-evtx library not available. Install with: pip install python-evtx")
        sys.exit(1)
    
    # Parse malicious window dates
    try:
        malicious_start = datetime.strptime(args.malicious_start, '%Y-%m-%d %H:%M:%S')
    except:
        malicious_start = datetime.strptime(args.malicious_start, '%Y-%m-%d')
        malicious_start = malicious_start.replace(hour=22, minute=1, second=0)
    
    try:
        malicious_end = datetime.strptime(args.malicious_end, '%Y-%m-%d %H:%M:%S')
    except:
        malicious_end = datetime.strptime(args.malicious_end, '%Y-%m-%d')
        malicious_end = malicious_end.replace(hour=23, minute=59, second=59)
    
    print("="*60)
    print("LABELING RULES")
    print("="*60)
    print(f"Benign (label 0):")
    print(f"  - Events until {malicious_start.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  - Events from {(malicious_end + timedelta(seconds=1)).strftime('%Y-%m-%d %H:%M:%S')} onwards")
    print(f"")
    print(f"Malicious (label 1):")
    print(f"  - Events from {malicious_start.strftime('%Y-%m-%d %H:%M:%S')} to {malicious_end.strftime('%Y-%m-%d %H:%M:%S')}")
    print("")
    
    input_dir = Path(args.input_dir)
    if not input_dir.exists():
        print(f"ERROR: Input directory not found: {input_dir}")
        sys.exit(1)
    
    # Find all EVTX files
    evtx_files = list(input_dir.glob('*.evtx'))
    
    # Filter by filename if specified
    if args.file_filter:
        evtx_files = [f for f in evtx_files if args.file_filter in f.name]
        print(f"Filtering for files containing: {args.file_filter}")
    
    if not evtx_files:
        print(f"No EVTX files found in {input_dir}")
        if args.file_filter:
            print(f"  (with filter: {args.file_filter})")
        return
    
    print(f"Found {len(evtx_files)} EVTX file(s)")
    for f in evtx_files:
        print(f"  - {f.name}")
    print("")
    
    all_benign_events = []
    all_malicious_events = []
    
    for evtx_file in evtx_files:
        print(f"Processing {evtx_file.name}...")
        try:
            benign, malicious = parse_evtx_file(str(evtx_file), malicious_start, malicious_end)
            all_benign_events.extend(benign)
            all_malicious_events.extend(malicious)
            print(f"  Benign events: {len(benign)}")
            print(f"  Malicious events: {len(malicious)}")
        except Exception as e:
            print(f"  Error processing {evtx_file.name}: {e}")
    
    print("")
    print("="*60)
    print("SUMMARY")
    print("="*60)
    print(f"Total benign events: {len(all_benign_events)}")
    print(f"Total malicious events: {len(all_malicious_events)}")
    print(f"Total events: {len(all_benign_events) + len(all_malicious_events)}")
    print("")
    
    # Save benign events
    if all_benign_events:
        benign_output = Path(args.benign_output)
        benign_output.parent.mkdir(parents=True, exist_ok=True)
        save_events_to_csv(all_benign_events, str(benign_output))
    else:
        print("No benign events to save")
    
    # Save malicious events
    if all_malicious_events:
        malicious_output = Path(args.malicious_output)
        malicious_output.parent.mkdir(parents=True, exist_ok=True)
        save_events_to_csv(all_malicious_events, str(malicious_output))
    else:
        print("No malicious events to save")
    
    print("")
    print("Processing complete!")

if __name__ == "__main__":
    main()

