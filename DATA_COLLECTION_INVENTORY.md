# Data Collection Inventory

Complete list of all data collected through the `data_collection` folder that is needed for ML model training.

## 📋 Overview

The data collection process generates several types of files and logs. However, **only the processed EVTX files (converted to CSV) are directly used for training**. The other files are for monitoring, verification, and debugging.

---

## 🎯 **PRIMARY DATA FOR TRAINING** (Required)

### 1. **Sysmon Event Logs (EVTX Files)** ⭐ **CRITICAL**

**Location:**
- `data/Master_sysmon/*.evtx` (consolidated logs)
- `data/Sysmon_logs/*.evtx` (periodic exports)
- Windows Event Log: `Microsoft-Windows-Sysmon/Operational`

**What it contains:**
- **Event ID 1** (Process Creation) - **PRIMARY SOURCE**
  - `command_line` - Full command with arguments ⭐
  - `process_name` (Image) - Executable path ⭐
  - `parent_image` - Parent process ⭐
  - `user` - User context ⭐
  - `integrity_level` - Security context ⭐
  - `timestamp` - Event time ⭐
- Event ID 7 (Image Load)
- Event ID 10 (Process Access)
- Event ID 11 (File Creation)
- Event ID 13 (Registry)
- Event ID 22 (DNS Query)

**How it's collected:**
- Automatically by Sysmon service (runs in background)
- Exported periodically using `export_sysmon_logs.ps1`
- Exported manually using `export_latest_sysmon.ps1`

**Used for training:** ✅ **YES** - This is the ONLY source of training data

**Processing:**
```bash
# Process EVTX files to CSV
python scripts/process_evtx_files_by_date.py \
    --input-dir "data/Master_sysmon" \
    --benign-output "data/processed/benign/events.csv" \
    --malicious-output "data/processed/malicious/events.csv"
```

---

## 📊 **SECONDARY DATA** (For Monitoring & Verification)

### 2. **Activity Logs (JSON)**

**Location:** `data_collection/automation/activity_log_*.json`

**What it contains:**
- Activity records with timestamps
- Activity type (Browse Web, File Operations, etc.)
- Activity count
- Duration information

**Example structure:**
```json
{
  "start_time": "2025-11-16T10:00:00",
  "end_time": "2025-11-16T22:00:00",
  "total_activities": 4005,
  "duration_hours": 12,
  "activities": [
    {
      "timestamp": "2025-11-16T10:00:15",
      "activity": "Browse Web",
      "activity_number": 1
    }
  ]
}
```

**Used for training:** ❌ **NO** - Only for verification and monitoring

**Purpose:**
- Verify collection is running
- Track activity counts
- Debug collection issues

---

### 3. **Automation Log (Text)**

**Location:** `data_collection/automation/user_behavior.log`

**What it contains:**
- Real-time log of all activities
- Errors and warnings
- Process status

**Used for training:** ❌ **NO** - Only for debugging

**Purpose:**
- Troubleshoot collection issues
- Monitor script execution
- Track errors

---

### 4. **Status File (JSON)**

**Location:** `data_collection/automation/collection_status.json`

**What it contains:**
```json
{
  "status": "Running",
  "cycle": 1,
  "total_activities": 0,
  "last_activity": "",
  "start_time": "2025-11-16 10:00:00",
  "activity_interval": 60,
  "cycle_duration": 24
}
```

**Used for training:** ❌ **NO** - Only for monitoring

**Purpose:**
- Check if collection is running
- Monitor progress
- Track cycle information

---

### 5. **Process ID File**

**Location:** `data_collection/automation/collection.pid`

**What it contains:**
- Process ID of the running collection script

**Used for training:** ❌ **NO** - Only for process management

---

### 6. **PowerShell Event Logs**

**Location:** Windows Event Log: `Microsoft-Windows-PowerShell/Operational`

**What it contains:**
- Event ID 4104 (Script Block Logging)
- PowerShell command execution logs

**Used for training:** ❌ **NO** - Not currently used (future enhancement)

**Purpose:**
- Additional context for PowerShell activities
- Could be used for advanced features later

---

## 🔄 **DATA FLOW TO TRAINING**

```
┌─────────────────────────────────────────────────────────────┐
│  DATA COLLECTION (data_collection/automation/)              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. User Behavior Simulator                                 │
│     → Generates activities                                  │
│     → Creates activity_log_*.json                           │
│     → Writes user_behavior.log                              │
│                                                              │
│  2. Sysmon Service (Windows)                                │
│     → Monitors all process creation                         │
│     → Logs to Event Log                                     │
│     → Captures: command_line, process_name, etc.            │
│                                                              │
│  3. Export Scripts                                          │
│     → export_sysmon_logs.ps1                                │
│     → export_latest_sysmon.ps1                              │
│     → Exports EVTX files                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  DATA PROCESSING (scripts/)                                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. process_evtx_files_by_date.py                           │
│     → Reads EVTX files                                      │
│     → Extracts Event ID 1 (Process Creation)                │
│     → Labels by timestamp                                   │
│     → Outputs: events.csv                                   │
│                                                              │
│  2. augment_duplicate_data.py (Strategy 3)                  │
│     → Removes duplicates                                    │
│     → Adds variations                                       │
│     → Adds weights                                          │
│     → Adds features                                         │
│     → Outputs: events_optimized.csv                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  MODEL TRAINING (scripts/train_models.py)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Input: events_optimized.csv                                │
│  Required columns:                                          │
│    - command_line ⭐                                         │
│    - process_name ⭐                                         │
│    - parent_image ⭐                                         │
│    - user ⭐                                                 │
│    - integrity_level ⭐                                      │
│    - timestamp                                               │
│    - label (0=benign, 1=malicious) ⭐                        │
│                                                              │
│  Output: Trained models                                     │
│    - models/random_forest_model.pkl                         │
│    - models/lstm_model.pth                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ **REQUIRED FOR TRAINING**

### Minimum Requirements:

1. **EVTX Files** (from Sysmon)
   - ✅ Benign events: Events until Nov 16, 2025 22:00:00
   - ✅ Malicious events: Events from Nov 16, 2025 22:01:00 to Nov 17, 2025 23:59:59
   - ✅ More benign events: Events from Nov 18, 2025 onwards

2. **Processed CSV Files**
   - ✅ `data/processed/benign/events_optimized.csv`
   - ✅ `data/processed/malicious/events_optimized.csv`

3. **Required CSV Columns:**
   - `command_line` - Full command with arguments
   - `process_name` - Executable path
   - `parent_image` - Parent process
   - `user` - User context
   - `integrity_level` - Security context
   - `timestamp` - Event time
   - `label` - 0 (benign) or 1 (malicious)

---

## 📁 **FILE LOCATIONS SUMMARY**

### Collection Files (Not used directly for training):
```
data_collection/automation/
├── activity_log_*.json          ❌ Monitoring only
├── user_behavior.log            ❌ Debugging only
├── collection_status.json       ❌ Status only
├── collection.pid               ❌ Process management
└── logs/                        ❌ Debugging only
```

### Training Data Files (Used for training):
```
data/
├── Master_sysmon/
│   └── *.evtx                   ✅ Source data
├── Sysmon_logs/
│   └── *.evtx                   ✅ Source data
└── processed/
    ├── benign/
    │   ├── events.csv           ✅ Processed data
    │   └── events_optimized.csv ✅ Training-ready data
    └── malicious/
        ├── events.csv           ✅ Processed data
        └── events_optimized.csv ✅ Training-ready data
```

---

## 🎯 **QUICK CHECKLIST**

Before training, ensure you have:

- [ ] **EVTX files** in `data/Master_sysmon/` or `data/Sysmon_logs/`
- [ ] **Processed CSV files** in `data/processed/benign/` and `data/processed/malicious/`
- [ ] **Optimized CSV files** (after Strategy 3) in `data/processed/*/events_optimized.csv`
- [ ] **Both labels present**: Benign (0) and Malicious (1)
- [ ] **Minimum data**: At least 1,000 events per class (5,000+ recommended)

---

## 📝 **NOTES**

1. **Only EVTX → CSV conversion is needed for training**
   - Activity logs, automation logs, and status files are NOT used
   - They're only for monitoring and debugging

2. **Sysmon is the single source of truth**
   - All training data comes from Sysmon Event ID 1
   - Other event IDs (7, 10, 11, 13, 22) are not currently used

3. **Data collection scripts generate activities**
   - But the actual training data comes from Sysmon monitoring those activities
   - The scripts don't directly create training data

4. **Labeling is done by timestamp**
   - Events before Nov 16, 2025 22:00:00 = Benign (0)
   - Events Nov 16, 2025 22:01:00 to Nov 17, 2025 23:59:59 = Malicious (1)
   - Events after Nov 17, 2025 23:59:59 = Benign (0)

---

## 🔍 **VERIFICATION**

To verify you have everything needed for training:

```bash
# Check EVTX files
ls data/Master_sysmon/*.evtx
ls data/Sysmon_logs/*.evtx

# Check processed files
ls data/processed/benign/events_optimized.csv
ls data/processed/malicious/events_optimized.csv

# Verify data quality
python scripts/analyze_data_quality.py data/processed/benign/events_optimized.csv
python scripts/analyze_data_quality.py data/processed/malicious/events_optimized.csv
```

---

## 📚 **RELATED DOCUMENTATION**

- `TRAINING_GUIDE.md` - Complete training workflow
- `WORKFLOW_70K_EVENTS.md` - Data collection workflow
- `data_collection/automation/BENIGN_COLLECTION_GUIDE.md` - Collection guide
- `data_collection/automation/MALICIOUS_ATTACK_GENERATION.md` - Attack generation

