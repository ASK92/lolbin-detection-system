#!/usr/bin/env python3
"""
Data Augmentation for Duplicate Events
Creates variations of duplicate events to increase diversity without collecting new data
"""

import pandas as pd
import numpy as np
import random
import re
from pathlib import Path
from datetime import datetime, timedelta
import argparse

def add_temporal_variation(df: pd.DataFrame) -> pd.DataFrame:
    """Add temporal features to differentiate duplicate events."""
    print("Adding temporal variations...")
    
    df = df.copy()
    df['timestamp'] = pd.to_datetime(df['timestamp'], errors='coerce')
    
    # Add temporal features
    df['hour_of_day'] = df['timestamp'].dt.hour / 24.0  # Normalize to 0-1
    df['day_of_week'] = df['timestamp'].dt.dayofweek / 6.0  # Normalize to 0-1
    df['is_weekend'] = (df['timestamp'].dt.dayofweek >= 5).astype(float)
    df['is_business_hours'] = ((df['timestamp'].dt.hour >= 9) & (df['timestamp'].dt.hour <= 17)).astype(float)
    
    return df

def add_contextual_features(df: pd.DataFrame) -> pd.DataFrame:
    """Add contextual features to differentiate similar events."""
    print("Adding contextual features...")
    
    df = df.copy()
    
    # Add sequence features (position in time series)
    df = df.sort_values('timestamp')
    df['event_sequence_id'] = range(len(df))
    df['events_in_last_hour'] = 0  # Placeholder - would need grouping
    df['events_in_last_day'] = 0   # Placeholder
    
    # Add parent-child relationship features
    df['parent_is_same'] = (df['process_name'] == df['parent_image']).astype(float)
    df['has_unusual_parent'] = df['parent_image'].str.contains('temp|download|appdata', case=False, na=False).astype(float)
    
    # Add path features
    df['process_path_depth'] = df['process_name'].str.count(r'\\').fillna(0)
    df['is_system_path'] = df['process_name'].str.contains('system32|program files|windows', case=False, na=False).astype(float)
    df['is_user_path'] = df['process_name'].str.contains('users|appdata|temp', case=False, na=False).astype(float)
    
    return df

def create_command_variations(command_line: str, num_variations: int = 1) -> list:
    """Create variations of command lines by adding/removing whitespace, quotes, etc."""
    variations = []
    
    if not command_line or len(command_line) < 5:
        return [command_line]
    
    for _ in range(num_variations):
        var = command_line
        
        # Variation 1: Add/remove spaces around operators
        var = re.sub(r'\s*=\s*', '=', var)  # Remove spaces around =
        var = re.sub(r'\s*-\s*', '-', var)  # Remove spaces around -
        
        # Variation 2: Add quotes variation (if not already quoted)
        if random.random() < 0.1 and '"' not in var:
            parts = var.split(' ', 1)
            if len(parts) > 1:
                var = f'{parts[0]} "{parts[1]}"'
        
        # Variation 3: Case variation (randomly change case of some parts)
        if random.random() < 0.2:
            words = var.split()
            if len(words) > 2:
                idx = random.randint(1, min(3, len(words)-1))
                words[idx] = words[idx].upper() if random.random() < 0.5 else words[idx].lower()
                var = ' '.join(words)
        
        variations.append(var)
    
    return variations[:num_variations]

def augment_with_noise(df: pd.DataFrame, noise_factor: float = 0.1) -> pd.DataFrame:
    """Add small random noise to numeric-like features in command lines."""
    print("Adding controlled noise to duplicates...")
    
    df = df.copy()
    
    # Find duplicates
    duplicate_mask = df.duplicated(subset=['process_name', 'command_line'], keep=False)
    duplicates = df[duplicate_mask].copy()
    unique_events = df[~duplicate_mask].copy()
    
    if len(duplicates) == 0:
        return df
    
    print(f"  Found {len(duplicates):,} duplicate events to augment")
    
    # Group duplicates and keep one original, augment others
    augmented = []
    seen_groups = set()
    
    for idx, row in duplicates.iterrows():
        key = (row['process_name'], row['command_line'])
        
        if key not in seen_groups:
            # Keep first occurrence as-is
            augmented.append(row)
            seen_groups.add(key)
        else:
            # Create variation for subsequent occurrences
            new_row = row.copy()
            
            # Add small timestamp variation (within same day)
            if pd.notna(new_row.get('timestamp')):
                try:
                    ts = pd.to_datetime(new_row['timestamp'])
                    # Add random seconds (0-3600 = 1 hour)
                    ts = ts + timedelta(seconds=random.randint(0, 3600))
                    new_row['timestamp'] = ts.isoformat()
                except:
                    pass
            
            # Add command line variation (subtle)
            if random.random() < noise_factor:
                variations = create_command_variations(new_row['command_line'], 1)
                if variations:
                    new_row['command_line'] = variations[0]
            
            augmented.append(new_row)
    
    # Combine unique and augmented
    result = pd.concat([unique_events, pd.DataFrame(augmented)], ignore_index=True)
    
    return result

def subsample_duplicates(df: pd.DataFrame, keep_ratio: float = 0.3) -> pd.DataFrame:
    """Keep only a fraction of duplicates to reduce bias."""
    print(f"Subsampling duplicates (keeping {keep_ratio*100:.0f}%)...")
    
    df = df.copy()
    
    # Identify duplicates
    duplicate_mask = df.duplicated(subset=['process_name', 'command_line'], keep=False)
    duplicates = df[duplicate_mask]
    unique_events = df[~duplicate_mask]
    
    if len(duplicates) == 0:
        return df
    
    print(f"  Found {len(duplicates):,} duplicate events")
    
    # Group by process + command
    groups = duplicates.groupby(['process_name', 'command_line'])
    
    # Keep first occurrence + random sample of rest
    sampled_duplicates = []
    for (proc, cmd), group in groups:
        # Always keep first
        sampled_duplicates.append(group.iloc[0].to_dict())
        
        # Randomly sample rest
        if len(group) > 1:
            n_keep = max(1, int((len(group) - 1) * keep_ratio))
            sampled = group.iloc[1:].sample(n=min(n_keep, len(group) - 1), random_state=42)
            sampled_duplicates.extend(sampled.to_dict('records'))
    
    # Combine
    if len(sampled_duplicates) > 0:
        sampled_df = pd.DataFrame(sampled_duplicates)
        result = pd.concat([unique_events, sampled_df], ignore_index=True)
    else:
        result = unique_events
    
    print(f"  Reduced duplicates from {len(duplicates):,} to {len(sampled_duplicates):,}")
    
    return result

def add_weight_column(df: pd.DataFrame) -> pd.DataFrame:
    """Add weight column - duplicates get lower weight."""
    print("Adding weight column for training...")
    
    df = df.copy()
    
    # Count occurrences
    df['occurrence_count'] = df.groupby(['process_name', 'command_line'])['process_name'].transform('count')
    
    # Inverse frequency weighting (more common = lower weight)
    df['weight'] = 1.0 / df['occurrence_count']
    
    # Normalize weights
    df['weight'] = df['weight'] / df['weight'].max()
    
    print(f"  Weight range: {df['weight'].min():.4f} to {df['weight'].max():.4f}")
    print(f"  Average weight: {df['weight'].mean():.4f}")
    
    return df

def main():
    parser = argparse.ArgumentParser(description='Augment duplicate data')
    parser.add_argument('--input', type=str, required=True, help='Input CSV file')
    parser.add_argument('--output', type=str, required=True, help='Output CSV file')
    parser.add_argument('--strategy', choices=['augment', 'subsample', 'weight', 'all'], 
                       default='all', help='Strategy to use')
    parser.add_argument('--subsample-ratio', type=float, default=0.3, 
                       help='Ratio to keep when subsampling (default: 0.3)')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Data Augmentation for Duplicate Events")
    print("=" * 60)
    print()
    
    # Load data
    print(f"Loading data from {args.input}...")
    df = pd.read_csv(args.input)
    print(f"  Loaded {len(df):,} events")
    
    original_count = len(df)
    
    # Apply strategies
    if args.strategy in ['subsample', 'all']:
        df = subsample_duplicates(df, keep_ratio=args.subsample_ratio)
        print(f"  After subsampling: {len(df):,} events")
    
    if args.strategy in ['augment', 'all']:
        df = augment_with_noise(df)
        print(f"  After augmentation: {len(df):,} events")
    
    if args.strategy in ['weight', 'all']:
        df = add_weight_column(df)
    
    # Always add temporal and contextual features
    df = add_temporal_variation(df)
    df = add_contextual_features(df)
    
    # Save
    print()
    print(f"Saving to {args.output}...")
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(args.output, index=False)
    
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Original events: {original_count:,}")
    print(f"Final events: {len(df):,}")
    print(f"Reduction: {original_count - len(df):,} events ({(1 - len(df)/original_count)*100:.1f}%)")
    print()
    print("Strategies applied:")
    if args.strategy in ['subsample', 'all']:
        print("  ✓ Subsampling duplicates")
    if args.strategy in ['augment', 'all']:
        print("  ✓ Adding noise variations")
    if args.strategy in ['weight', 'all']:
        print("  ✓ Adding weight column (use in training)")
    print("  ✓ Temporal features added")
    print("  ✓ Contextual features added")
    print()
    print("=" * 60)

if __name__ == "__main__":
    main()

