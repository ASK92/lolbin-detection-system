#!/usr/bin/env python3
"""
Master Pipeline: Prepare Data for Training
Orchestrates the complete data preparation workflow using Strategy 3
"""

import pandas as pd
import numpy as np
from pathlib import Path
import sys
import argparse
from datetime import datetime

# Import augmentation functions
sys.path.insert(0, str(Path(__file__).parent))
from augment_duplicate_data import (
    subsample_duplicates,
    augment_with_noise,
    add_weight_column,
    add_temporal_variation,
    add_contextual_features
)

def check_data_requirements(df: pd.DataFrame) -> dict:
    """Check if data meets requirements for training."""
    requirements = {
        'min_events': 1000,
        'recommended_events': 10000,
        'optimal_events': 50000,
        'needs_malicious': True
    }
    
    status = {
        'total_events': len(df),
        'benign_events': (df['label'] == 0).sum() if 'label' in df.columns else len(df),
        'malicious_events': (df['label'] == 1).sum() if 'label' in df.columns else 0,
        'meets_minimum': False,
        'meets_recommended': False,
        'has_malicious': False,
        'ready_for_training': False
    }
    
    status['meets_minimum'] = status['total_events'] >= requirements['min_events']
    status['meets_recommended'] = status['total_events'] >= requirements['recommended_events']
    status['has_malicious'] = status['malicious_events'] > 0
    status['ready_for_training'] = status['meets_minimum'] and status['has_malicious']
    
    return status, requirements

def prepare_benign_data(input_path: str, output_path: str, subsample_ratio: float = 0.3):
    """Prepare benign data using Strategy 3."""
    print("=" * 60)
    print("PREPARING BENIGN DATA (Strategy 3)")
    print("=" * 60)
    print()
    
    # Load data
    print(f"Loading benign data from {input_path}...")
    df = pd.read_csv(input_path)
    print(f"  Loaded {len(df):,} events")
    
    original_count = len(df)
    
    # Step 1: Remove exact duplicates
    print("\n[Step 1/5] Removing exact duplicates...")
    df = df.drop_duplicates()
    print(f"  Removed {original_count - len(df):,} exact duplicates")
    print(f"  Remaining: {len(df):,} events")
    
    # Step 2: Subsample duplicates
    print("\n[Step 2/5] Subsampling duplicate events...")
    df = subsample_duplicates(df, keep_ratio=subsample_ratio)
    print(f"  After subsampling: {len(df):,} events")
    
    # Step 3: Add noise variations
    print("\n[Step 3/5] Adding controlled variations...")
    df = augment_with_noise(df, noise_factor=0.1)
    print(f"  After augmentation: {len(df):,} events")
    
    # Step 4: Add weights
    print("\n[Step 4/5] Adding sample weights...")
    df = add_weight_column(df)
    
    # Step 5: Add features
    print("\n[Step 5/5] Adding temporal and contextual features...")
    df = add_temporal_variation(df)
    df = add_contextual_features(df)
    
    # Save
    print(f"\nSaving prepared data to {output_path}...")
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False)
    
    print()
    print("=" * 60)
    print("BENIGN DATA PREPARATION COMPLETE")
    print("=" * 60)
    print(f"Original events: {original_count:,}")
    print(f"Final events: {len(df):,}")
    print(f"Reduction: {original_count - len(df):,} events ({(1 - len(df)/original_count)*100:.1f}%)")
    print(f"Output: {output_path}")
    print()
    
    return df

def prepare_malicious_data(input_path: str, output_path: str):
    """Prepare malicious data (similar process but keep all for now)."""
    print("=" * 60)
    print("PREPARING MALICIOUS DATA")
    print("=" * 60)
    print()
    
    # Load data
    print(f"Loading malicious data from {input_path}...")
    df = pd.read_csv(input_path)
    print(f"  Loaded {len(df):,} events")
    
    original_count = len(df)
    
    # Remove exact duplicates only (keep all malicious examples)
    print("\nRemoving exact duplicates...")
    df = df.drop_duplicates()
    print(f"  Removed {original_count - len(df):,} exact duplicates")
    print(f"  Remaining: {len(df):,} events")
    
    # Add features
    print("\nAdding temporal and contextual features...")
    df = add_temporal_variation(df)
    df = add_contextual_features(df)
    
    # Add weights (malicious events are rarer, so higher weight)
    print("\nAdding sample weights...")
    df['occurrence_count'] = 1  # All unique for now
    df['weight'] = 1.0  # Full weight for malicious
    
    # Save
    print(f"\nSaving prepared data to {output_path}...")
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False)
    
    print()
    print("=" * 60)
    print("MALICIOUS DATA PREPARATION COMPLETE")
    print("=" * 60)
    print(f"Original events: {original_count:,}")
    print(f"Final events: {len(df):,}")
    print(f"Output: {output_path}")
    print()
    
    return df

def combine_datasets(benign_path: str, malicious_path: str, output_path: str):
    """Combine benign and malicious datasets."""
    print("=" * 60)
    print("COMBINING DATASETS")
    print("=" * 60)
    print()
    
    # Load both datasets
    print("Loading datasets...")
    df_benign = pd.read_csv(benign_path)
    df_malicious = pd.read_csv(malicious_path)
    
    print(f"  Benign: {len(df_benign):,} events")
    print(f"  Malicious: {len(df_malicious):,} events")
    
    # Combine
    print("\nCombining datasets...")
    df_combined = pd.concat([df_benign, df_malicious], ignore_index=True)
    
    # Shuffle
    print("Shuffling combined dataset...")
    df_combined = df_combined.sample(frac=1, random_state=42).reset_index(drop=True)
    
    # Save
    print(f"\nSaving combined dataset to {output_path}...")
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    df_combined.to_csv(output_path, index=False)
    
    # Statistics
    benign_count = (df_combined['label'] == 0).sum()
    malicious_count = (df_combined['label'] == 1).sum()
    ratio = benign_count / malicious_count if malicious_count > 0 else float('inf')
    
    print()
    print("=" * 60)
    print("DATASET COMBINATION COMPLETE")
    print("=" * 60)
    print(f"Total events: {len(df_combined):,}")
    print(f"  Benign (0): {benign_count:,} ({(benign_count/len(df_combined)*100):.1f}%)")
    print(f"  Malicious (1): {malicious_count:,} ({(malicious_count/len(df_combined)*100):.1f}%)")
    print(f"  Ratio: {ratio:.1f}:1")
    print(f"Output: {output_path}")
    print()
    
    if ratio > 20:
        print("⚠️  WARNING: Highly imbalanced dataset (ratio > 20:1)")
        print("   Consider collecting more malicious data or using class weights")
    elif ratio > 10:
        print("⚠️  WARNING: Imbalanced dataset (ratio > 10:1)")
        print("   Model will use class weights to handle imbalance")
    else:
        print("✓ Dataset is reasonably balanced")
    
    return df_combined

def main():
    parser = argparse.ArgumentParser(description='Prepare data for training (Strategy 3)')
    parser.add_argument('--benign-input', type=str, help='Input benign CSV file')
    parser.add_argument('--malicious-input', type=str, help='Input malicious CSV file')
    parser.add_argument('--benign-output', type=str, default='data/processed/benign/events_prepared.csv',
                       help='Output path for prepared benign data')
    parser.add_argument('--malicious-output', type=str, default='data/processed/malicious/events_prepared.csv',
                       help='Output path for prepared malicious data')
    parser.add_argument('--combined-output', type=str, default='data/processed/training_data.csv',
                       help='Output path for combined training data')
    parser.add_argument('--subsample-ratio', type=float, default=0.3,
                       help='Ratio to keep when subsampling duplicates (default: 0.3)')
    parser.add_argument('--step', choices=['benign', 'malicious', 'combine', 'all'], default='all',
                       help='Which step to run')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("TRAINING DATA PREPARATION PIPELINE")
    print("Strategy 3: Combined Approach")
    print("=" * 60)
    print()
    
    if args.step in ['benign', 'all']:
        if not args.benign_input:
            print("ERROR: --benign-input required for benign preparation")
            return
        prepare_benign_data(args.benign_input, args.benign_output, args.subsample_ratio)
    
    if args.step in ['malicious', 'all']:
        if not args.malicious_input:
            print("WARNING: --malicious-input not provided, skipping malicious preparation")
        else:
            prepare_malicious_data(args.malicious_input, args.malicious_output)
    
    if args.step in ['combine', 'all']:
        benign_path = args.benign_output
        malicious_path = args.malicious_output
        
        if not Path(benign_path).exists():
            print(f"ERROR: Benign data not found at {benign_path}")
            return
        
        if not Path(malicious_path).exists():
            print(f"WARNING: Malicious data not found at {malicious_path}")
            print("  Cannot combine datasets yet. Prepare malicious data first.")
            return
        
        df_combined = combine_datasets(benign_path, malicious_path, args.combined_output)
        
        # Final check
        status, requirements = check_data_requirements(df_combined)
        
        print()
        print("=" * 60)
        print("FINAL DATA STATUS")
        print("=" * 60)
        print(f"Total Events: {status['total_events']:,}")
        print(f"  Benign: {status['benign_events']:,}")
        print(f"  Malicious: {status['malicious_events']:,}")
        print()
        
        if status['ready_for_training']:
            print("✅ DATA READY FOR TRAINING!")
            print()
            print("Next step: Train models")
            print(f"  python scripts/train_models.py --data-path {args.combined_output} --random-forest")
        else:
            print("⚠️  DATA NOT READY FOR TRAINING")
            if not status['has_malicious']:
                print("  ✗ Missing malicious data (label 1)")
            if not status['meets_minimum']:
                print(f"  ✗ Insufficient data (need {requirements['min_events']:,}+ events)")
    
    print()
    print("=" * 60)
    print("PIPELINE COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()










