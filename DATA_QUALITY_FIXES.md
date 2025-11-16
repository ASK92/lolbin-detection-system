# Fixing Duplicate Data Issues

## Problem
You have **56.6% duplicate data** which can:
- Bias the model toward common patterns
- Reduce learning from diverse examples
- Waste computational resources
- Lead to overfitting on repeated patterns

## Solutions (Without Collecting More Data)

### Strategy 1: Subsampling Duplicates (Recommended First)

Keep only a fraction of duplicates to reduce bias:

```bash
python scripts/augment_duplicate_data.py \
    --input data/processed/benign/events.csv \
    --output data/processed/benign/events_subsampled.csv \
    --strategy subsample \
    --subsample-ratio 0.3
```

**What it does:**
- Groups events by (process_name, command_line)
- Keeps first occurrence + 30% of duplicates
- Reduces dataset size while maintaining diversity

**Result:** ~40K → ~25K events (removes redundant duplicates)

### Strategy 2: Add Sample Weights (Best for Training)

Give duplicates lower weight during training:

```bash
# First, add weight column
python scripts/augment_duplicate_data.py \
    --input data/processed/benign/events.csv \
    --output data/processed/benign/events_weighted.csv \
    --strategy weight

# Then train with weights
python scripts/train_with_weights.py \
    --data-path data/processed/benign/events_weighted.csv \
    --output models/random_forest_weighted.pkl
```

**What it does:**
- Calculates inverse frequency weights
- Common events get lower weight (0.1-0.5)
- Rare events get higher weight (1.0)
- Model learns from all data but prioritizes unique examples

**Result:** Uses all 40K events but trains smarter

### Strategy 3: Data Augmentation

Create subtle variations of duplicate events:

```bash
python scripts/augment_duplicate_data.py \
    --input data/processed/benign/events.csv \
    --output data/processed/benign/events_augmented.csv \
    --strategy augment
```

**What it does:**
- Adds temporal variations (different timestamps)
- Creates command line variations (whitespace, quotes)
- Adds contextual features
- Keeps all events but makes them more diverse

**Result:** 40K events with more variation

### Strategy 4: Combined Approach (Best Results)

Use all strategies together:

```bash
python scripts/augment_duplicate_data.py \
    --input data/processed/benign/events.csv \
    --output data/processed/benign/events_optimized.csv \
    --strategy all \
    --subsample-ratio 0.3
```

**What it does:**
1. Subsamples duplicates (keeps 30%)
2. Adds noise/variations to remaining duplicates
3. Adds weight column for training
4. Adds temporal and contextual features

**Result:** Optimized dataset ready for training

## Feature Engineering to Differentiate Duplicates

The augmentation script adds these features:

### Temporal Features
- `hour_of_day`: Normalized hour (0-1)
- `day_of_week`: Normalized day (0-1)
- `is_weekend`: Boolean
- `is_business_hours`: Boolean

### Contextual Features
- `process_path_depth`: Number of path separators
- `is_system_path`: Boolean
- `is_user_path`: Boolean
- `parent_is_same`: Parent = process
- `has_unusual_parent`: Parent in temp/download paths

### Sequence Features
- `event_sequence_id`: Position in timeline
- `events_in_last_hour`: Count (if grouped)
- `events_in_last_day`: Count (if grouped)

## Training Recommendations

### Option A: Weighted Training (Recommended)
```bash
# Use all data with weights
python scripts/train_with_weights.py \
    --data-path data/processed/benign/events_weighted.csv
```

**Pros:**
- Uses all available data
- Automatically handles duplicates
- Better for imbalanced data

### Option B: Subsampled Training
```bash
# Use reduced dataset
python scripts/train_models.py \
    --data-path data/processed/benign/events_subsampled.csv \
    --random-forest
```

**Pros:**
- Faster training
- Less memory usage
- Cleaner dataset

### Option C: Hybrid Approach
1. Subsample to reduce size
2. Add weights to remaining data
3. Train with both strategies

## Quick Fix Commands

### Immediate Fix (Subsample)
```bash
python scripts/augment_duplicate_data.py \
    --input data/processed/benign/events.csv \
    --output data/processed/benign/events_clean.csv \
    --strategy subsample \
    --subsample-ratio 0.3
```

### Best Practice (Weighted)
```bash
# Add weights
python scripts/augment_duplicate_data.py \
    --input data/processed/benign/events.csv \
    --output data/processed/benign/events_weighted.csv \
    --strategy weight

# Train with weights (when you have malicious data)
python scripts/train_with_weights.py \
    --data-path data/processed/benign/events_weighted.csv
```

## Expected Results

### Before Fix
- 40,609 events
- Many exact duplicates
- Model may overfit to common patterns

### After Subsampling (30%)
- ~25,000-30,000 events
- Reduced duplicates
- More diverse training set

### After Weighting
- 40,609 events (all kept)
- Weighted training
- Better generalization

## Which Strategy to Use?

**For immediate use:** Subsampling (Strategy 1)
- Quick fix
- Reduces dataset size
- Removes obvious duplicates

**For best results:** Weighted training (Strategy 2)
- Uses all data intelligently
- Better model performance
- Handles class imbalance too

**For maximum diversity:** Combined (Strategy 4)
- Best of all approaches
- Most features
- Optimized dataset

## Next Steps

1. **Run subsampling** to get clean dataset
2. **Add weights** for better training
3. **Collect malicious data** (still needed!)
4. **Train with weights** for best results

