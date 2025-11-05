import requests
import json
import time
from datetime import datetime
from typing import Dict, Any, Optional
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings


class WindowsEventCollector:
    """Collects Windows events from Sysmon and streams to detection backend."""
    
    def __init__(self, backend_url: str = None):
        self.backend_url = backend_url or f"http://{settings.api_host}:{settings.api_port}"
        self.event_endpoint = f"{self.backend_url}/api/v1/events"
        self.running = False
    
    def collect_events_from_file(self, evtx_file_path: str):
        """Collect events from EVTX file and send to backend."""
        try:
            import Evtx.Evtx as evtx
            
            with evtx.Evtx(evtx_file_path) as log:
                for record in log.records():
                    event_data = self._parse_event_record(record)
                    if event_data:
                        self._send_event(event_data)
        except ImportError:
            print("ERROR: evtx library not available. Install with: pip install python-evtx")
            sys.exit(1)
        except Exception as e:
            print(f"Error processing EVTX file: {e}")
    
    def collect_events_realtime(self):
        """Collect events in real-time from Windows Event Log."""
        self.running = True
        
        try:
            if sys.platform != 'win32':
                print("ERROR: Real-time collection requires Windows OS")
                sys.exit(1)
            
            import win32evtlog
            import win32evtlogutil
            
            # Open Sysmon event log
            handle = win32evtlog.OpenEventLog(None, "Microsoft-Windows-Sysmon/Operational")
            
            if not handle:
                print("ERROR: Could not open Sysmon event log. Is Sysmon installed?")
                sys.exit(1)
            
            # Read events
            flags = win32evtlog.EVENTLOG_BACKWARDS_READ | win32evtlog.EVENTLOG_SEQUENTIAL_READ
            
            while self.running:
                events = win32evtlog.ReadEventLog(handle, flags, 0)
                
                if not events:
                    time.sleep(1)
                    continue
                
                for event in events:
                    event_data = self._parse_win32_event(event)
                    if event_data:
                        self._send_event(event_data)
                
                time.sleep(0.5)
            
            win32evtlog.CloseEventLog(handle)
        except ImportError:
            print("ERROR: pywin32 not available. Install with: pip install pywin32")
            sys.exit(1)
        except Exception as e:
            print(f"Error in real-time collection: {e}")
            self.running = False
    
    def _parse_event_record(self, record) -> Optional[Dict[str, Any]]:
        """Parse EVTX record to event data."""
        try:
            xml = record.xml()
            # Parse XML to extract event data
            # This is a simplified version - actual implementation would parse XML properly
            import xml.etree.ElementTree as ET
            root = ET.fromstring(xml)
            
            event_data = {}
            
            # Extract common fields
            system = root.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}System')
            if system is not None:
                event_id_elem = system.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}EventID')
                if event_id_elem is not None:
                    event_data['event_id'] = event_id_elem.text
            
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
            
            event_data['timestamp'] = datetime.now()
            event_data['raw_event_data'] = xml
            
            return event_data if event_data.get('command_line') else None
        except Exception as e:
            print(f"Error parsing event record: {e}")
            return None
    
    def _parse_win32_event(self, event) -> Optional[Dict[str, Any]]:
        """Parse win32 event to event data."""
        try:
            event_data = {
                'event_id': str(event.EventID),
                'timestamp': datetime.fromtimestamp(event.TimeGenerated.timestamp()),
                'raw_event_data': {}
            }
            
            # Parse event strings
            event_strings = win32evtlogutil.SafeFormatMessage(event, "Microsoft-Windows-Sysmon/Operational")
            
            # Extract fields from event strings (simplified)
            # In production, you would parse the event data structure properly
            event_data['process_name'] = ''
            event_data['command_line'] = ''
            event_data['parent_image'] = ''
            event_data['user'] = ''
            event_data['integrity_level'] = ''
            
            # This is a placeholder - actual implementation would parse event data properly
            # based on the Sysmon event structure
            
            return event_data if event_data.get('command_line') else None
        except Exception as e:
            print(f"Error parsing win32 event: {e}")
            return None
    
    def _send_event(self, event_data: Dict[str, Any]):
        """Send event to backend API."""
        try:
            payload = {
                'event_id': event_data.get('event_id', ''),
                'timestamp': event_data.get('timestamp', datetime.now()).isoformat(),
                'process_name': event_data.get('process_name', ''),
                'command_line': event_data.get('command_line', ''),
                'parent_image': event_data.get('parent_image'),
                'user': event_data.get('user'),
                'integrity_level': event_data.get('integrity_level'),
                'raw_event_data': event_data.get('raw_event_data')
            }
            
            response = requests.post(
                self.event_endpoint,
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            
            print(f"Event sent: {event_data.get('process_name')} - {event_data.get('command_line', '')[:50]}")
        except requests.exceptions.RequestException as e:
            print(f"Error sending event to backend: {e}")
        except Exception as e:
            print(f"Unexpected error sending event: {e}")


def main():
    """Main entry point for event collector."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Windows Event Collector')
    parser.add_argument('--mode', choices=['file', 'realtime'], default='realtime',
                       help='Collection mode: file or realtime')
    parser.add_argument('--file', type=str, help='Path to EVTX file (for file mode)')
    parser.add_argument('--backend-url', type=str, help='Backend API URL')
    
    args = parser.parse_args()
    
    collector = WindowsEventCollector(backend_url=args.backend_url)
    
    if args.mode == 'file':
        if not args.file:
            print("ERROR: --file required for file mode")
            sys.exit(1)
        collector.collect_events_from_file(args.file)
    else:
        print("Starting real-time event collection...")
        print("Press Ctrl+C to stop")
        try:
            collector.collect_events_realtime()
        except KeyboardInterrupt:
            print("\nStopping event collection...")
            collector.running = False


if __name__ == "__main__":
    main()



