#!/usr/bin/env python3
"""Quick verification of prepared data"""

import pandas as pd
import sys

if len(sys.argv) < 2:
    print("Usage: python verify_prepared_data.py <csv_file>")
    sys.exit(1)

df = pd.read_csv(sys.argv[1])

print("=" * 60)
print("PREPARED DATA SUMMARY")
print("=" * 60)
print(f"\nTotal events: {len(df):,}")
print(f"Columns: {len(df.columns)}")

if 'weight' in df.columns:
    print(f"\nWeight column:")
    print(f"  Range: {df['weight'].min():.4f} to {df['weight'].max():.4f}")
    print(f"  Average: {df['weight'].mean():.4f}")

if 'occurrence_count' in df.columns:
    print(f"\nOccurrence count:")
    print(f"  Range: {df['occurrence_count'].min()} to {df['occurrence_count'].max()}")
    print(f"  Average: {df['occurrence_count'].mean():.2f}")

new_features = [c for c in df.columns if c in [
    'hour_of_day', 'day_of_week', 'is_weekend', 'is_business_hours',
    'event_sequence_id', 'parent_is_same', 'has_unusual_parent',
    'process_path_depth', 'is_system_path', 'is_user_path'
]]
if new_features:
    print(f"\nNew features added: {len(new_features)}")
    print(f"  {', '.join(new_features)}")

print(f"\nData diversity:")
print(f"  Unique command lines: {df['command_line'].nunique():,}")
print(f"  Unique processes: {df['process_name'].nunique():,}")

if 'label' in df.columns:
    print(f"\nLabel distribution:")
    print(df['label'].value_counts().to_string())

print("\n" + "=" * 60)










