#!/usr/bin/env python3
"""Quick summary of optimized datasets"""

import pandas as pd

print("="*60)
print("STRATEGY 3 PROCESSING SUMMARY")
print("="*60)

b = pd.read_csv('data/processed/benign/events_optimized.csv')
m = pd.read_csv('data/processed/malicious/events_optimized.csv')

print(f'\nBENIGN DATA:')
print(f'  Original: 47,116 events')
print(f'  Optimized: {len(b):,} events')
print(f'  Reduction: {47116-len(b):,} events ({(1-len(b)/47116)*100:.1f}%)')
print(f'  Unique processes: {b["process_name"].nunique()}')
print(f'  Has weight column: {"weight" in b.columns}')
print(f'  Average weight: {b["weight"].mean():.4f}')

print(f'\nMALICIOUS DATA:')
print(f'  Original: 14,039 events')
print(f'  Optimized: {len(m):,} events')
print(f'  Reduction: {14039-len(m):,} events ({(1-len(m)/14039)*100:.1f}%)')
print(f'  Unique processes: {m["process_name"].nunique()}')
print(f'  Has weight column: {"weight" in m.columns}')
print(f'  Average weight: {m["weight"].mean():.4f}')

print(f'\nCOMBINED:')
print(f'  Total events: {len(b)+len(m):,}')
print(f'  Benign: {len(b):,} ({len(b)/(len(b)+len(m))*100:.1f}%)')
print(f'  Malicious: {len(m):,} ({len(m)/(len(b)+len(m))*100:.1f}%)')
print(f'  Ratio: {len(b)/len(m):.2f}:1')

print('\nFEATURES ADDED:')
print('  ✓ Temporal features (hour_of_day, day_of_week, is_weekend, is_business_hours)')
print('  ✓ Contextual features (parent_is_same, has_unusual_parent, path_depth, etc.)')
print('  ✓ Weight column for training')
print('  ✓ Occurrence count')

print('\n' + "="*60)
print("READY FOR TRAINING!")
print("="*60)



