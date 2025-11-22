# Enhanced Data Collection Guide

## What's New?

The enhanced collection script (`run_benign_collection.ps1`) now uses an **Enhanced User Behavior Simulator** that provides significantly better event diversity.

## Key Improvements

### 1. **Time-Based Activity Patterns**
- **Business Hours (9 AM - 5 PM)**: More frequent activities, more office apps and file operations
- **Evening (5 PM - 10 PM)**: Moderate activity levels
- **Night (10 PM - 6 AM)**: Less frequent, more background tasks
- **Morning (6 AM - 9 AM)**: Moderate activity levels

### 2. **New Activity Types**

#### LOLBin Commands (Legitimate Usage)
- `certutil` - Certificate management
- `wmic` - Windows Management Instrumentation
- `regsvr32` - DLL registration (query only)
- `bitsadmin` - Background Intelligent Transfer Service
- `schtasks` - Task Scheduler queries
- `sc` - Service Control queries
- `rundll32` - DLL execution (help only)
- `mshta` - HTML Application (help only)

#### Network Operations
- `ping` - Network connectivity tests
- `nslookup` - DNS lookups
- `net` commands - Network configuration queries
- `curl` - HTTP requests

#### Registry Operations
- `reg query` - Registry key queries
- `reg export` - Registry exports (small keys, cleaned up)

### 3. **Enhanced Existing Activities**

#### System Commands
- More diverse command variations
- Additional PowerShell commands
- Extended parameter usage

#### File Operations
- Added `move` and `delete` operations
- More file types and locations
- Better cleanup

#### PowerShell Activity
- 12+ different PowerShell commands
- More complex queries
- Better formatting options

### 4. **Dynamic Intervals**
- Intervals vary based on time of day
- Business hours: 30% faster (more activities)
- Night hours: 50% slower (fewer activities)
- Random variation within ranges

## Usage

### Standard Usage (Enhanced by Default)
```powershell
.\run_benign_collection.ps1
```

### With Custom Parameters
```powershell
.\run_benign_collection.ps1 -ActivityInterval 45 -CycleDuration 12
```

### Monitor Collection
```powershell
.\monitor_benign_collection.ps1 -Continuous
```

## Expected Event Diversity

With the enhanced simulator, you should see:

### Process Diversity
- **Before**: ~50-100 unique processes
- **After**: ~150-250 unique processes

### Command Line Diversity
- **Before**: ~2,000-3,000 unique command lines
- **After**: ~5,000-8,000 unique command lines

### Event Types
- More network-related events
- More registry access events
- More LOLBin tool usage (legitimate)
- Better temporal distribution

## Activity Distribution

### Base Weights (Adjusted by Time)
- Browse Web: 20%
- File Operations: 18%
- Office Apps: 12%
- System Commands: 12%
- PowerShell: 10%
- **LOLBin Commands: 8%** (NEW)
- **Network Operations: 8%** (NEW)
- **Registry Operations: 5%** (NEW)
- Read Documents: 5%
- Background Tasks: 2%

### Time-Based Adjustments
- **Business Hours**: +50% Office Apps, File Ops, Network
- **Night**: +100% Background Tasks, -30% Office Apps/Web

## Benefits for Training

1. **Better LOLBin Coverage**: Legitimate usage patterns help model distinguish benign from malicious
2. **Temporal Patterns**: Time-based features improve detection
3. **Network Diversity**: More network events for better network-based detection
4. **Registry Patterns**: Registry access patterns improve detection
5. **Command Variations**: More command variations reduce overfitting

## Monitoring

Check event diversity:
```powershell
# After processing, check diversity
python -c "import pandas as pd; df = pd.read_csv('data/processed/benign/events.csv'); print(f'Unique processes: {df[\"process_name\"].nunique()}'); print(f'Unique commands: {df[\"command_line\"].nunique()}')"
```

## Troubleshooting

### If Enhanced Simulator Not Found
The script will automatically fall back to the standard simulator. To use enhanced:
1. Ensure `user_behavior_simulator_enhanced.py` is in the automation directory
2. Check Python dependencies are installed

### If LOLBin Commands Fail
- Some commands may require admin privileges (they're skipped gracefully)
- Commands are read-only/query-only to ensure safety
- Failures are logged but don't stop collection

### Performance
- Enhanced simulator may be slightly slower due to more activities
- This is normal and improves data quality
- Monitor system resources if needed

## Next Steps

1. **Run Enhanced Collection**: Let it run for the rest of the day
2. **Monitor Progress**: Use monitor script to track collection
3. **Process Data**: When ready, process with Strategy 3 pipeline
4. **Compare Results**: Compare diversity metrics with previous collection

## Expected Results

After running enhanced collection for a day:
- **50,000-70,000 total events** (raw)
- **15,000-25,000 unique events** (after Strategy 3)
- **200+ unique processes**
- **6,000+ unique command lines**
- **Better temporal distribution**
- **LOLBin usage patterns** (legitimate)

This will significantly improve model training quality! 🚀










