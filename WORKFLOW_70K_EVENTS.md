# Complete Workflow for 70K Events

Step-by-step guide for when you reach ~70K events and are ready to train models.

## Current Status

- ✅ Benign data collection: Running
- ✅ Data processing scripts: Ready
- ✅ Strategy 3 preparation: Ready
- ⏳ Target: ~70K total events
- ⏳ Malicious data: Need to collect

## Phase 1: Data Collection (Current)

### Benign Data Collection
```powershell
# Already running
.\run_benign_collection.ps1

# Monitor progress
.\monitor_benign_collection.ps1 -Continuous
```

**Target:** 50,000-60,000 benign events

### Export Sysmon Logs Periodically
```powershell
# Export every 24 hours (automated)
.\export_sysmon_logs.ps1 -Continuous -IntervalHours 24
```

## Phase 2: Process Benign Data (When Ready)

### Step 1: Process EVTX Files
```bash
python scripts/process_evtx_files.py \
    --input-dir data/Sysmon_logs \
    --output-dir data/processed/benign \
    --label 0 \
    --format csv
```

### Step 2: Prepare with Strategy 3
```bash
python scripts/prepare_training_pipeline.py \
    --benign-input data/processed/benign/events.csv \
    --benign-output data/processed/benign/events_prepared.csv \
    --step benign \
    --subsample-ratio 0.3
```

**What this does:**
- Removes exact duplicates
- Subsamples duplicate events (keeps 30%)
- Adds controlled variations
- Adds sample weights
- Adds temporal/contextual features

**Expected result:** ~20,000-30,000 prepared benign events

## Phase 3: Collect Malicious Data

### Step 1: Create LOLBin Attack Script
(We'll create this next - `run_lolbin_attacks.ps1`)

### Step 2: Run Attacks
```powershell
.\run_lolbin_attacks.ps1
```

**Target:** 5,000-10,000 malicious events

### Step 3: Export Malicious Logs
```powershell
# Export after attack session
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd').evtx"
```

### Step 4: Process Malicious Data
```bash
python scripts/process_evtx_files.py \
    --input-dir data/raw/malicious \
    --output-dir data/processed/malicious \
    --label 1 \
    --format csv
```

### Step 5: Prepare Malicious Data
```bash
python scripts/prepare_training_pipeline.py \
    --malicious-input data/processed/malicious/events.csv \
    --malicious-output data/processed/malicious/events_prepared.csv \
    --step malicious
```

## Phase 4: Combine and Train

### Step 1: Combine Datasets
```bash
python scripts/prepare_training_pipeline.py \
    --benign-input data/processed/benign/events_prepared.csv \
    --malicious-input data/processed/malicious/events_prepared.csv \
    --combined-output data/processed/training_data.csv \
    --step combine
```

**Expected result:** ~25,000-40,000 combined events ready for training

### Step 2: Train Random Forest
```bash
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --random-forest \
    --test-size 0.2
```

### Step 3: Train LSTM (Optional)
```bash
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --lstm \
    --test-size 0.2
```

## Quick Reference: Complete Pipeline

### One-Command Workflow (When All Data Ready)

```bash
# Prepare everything and combine
python scripts/prepare_training_pipeline.py \
    --benign-input data/processed/benign/events.csv \
    --malicious-input data/processed/malicious/events.csv \
    --combined-output data/processed/training_data.csv \
    --step all \
    --subsample-ratio 0.3

# Train models
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --random-forest \
    --lstm
```

## Data Quality Targets

### Minimum Requirements
- ✅ 1,000+ total events
- ✅ Both benign and malicious labels
- ✅ At least 200 malicious events

### Recommended (Your Target)
- ✅ 10,000+ total events
- ✅ 5,000+ benign events
- ✅ 1,000+ malicious events
- ✅ Balanced ratio (5:1 to 10:1)

### Optimal (70K Goal)
- ✅ 50,000+ benign events
- ✅ 5,000-10,000 malicious events
- ✅ Good temporal coverage (5+ days)
- ✅ High process diversity (100+ unique processes)

## Progress Tracking

### Current Progress
- Benign events collected: ~37K (from logs)
- Benign events processed: 40,609 (after dedup)
- Malicious events: 0 (need to collect)
- **Total: 40,609 events**

### Target Progress (70K)
- Benign events: 50,000-60,000
- Malicious events: 5,000-10,000
- **Total: 55,000-70,000 events**

### After Strategy 3 Preparation
- Benign (prepared): ~20,000-30,000
- Malicious (prepared): ~5,000-10,000
- **Total (prepared): ~25,000-40,000 events**

## Checklist

### Data Collection
- [ ] Continue benign collection until 50K+ events
- [ ] Export Sysmon logs periodically
- [ ] Monitor collection health
- [ ] Fix Sysmon log size (if not done)

### Data Processing
- [ ] Process all benign EVTX files
- [ ] Remove duplicates from benign data
- [ ] Prepare benign data (Strategy 3)
- [ ] Collect malicious data (LOLBin attacks)
- [ ] Process malicious EVTX files
- [ ] Prepare malicious data

### Training Preparation
- [ ] Combine benign and malicious datasets
- [ ] Verify data quality
- [ ] Check label distribution
- [ ] Verify feature extraction

### Model Training
- [ ] Train Random Forest model
- [ ] Evaluate model performance
- [ ] Train LSTM model (optional)
- [ ] Compare model results
- [ ] Deploy best model

## Next Steps

1. **Continue benign collection** - Let it run until you have 50K+ events
2. **Create LOLBin attack script** - We'll do this next
3. **Collect malicious data** - Run attacks to generate malicious events
4. **Run complete pipeline** - Use the master script to prepare everything
5. **Train models** - Start training once data is ready

## Files Created

- ✅ `scripts/prepare_training_pipeline.py` - Master preparation script
- ✅ `scripts/augment_duplicate_data.py` - Strategy 3 implementation
- ✅ `scripts/train_with_weights.py` - Weighted training
- ✅ `WORKFLOW_70K_EVENTS.md` - This guide

## Ready to Go!

When you reach 70K events, just run:

```bash
python scripts/prepare_training_pipeline.py --step all
```

Everything is automated and ready! 🚀

