#!/usr/bin/env python3
"""
Brutal Data Quality Analysis
Analyzes processed event data and reports all issues honestly
"""

import pandas as pd
import sys
from pathlib import Path

def analyze_data_quality(csv_path: str):
    """Analyze data quality and report issues."""
    
    print("=" * 60)
    print("BRUTAL DATA QUALITY ANALYSIS")
    print("=" * 60)
    print()
    
    # Load data
    print("Loading data...")
    try:
        df = pd.read_csv(csv_path)
        print(f"✓ Loaded {len(df):,} records")
    except Exception as e:
        print(f"✗ ERROR loading data: {e}")
        return
    
    print()
    print("=" * 60)
    print("1. BASIC STATISTICS")
    print("=" * 60)
    print(f"Total Records: {len(df):,}")
    print(f"Columns: {list(df.columns)}")
    print(f"File Size: {Path(csv_path).stat().st_size / (1024*1024):.2f} MB")
    
    print()
    print("=" * 60)
    print("2. MISSING VALUES")
    print("=" * 60)
    missing = df.isnull().sum()
    for col, count in missing.items():
        pct = (count / len(df)) * 100
        if count > 0:
            print(f"✗ {col}: {count:,} missing ({pct:.2f}%)")
        else:
            print(f"✓ {col}: No missing values")
    
    print()
    print("=" * 60)
    print("3. EMPTY VALUES")
    print("=" * 60)
    empty_cmd = (df['command_line'].isna() | (df['command_line'] == '')).sum()
    empty_proc = (df['process_name'].isna() | (df['process_name'] == '')).sum()
    empty_parent = (df['parent_image'].isna() | (df['parent_image'] == '')).sum()
    
    print(f"Empty command_line: {empty_cmd:,} ({(empty_cmd/len(df)*100):.2f}%)")
    print(f"Empty process_name: {empty_proc:,} ({(empty_proc/len(df)*100):.2f}%)")
    print(f"Empty parent_image: {empty_parent:,} ({(empty_parent/len(df)*100):.2f}%)")
    
    if empty_cmd > 0:
        print("  ⚠️  WARNING: Events without command lines are less useful for ML")
    
    print()
    print("=" * 60)
    print("4. DATA DIVERSITY")
    print("=" * 60)
    unique_procs = df['process_name'].nunique()
    unique_parents = df['parent_image'].nunique()
    unique_users = df['user'].nunique()
    unique_integrity = df['integrity_level'].nunique()
    
    print(f"Unique processes: {unique_procs:,}")
    print(f"Unique parent processes: {unique_parents:,}")
    print(f"Unique users: {unique_users}")
    print(f"Unique integrity levels: {unique_integrity}")
    
    # Check for low diversity
    if unique_procs < 20:
        print("  ⚠️  WARNING: Low process diversity - may not generalize well")
    if unique_parents < 10:
        print("  ⚠️  WARNING: Low parent process diversity")
    
    print()
    print("Top 10 processes:")
    top_procs = df['process_name'].value_counts().head(10)
    for proc, count in top_procs.items():
        pct = (count / len(df)) * 100
        print(f"  {proc[:60]:<60} {count:>8,} ({pct:>5.2f}%)")
    
    # Check for dominance
    top_proc_pct = (top_procs.iloc[0] / len(df)) * 100
    if top_proc_pct > 30:
        print(f"  ⚠️  WARNING: Top process is {top_proc_pct:.1f}% of data - potential bias")
    
    print()
    print("=" * 60)
    print("5. LABEL DISTRIBUTION")
    print("=" * 60)
    label_counts = df['label'].value_counts()
    for label, count in label_counts.items():
        pct = (count / len(df)) * 100
        label_name = "Benign" if label == 0 else "Malicious"
        print(f"Label {label} ({label_name}): {count:,} ({pct:.2f}%)")
    
    if len(label_counts) == 1:
        print("  ⚠️  WARNING: Only one label present - cannot train binary classifier!")
        print("  ⚠️  You need malicious data (label 1) to train the model")
    
    print()
    print("=" * 60)
    print("6. COMMAND LINE QUALITY")
    print("=" * 60)
    df['cmd_len'] = df['command_line'].str.len()
    print(f"Command line length statistics:")
    print(df['cmd_len'].describe())
    
    very_short = (df['cmd_len'] < 10).sum()
    very_long = (df['cmd_len'] > 1000).sum()
    print(f"\nVery short commands (<10 chars): {very_short:,} ({(very_short/len(df)*100):.2f}%)")
    print(f"Very long commands (>1000 chars): {very_long:,} ({(very_long/len(df)*100):.2f}%)")
    
    if very_short > len(df) * 0.1:
        print("  ⚠️  WARNING: Many very short commands - may be less informative")
    
    print()
    print("=" * 60)
    print("7. DUPLICATE ANALYSIS")
    print("=" * 60)
    exact_duplicates = df.duplicated().sum()
    duplicate_cmds = df['command_line'].duplicated().sum()
    
    print(f"Exact duplicate rows: {exact_duplicates:,} ({(exact_duplicates/len(df)*100):.2f}%)")
    print(f"Duplicate command lines: {duplicate_cmds:,} ({(duplicate_cmds/len(df)*100):.2f}%)")
    
    if duplicate_cmds > len(df) * 0.2:
        print("  ⚠️  WARNING: High duplicate rate - may reduce model learning")
    
    print()
    print("=" * 60)
    print("8. TEMPORAL COVERAGE")
    print("=" * 60)
    df['timestamp'] = pd.to_datetime(df['timestamp'], errors='coerce')
    valid_timestamps = df['timestamp'].notna().sum()
    print(f"Valid timestamps: {valid_timestamps:,} ({(valid_timestamps/len(df)*100):.2f}%)")
    
    if valid_timestamps > 0:
        date_range = df['timestamp'].max() - df['timestamp'].min()
        days = date_range.days
        hours = date_range.total_seconds() / 3600
        
        print(f"Date range: {df['timestamp'].min()} to {df['timestamp'].max()}")
        print(f"Time span: {days} days ({hours:.1f} hours)")
        
        if days < 1:
            print("  ⚠️  WARNING: Less than 1 day of data - limited temporal diversity")
        elif days < 3:
            print("  ⚠️  WARNING: Less than 3 days - may not capture daily patterns")
    
    print()
    print("=" * 60)
    print("9. LOLBIN PROCESSES IN BENIGN DATA")
    print("=" * 60)
    lolbins = ['powershell', 'cmd', 'wmic', 'certutil', 'regsvr32', 'mshta', 
               'rundll32', 'cscript', 'wscript', 'bitsadmin', 'schtasks', 
               'sc.exe', 'net.exe', 'netstat', 'tasklist', 'whoami']
    
    found_lolbins = df[df['process_name'].str.lower().str.contains('|'.join(lolbins), case=False, na=False)]
    print(f"Events from LOLBin processes: {len(found_lolbins):,} ({(len(found_lolbins)/len(df)*100):.2f}%)")
    
    if len(found_lolbins) > 0:
        print("\nLOLBin process breakdown:")
        lolbin_procs = found_lolbins['process_name'].value_counts().head(10)
        for proc, count in lolbin_procs.items():
            print(f"  {proc[:60]:<60} {count:>8,}")
        print("\n  ✓ This is GOOD - shows legitimate use of these tools")
        print("  ✓ Model will learn to distinguish legitimate vs malicious usage")
    
    print()
    print("=" * 60)
    print("10. SUSPICIOUS PATTERNS")
    print("=" * 60)
    suspicious_patterns = ['base64', 'encodedcommand', '-enc', '-e ', 'iex', 
                          'downloadstring', 'downloadfile', 'frombase64string',
                          'bypass', 'hidden', 'noprofile']
    
    suspicious = df[df['command_line'].str.contains('|'.join(suspicious_patterns), case=False, na=False)]
    print(f"Events with suspicious patterns: {len(suspicious):,} ({(len(suspicious)/len(df)*100):.2f}%)")
    
    if len(suspicious) > 0:
        print("\n  ⚠️  These might be:")
        print("     - False positives (legitimate automation)")
        print("     - Actual suspicious activity (should be labeled malicious)")
        print("     - Edge cases for the model to learn")
        
        print("\n  Sample suspicious commands:")
        for idx, row in suspicious.head(5).iterrows():
            cmd = row['command_line'][:100] if len(row['command_line']) > 100 else row['command_line']
            print(f"    - {row['process_name']}: {cmd}...")
    
    print()
    print("=" * 60)
    print("11. FEATURE COMPLETENESS FOR ML")
    print("=" * 60)
    
    features_required = {
        'command_line': 'Critical - primary feature source',
        'process_name': 'Critical - process identification',
        'parent_image': 'Important - context information',
        'user': 'Useful - user context',
        'integrity_level': 'Useful - security context'
    }
    
    for feature, importance in features_required.items():
        has_data = df[feature].notna().sum()
        pct = (has_data / len(df)) * 100
        status = "✓" if pct >= 95 else "⚠️" if pct >= 80 else "✗"
        print(f"{status} {feature:20s}: {has_data:>8,} ({pct:>5.2f}%) - {importance}")
    
    print()
    print("=" * 60)
    print("12. BRUTAL HONEST ASSESSMENT")
    print("=" * 60)
    print()
    
    issues = []
    warnings = []
    good_points = []
    
    # Check volume
    if len(df) >= 50000:
        good_points.append(f"✓ Excellent volume: {len(df):,} events")
    elif len(df) >= 10000:
        good_points.append(f"✓ Good volume: {len(df):,} events")
    elif len(df) >= 1000:
        warnings.append(f"⚠️  Moderate volume: {len(df):,} events (recommend 10K+)")
    else:
        issues.append(f"✗ Low volume: {len(df):,} events (need at least 1K)")
    
    # Check labels
    if len(df['label'].unique()) == 1:
        if df['label'].unique()[0] == 0:
            issues.append("✗ CRITICAL: Only benign data (label 0) - cannot train binary classifier!")
            issues.append("✗ You MUST collect malicious data (label 1) before training")
        else:
            issues.append("✗ CRITICAL: Only malicious data - need benign data too!")
    else:
        benign_count = (df['label'] == 0).sum()
        malicious_count = (df['label'] == 1).sum()
        ratio = benign_count / malicious_count if malicious_count > 0 else float('inf')
        
        if ratio > 20:
            warnings.append(f"⚠️  Highly imbalanced: {benign_count:,} benign vs {malicious_count:,} malicious (ratio {ratio:.1f}:1)")
        elif ratio > 10:
            warnings.append(f"⚠️  Imbalanced dataset: {benign_count:,} benign vs {malicious_count:,} malicious")
        else:
            good_points.append(f"✓ Balanced dataset: {benign_count:,} benign, {malicious_count:,} malicious")
    
    # Check command lines
    empty_cmd_pct = (empty_cmd / len(df)) * 100
    if empty_cmd_pct > 5:
        issues.append(f"✗ {empty_cmd_pct:.1f}% events missing command lines - critical feature missing")
    elif empty_cmd_pct > 1:
        warnings.append(f"⚠️  {empty_cmd_pct:.1f}% events missing command lines")
    else:
        good_points.append("✓ All events have command lines")
    
    # Check diversity
    if unique_procs < 10:
        issues.append(f"✗ Very low process diversity: only {unique_procs} unique processes")
    elif unique_procs < 50:
        warnings.append(f"⚠️  Low process diversity: {unique_procs} unique processes")
    else:
        good_points.append(f"✓ Good process diversity: {unique_procs} unique processes")
    
    # Check duplicates
    dup_pct = (duplicate_cmds / len(df)) * 100
    if dup_pct > 30:
        warnings.append(f"⚠️  High duplicate rate: {dup_pct:.1f}% duplicate command lines")
    elif dup_pct < 10:
        good_points.append(f"✓ Low duplicate rate: {dup_pct:.1f}%")
    
    # Check temporal coverage
    if valid_timestamps > 0:
        if days < 1:
            warnings.append("⚠️  Less than 1 day of data - limited temporal patterns")
        elif days >= 3:
            good_points.append(f"✓ Good temporal coverage: {days} days")
    
    # Print summary
    if good_points:
        print("STRENGTHS:")
        for point in good_points:
            print(f"  {point}")
        print()
    
    if warnings:
        print("WARNINGS:")
        for warning in warnings:
            print(f"  {warning}")
        print()
    
    if issues:
        print("CRITICAL ISSUES:")
        for issue in issues:
            print(f"  {issue}")
        print()
    
    # Overall assessment
    print("=" * 60)
    print("OVERALL ASSESSMENT")
    print("=" * 60)
    
    if issues:
        if "CRITICAL" in str(issues):
            print("❌ DATA QUALITY: POOR - Critical issues must be fixed")
            print("   Cannot proceed with training until issues are resolved")
        else:
            print("⚠️  DATA QUALITY: FAIR - Has issues but may be usable")
            print("   Address issues for better model performance")
    elif warnings:
        print("⚠️  DATA QUALITY: GOOD - Minor issues present")
        print("   Data is usable but could be improved")
    else:
        print("✅ DATA QUALITY: EXCELLENT - Ready for training")
        print("   Data meets all quality requirements")
    
    print()
    print("=" * 60)
    print("RECOMMENDATIONS")
    print("=" * 60)
    
    if len(df['label'].unique()) == 1:
        print("1. ✗ COLLECT MALICIOUS DATA - This is the #1 priority")
        print("   - Run LOLBin attack script to generate malicious events")
        print("   - Need at least 1,000 malicious events (5,000+ recommended)")
        print("   - Label them as 1 (malicious)")
    
    if len(df) < 10000:
        print("2. ⚠️  Collect more data if possible")
        print("   - Current: {len(df):,} events")
        print("   - Recommended: 10,000+ events")
    
    if empty_cmd_pct > 1:
        print("3. ⚠️  Investigate missing command lines")
        print("   - Some events may be filtered out during training")
    
    if unique_procs < 50:
        print("4. ⚠️  Increase process diversity")
        print("   - Run more varied activities")
        print("   - Use different applications and tools")
    
    print()
    print("=" * 60)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python analyze_data_quality.py <path_to_csv>")
        sys.exit(1)
    
    csv_path = sys.argv[1]
    analyze_data_quality(csv_path)








