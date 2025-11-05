import argparse
import json
import csv
from pathlib import Path
from datetime import datetime
import sys

try:
    import Evtx.Evtx as evtx
    EVTX_AVAILABLE = True
except ImportError:
    EVTX_AVAILABLE = False
    print("WARNING: python-evtx not available. Install with: pip install python-evtx")


def parse_evtx_file(evtx_path: str) -> list:
    """Parse EVTX file and extract events."""
    if not EVTX_AVAILABLE:
        raise ImportError("python-evtx library not available")
    
    events = []
    
    with evtx.Evtx(evtx_path) as log:
        for record in log.records():
            try:
                event_data = parse_event_record(record)
                if event_data:
                    events.append(event_data)
            except Exception as e:
                print(f"Error parsing record: {e}")
                continue
    
    return events


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


def save_events_to_csv(events: list, output_path: str):
    """Save events to CSV file."""
    if not events:
        print("No events to save.")
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
                'label': event.get('label', 0)  # Default to benign
            }
            writer.writerow(row)
    
    print(f"Saved {len(events)} events to {output_path}")


def save_events_to_json(events: list, output_path: str):
    """Save events to JSON file."""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(events, f, indent=2, default=str)
    
    print(f"Saved {len(events)} events to {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Process EVTX files and extract events')
    parser.add_argument('--input-dir', type=str, required=True, help='Input directory containing EVTX files')
    parser.add_argument('--output-dir', type=str, required=True, help='Output directory for processed files')
    parser.add_argument('--format', choices=['csv', 'json'], default='csv', help='Output format')
    parser.add_argument('--label', type=int, default=0, help='Label for events (0=benign, 1=malicious)')
    
    args = parser.parse_args()
    
    if not EVTX_AVAILABLE:
        print("ERROR: python-evtx library not available. Install with: pip install python-evtx")
        sys.exit(1)
    
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Find all EVTX files
    evtx_files = list(input_dir.glob('*.evtx'))
    
    if not evtx_files:
        print(f"No EVTX files found in {input_dir}")
        return
    
    print(f"Found {len(evtx_files)} EVTX files")
    
    all_events = []
    
    for evtx_file in evtx_files:
        print(f"Processing {evtx_file.name}...")
        try:
            events = parse_evtx_file(str(evtx_file))
            for event in events:
                event['label'] = args.label
            all_events.extend(events)
            print(f"  Extracted {len(events)} events")
        except Exception as e:
            print(f"  Error processing {evtx_file.name}: {e}")
    
    # Save combined events
    if all_events:
        output_file = output_dir / f"events.{args.format}"
        if args.format == 'csv':
            save_events_to_csv(all_events, str(output_file))
        else:
            save_events_to_json(all_events, str(output_file))
    else:
        print("No events extracted.")


if __name__ == "__main__":
    main()




