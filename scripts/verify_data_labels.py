#!/usr/bin/env python3
"""
Verify Data Quality and Label Segregation
- Label 0: Data before 16th November 2025 (<= 2025-11-15 23:59:59)
- Label 1: Data from 17th November 2025 onwards (>= 2025-11-17 00:00:00)
"""

import pandas as pd
import sys
from pathlib import Path
from datetime import datetime, timezone
import numpy as np

def verify_label_segregation(df, label_col='label', timestamp_col='timestamp'):
    """Verify that labels are correctly segregated by date."""
    
    print("=" * 80)
    print("LABEL SEGREGATION VERIFICATION")
    print("=" * 80)
    print()
    
    # Define cutoff dates (timezone-aware to match data)
    cutoff_benign = datetime(2025, 11, 15, 23, 59, 59, tzinfo=timezone.utc)  # Before Nov 16
    cutoff_malicious = datetime(2025, 11, 17, 0, 0, 0, tzinfo=timezone.utc)  # From Nov 17 onwards
    
    print(f"Expected segregation:")
    print(f"  Label 0 (Benign):   <= {cutoff_benign}")
    print(f"  Label 1 (Malicious): >= {cutoff_malicious}")
    print(f"  Nov 16, 2025:        Should be Label 0 (or excluded)")
    print()
    
    # Convert timestamp to datetime
    df[timestamp_col] = pd.to_datetime(df[timestamp_col], errors='coerce')
    
    # Check for invalid timestamps
    invalid_timestamps = df[timestamp_col].isna().sum()
    if invalid_timestamps > 0:
        print(f"⚠️  WARNING: {invalid_timestamps} records with invalid timestamps")
        print()
    
    # Separate by label
    label_0 = df[df[label_col] == 0].copy()
    label_1 = df[df[label_col] == 1].copy()
    
    print(f"Label 0 (Benign) records: {len(label_0):,}")
    print(f"Label 1 (Malicious) records: {len(label_1):,}")
    print()
    
    # Check Label 0 dates
    if len(label_0) > 0:
        label_0_valid = label_0[label_0[timestamp_col].notna()]
        if len(label_0_valid) > 0:
            min_date_0 = label_0_valid[timestamp_col].min()
            max_date_0 = label_0_valid[timestamp_col].max()
            
            print(f"Label 0 date range: {min_date_0} to {max_date_0}")
            
            # Check for violations
            violations_0 = label_0_valid[label_0_valid[timestamp_col] >= cutoff_malicious]
            if len(violations_0) > 0:
                print(f"  ✗ ERROR: {len(violations_0)} Label 0 records on/after Nov 17, 2025!")
                print(f"    These should be Label 1")
                print(f"    Sample violations:")
                for idx, row in violations_0.head(5).iterrows():
                    print(f"      - {row[timestamp_col]}: {row.get('process_name', 'N/A')}")
            else:
                print(f"  ✓ All Label 0 records are before Nov 17, 2025")
            
            # Check for Nov 16 records
            nov_16_start = datetime(2025, 11, 16, 0, 0, 0, tzinfo=timezone.utc)
            nov_16_end = datetime(2025, 11, 16, 23, 59, 59, tzinfo=timezone.utc)
            nov_16_records = label_0_valid[
                (label_0_valid[timestamp_col] >= nov_16_start) & 
                (label_0_valid[timestamp_col] <= nov_16_end)
            ]
            if len(nov_16_records) > 0:
                print(f"  ⚠️  NOTE: {len(nov_16_records)} Label 0 records on Nov 16, 2025 (acceptable)")
        else:
            print(f"  ⚠️  WARNING: No valid timestamps in Label 0 records")
    else:
        print(f"  ⚠️  WARNING: No Label 0 records found")
    
    print()
    
    # Check Label 1 dates
    if len(label_1) > 0:
        label_1_valid = label_1[label_1[timestamp_col].notna()]
        if len(label_1_valid) > 0:
            min_date_1 = label_1_valid[timestamp_col].min()
            max_date_1 = label_1_valid[timestamp_col].max()
            
            print(f"Label 1 date range: {min_date_1} to {max_date_1}")
            
            # Check for violations
            violations_1 = label_1_valid[label_1_valid[timestamp_col] < cutoff_malicious]
            if len(violations_1) > 0:
                print(f"  ✗ ERROR: {len(violations_1)} Label 1 records before Nov 17, 2025!")
                print(f"    These should be Label 0")
                print(f"    Sample violations:")
                for idx, row in violations_1.head(5).iterrows():
                    print(f"      - {row[timestamp_col]}: {row.get('process_name', 'N/A')}")
            else:
                print(f"  ✓ All Label 1 records are on/after Nov 17, 2025")
            
            # Check for Nov 16 records
            nov_16_start = datetime(2025, 11, 16, 0, 0, 0, tzinfo=timezone.utc)
            nov_16_end = datetime(2025, 11, 16, 23, 59, 59, tzinfo=timezone.utc)
            nov_16_records = label_1_valid[
                (label_1_valid[timestamp_col] >= nov_16_start) & 
                (label_1_valid[timestamp_col] <= nov_16_end)
            ]
            if len(nov_16_records) > 0:
                print(f"  ⚠️  WARNING: {len(nov_16_records)} Label 1 records on Nov 16, 2025")
                print(f"    These should be Label 0 (before Nov 17)")
        else:
            print(f"  ⚠️  WARNING: No valid timestamps in Label 1 records")
    else:
        print(f"  ⚠️  WARNING: No Label 1 records found")
    
    print()
    
    # Summary
    total_violations = 0
    if len(label_0) > 0:
        label_0_valid = label_0[label_0[timestamp_col].notna()]
        if len(label_0_valid) > 0:
            violations_0 = label_0_valid[label_0_valid[timestamp_col] >= cutoff_malicious]
            total_violations += len(violations_0)
    
    if len(label_1) > 0:
        label_1_valid = label_1[label_1[timestamp_col].notna()]
        if len(label_1_valid) > 0:
            violations_1 = label_1_valid[label_1_valid[timestamp_col] < cutoff_malicious]
            total_violations += len(violations_1)
    
    if total_violations == 0:
        print("=" * 80)
        print("✓ LABEL SEGREGATION: PASSED")
        print("=" * 80)
        return True
    else:
        print("=" * 80)
        print(f"✗ LABEL SEGREGATION: FAILED - {total_violations} violations found")
        print("=" * 80)
        return False

def verify_data_quality(df):
    """Verify overall data quality."""
    
    print("=" * 80)
    print("DATA QUALITY VERIFICATION")
    print("=" * 80)
    print()
    
    print(f"Total records: {len(df):,}")
    print(f"Columns: {list(df.columns)}")
    print()
    
    # Check for required columns
    required_cols = ['timestamp', 'process_name', 'command_line', 'label']
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        print(f"✗ ERROR: Missing required columns: {missing_cols}")
        return False
    else:
        print(f"✓ All required columns present")
    
    print()
    
    # Check for missing values
    print("Missing values:")
    for col in df.columns:
        missing = df[col].isna().sum()
        pct = (missing / len(df)) * 100
        if missing > 0:
            print(f"  {col}: {missing:,} ({pct:.2f}%)")
        else:
            print(f"  {col}: ✓ No missing values")
    
    print()
    
    # Check for empty command lines
    empty_cmd = (df['command_line'].isna() | (df['command_line'] == '')).sum()
    if empty_cmd > 0:
        print(f"⚠️  WARNING: {empty_cmd:,} records with empty command lines ({(empty_cmd/len(df)*100):.2f}%)")
    else:
        print(f"✓ All records have command lines")
    
    print()
    
    # Check label distribution
    print("Label distribution:")
    label_counts = df['label'].value_counts().sort_index()
    for label, count in label_counts.items():
        pct = (count / len(df)) * 100
        label_name = "Benign" if label == 0 else "Malicious"
        print(f"  Label {label} ({label_name}): {count:,} ({pct:.2f}%)")
    
    if len(label_counts) == 1:
        print("  ✗ ERROR: Only one label present - cannot train binary classifier!")
        return False
    
    print()
    
    # Check data diversity
    print("Data diversity:")
    unique_procs = df['process_name'].nunique()
    unique_parents = df['parent_image'].nunique() if 'parent_image' in df.columns else 0
    unique_users = df['user'].nunique() if 'user' in df.columns else 0
    
    print(f"  Unique processes: {unique_procs:,}")
    if unique_parents > 0:
        print(f"  Unique parent processes: {unique_parents:,}")
    if unique_users > 0:
        print(f"  Unique users: {unique_users:,}")
    
    print()
    
    # Check for duplicates
    exact_duplicates = df.duplicated().sum()
    duplicate_cmds = df['command_line'].duplicated().sum()
    
    print(f"Duplicate analysis:")
    print(f"  Exact duplicate rows: {exact_duplicates:,} ({(exact_duplicates/len(df)*100):.2f}%)")
    print(f"  Duplicate command lines: {duplicate_cmds:,} ({(duplicate_cmds/len(df)*100):.2f}%)")
    
    print()
    
    return True

def main():
    """Main verification function."""
    
    print("=" * 80)
    print("DATA QUALITY AND LABEL VERIFICATION")
    print("=" * 80)
    print()
    
    # Check if combined file exists, otherwise check separate files
    benign_path = Path("data/processed/benign/events.csv")
    malicious_path = Path("data/processed/malicious/events.csv")
    combined_path = Path("data/processed/combined_events.csv")
    
    if combined_path.exists():
        print(f"Loading combined data from: {combined_path}")
        df = pd.read_csv(combined_path)
    elif benign_path.exists() and malicious_path.exists():
        print(f"Loading benign data from: {benign_path}")
        print(f"Loading malicious data from: {malicious_path}")
        df_benign = pd.read_csv(benign_path)
        df_malicious = pd.read_csv(malicious_path)
        df = pd.concat([df_benign, df_malicious], ignore_index=True)
        print(f"Combined: {len(df):,} total records")
    else:
        print("ERROR: Could not find data files!")
        print(f"  Looking for: {benign_path} or {malicious_path} or {combined_path}")
        sys.exit(1)
    
    print()
    
    # Verify data quality
    quality_ok = verify_data_quality(df)
    print()
    
    # Verify label segregation
    segregation_ok = verify_label_segregation(df)
    print()
    
    # Final summary
    print("=" * 80)
    print("VERIFICATION SUMMARY")
    print("=" * 80)
    print()
    
    if quality_ok and segregation_ok:
        print("✅ ALL CHECKS PASSED")
        print("   Data quality is good and labels are correctly segregated")
        sys.exit(0)
    else:
        print("❌ VERIFICATION FAILED")
        if not quality_ok:
            print("   - Data quality issues found")
        if not segregation_ok:
            print("   - Label segregation issues found")
        print()
        print("Please fix the issues before proceeding with training.")
        sys.exit(1)

if __name__ == "__main__":
    main()

