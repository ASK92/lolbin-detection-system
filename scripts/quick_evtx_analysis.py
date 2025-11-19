#!/usr/bin/env python3
"""
Quick EVTX Analysis - Get actual usable event counts
Analyzes EVTX files to determine how many events have command lines
"""

import argparse
import sys
from pathlib import Path

try:
    import Evtx.Evtx as evtx
    EVTX_AVAILABLE = True
except ImportError:
    EVTX_AVAILABLE = False
    print("ERROR: python-evtx not available. Install with: pip install python-evtx")
    sys.exit(1)

def analyze_evtx_file(evtx_path: str):
    """Analyze a single EVTX file and return statistics."""
    import xml.etree.ElementTree as ET
    
    total_events = 0
    event_id_1_count = 0
    events_with_command_line = 0
    events_without_command_line = 0
    
    print(f"\nAnalyzing: {Path(evtx_path).name}")
    print("-" * 60)
    
    try:
        with evtx.Evtx(evtx_path) as log:
            for record in log.records():
                total_events += 1
                
                try:
                    xml = record.xml()
                    root = ET.fromstring(xml)
                    
                    # Get Event ID
                    system = root.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}System')
                    if system is not None:
                        event_id_elem = system.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}EventID')
                        if event_id_elem is not None:
                            event_id = event_id_elem.text
                            
                            if event_id == "1":  # Process Creation
                                event_id_1_count += 1
                                
                                # Check for command line
                                event_data_elem = root.find('.//{http://schemas.microsoft.com/win/2004/08/events/event}EventData')
                                if event_data_elem is not None:
                                    has_command_line = False
                                    for data in event_data_elem.findall('.//{http://schemas.microsoft.com/win/2004/08/events/event}Data'):
                                        if data.get('Name') == 'CommandLine' and data.text and data.text.strip():
                                            has_command_line = True
                                            break
                                    
                                    if has_command_line:
                                        events_with_command_line += 1
                                    else:
                                        events_without_command_line += 1
                
                except Exception as e:
                    continue
        
        print(f"Total events in file: {total_events:,}")
        print(f"Event ID 1 (Process Creation): {event_id_1_count:,}")
        print(f"  ├─ With command line: {events_with_command_line:,} ({events_with_command_line/event_id_1_count*100:.1f}%)" if event_id_1_count > 0 else "  ├─ With command line: 0")
        print(f"  └─ Without command line: {events_without_command_line:,} ({events_without_command_line/event_id_1_count*100:.1f}%)" if event_id_1_count > 0 else "  └─ Without command line: 0")
        
        return {
            'total': total_events,
            'event_id_1': event_id_1_count,
            'with_cmd': events_with_command_line,
            'without_cmd': events_without_command_line
        }
    
    except Exception as e:
        print(f"ERROR processing file: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description='Quick analysis of EVTX files to count usable events')
    parser.add_argument('--input-dir', type=str, required=True, help='Directory containing EVTX files')
    parser.add_argument('--file', type=str, help='Single EVTX file to analyze')
    
    args = parser.parse_args()
    
    if args.file:
        evtx_files = [Path(args.file)]
    else:
        input_dir = Path(args.input_dir)
        if not input_dir.exists():
            print(f"ERROR: Directory not found: {input_dir}")
            sys.exit(1)
        
        evtx_files = list(input_dir.glob('*.evtx'))
        if not evtx_files:
            print(f"ERROR: No EVTX files found in {input_dir}")
            sys.exit(1)
    
    print("=" * 60)
    print("QUICK EVTX ANALYSIS - USABLE EVENT COUNT")
    print("=" * 60)
    print(f"\nFound {len(evtx_files)} EVTX file(s)")
    
    total_stats = {
        'total': 0,
        'event_id_1': 0,
        'with_cmd': 0,
        'without_cmd': 0
    }
    
    for evtx_file in evtx_files:
        stats = analyze_evtx_file(str(evtx_file))
        if stats:
            total_stats['total'] += stats['total']
            total_stats['event_id_1'] += stats['event_id_1']
            total_stats['with_cmd'] += stats['with_cmd']
            total_stats['without_cmd'] += stats['without_cmd']
    
    print("\n" + "=" * 60)
    print("TOTAL SUMMARY")
    print("=" * 60)
    print(f"Total events across all files: {total_stats['total']:,}")
    print(f"Event ID 1 (Process Creation): {total_stats['event_id_1']:,}")
    print(f"  ├─ USABLE (with command line): {total_stats['with_cmd']:,}")
    print(f"  └─ NOT USABLE (without command line): {total_stats['without_cmd']:,}")
    
    if total_stats['event_id_1'] > 0:
        usable_pct = (total_stats['with_cmd'] / total_stats['event_id_1']) * 100
        print(f"\nUsable rate: {usable_pct:.1f}% of Event ID 1 events")
    
    print("\n" + "=" * 60)
    print("ASSESSMENT")
    print("=" * 60)
    
    usable_count = total_stats['with_cmd']
    
    if usable_count >= 50000:
        print("✅ EXCELLENT: You have enough benign data for optimal training")
        print(f"   {usable_count:,} usable events (optimal: 50,000+)")
    elif usable_count >= 10000:
        print("✅ GOOD: You have enough benign data for recommended training")
        print(f"   {usable_count:,} usable events (recommended: 10,000+)")
    elif usable_count >= 1000:
        print("⚠️  MINIMUM: You have the minimum required benign data")
        print(f"   {usable_count:,} usable events (minimum: 1,000+)")
        print("   Consider collecting more for better model performance")
    else:
        print("❌ INSUFFICIENT: You need more benign data")
        print(f"   {usable_count:,} usable events (minimum: 1,000+)")
    
    print("\n" + "=" * 60)
    print("NEXT STEPS")
    print("=" * 60)
    print("1. ✅ You have benign data (if count above is sufficient)")
    print("2. ❌ CRITICAL: You still need malicious data (0 events)")
    print("   - Need at least 200 malicious events (1,000+ recommended)")
    print("   - Run LOLBin attack scripts to generate malicious events")
    print("3. Process EVTX files: python scripts/process_evtx_files.py")
    print("4. Analyze quality: python scripts/analyze_data_quality.py")
    print("=" * 60)


if __name__ == "__main__":
    main()







