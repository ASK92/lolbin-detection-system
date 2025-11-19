# Script Usage Guide - Malicious Attack Generation

## 📋 Quick Answer

**Are the scripts merged?** 
- ✅ **YES** - Use `run_comprehensive_lolbin_attacks.ps1` (recommended)
- ✅ **OR** - Run them individually if you want more control

## 🎯 Three Ways to Run

### Option 1: Use the Orchestrator (RECOMMENDED) ⭐

The orchestrator runs both scripts automatically:

```powershell
# Run everything (standard + advanced attacks)
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1000 -AdvancedAttackCount 500 -AutoExport
```

**What it does:**
- ✅ Runs standard attacks (1,000)
- ✅ Runs advanced attacks (500)
- ✅ Automatically exports Sysmon logs
- ✅ Creates comprehensive logs
- ✅ One command, complete solution

### Option 2: Run Scripts Individually

If you want more control, run them separately:

```powershell
# Step 1: Run standard attacks
.\generate_malicious_lolbin_attacks.ps1 -AttackCount 1000 -DelayBetweenAttacks 2

# Step 2: Run advanced attacks (optional)
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 500 -IncludeObfuscation -IncludePolymorphic

# Step 3: Export Sysmon logs manually
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx"
```

### Option 3: Run Only One Type

```powershell
# Only standard attacks
.\run_comprehensive_lolbin_attacks.ps1 -StandardOnly -StandardAttackCount 1000

# Only advanced attacks
.\run_comprehensive_lolbin_attacks.ps1 -AdvancedOnly -AdvancedAttackCount 500
```

## 📊 Comparison

| Feature | Orchestrator | Individual Scripts |
|---------|-------------|-------------------|
| Ease of Use | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Automation | ✅ Full | ⚠️ Manual |
| Control | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Logging | ✅ Comprehensive | ⚠️ Separate logs |
| Auto-Export | ✅ Yes | ❌ Manual |
| Recommended For | Most users | Advanced users |

## 🔍 Monitoring

### Monitor Malicious Collection

```powershell
# One-time check
.\monitor_malicious_collection.ps1

# Continuous monitoring (checks every 5 minutes)
.\monitor_malicious_collection.ps1 -Continuous -CheckInterval 300
```

**What it monitors:**
- ✅ Attack generation processes
- ✅ Attack log files
- ✅ Sysmon events
- ✅ PowerShell logging
- ✅ Exported EVTX files
- ✅ Disk space
- ✅ Attack statistics
- ✅ Recent activity
- ✅ Completion status

## 🚀 Complete Workflow

### Recommended Workflow (Orchestrator)

```powershell
# Terminal 1: Start attack generation
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1000 -AdvancedAttackCount 500 -AutoExport

# Terminal 2: Monitor progress (in another PowerShell window)
.\monitor_malicious_collection.ps1 -Continuous
```

### Manual Workflow (Individual Scripts)

```powershell
# Terminal 1: Start standard attacks
.\generate_malicious_lolbin_attacks.ps1 -AttackCount 1000

# Terminal 2: Monitor
.\monitor_malicious_collection.ps1 -Continuous

# After completion: Run advanced attacks
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 500

# Export logs
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx"
```

## 📝 Script Details

### `run_comprehensive_lolbin_attacks.ps1` (Orchestrator)

**Purpose:** Master script that coordinates both attack generators

**Parameters:**
- `-StandardAttackCount`: Number of standard attacks (default: 1000)
- `-AdvancedAttackCount`: Number of advanced attacks (default: 500)
- `-DelayBetweenAttacks`: Delay in seconds (default: 2)
- `-StandardOnly`: Run only standard attacks
- `-AdvancedOnly`: Run only advanced attacks
- `-IncludeObfuscation`: Include obfuscation in advanced attacks
- `-IncludePolymorphic`: Include polymorphic in advanced attacks
- `-OutputDir`: Output directory (default: C:\SysmonLogs)
- `-AutoExport`: Automatically export Sysmon logs

**Example:**
```powershell
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1500 -AdvancedAttackCount 750 -AutoExport
```

### `generate_malicious_lolbin_attacks.ps1` (Standard)

**Purpose:** Generate standard malicious LOLBin attacks

**Parameters:**
- `-AttackCount`: Number of attacks (default: 1000)
- `-DelayBetweenAttacks`: Delay in seconds (default: 2)
- `-Verbose`: Show detailed progress
- `-LogFile`: Log file path (default: malicious_attacks.log)

**Example:**
```powershell
.\generate_malicious_lolbin_attacks.ps1 -AttackCount 2000 -DelayBetweenAttacks 1 -Verbose
```

### `generate_advanced_lolbin_attacks.ps1` (Advanced)

**Purpose:** Generate advanced/edge-case attacks

**Parameters:**
- `-AttackCount`: Number of attacks (default: 500)
- `-DelayBetweenAttacks`: Delay in seconds (default: 3)
- `-IncludeObfuscation`: Include obfuscation techniques
- `-IncludePolymorphic`: Include polymorphic techniques
- `-LogFile`: Log file path (default: advanced_attacks.log)

**Example:**
```powershell
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 1000 -IncludeObfuscation -IncludePolymorphic
```

### `monitor_malicious_collection.ps1` (Monitor)

**Purpose:** Monitor malicious data collection progress

**Parameters:**
- `-AutomationPath`: Path to automation directory (default: script directory)
- `-SysmonLogPath`: Path to Sysmon logs (default: C:\SysmonLogs)
- `-Continuous`: Run continuously with periodic checks
- `-CheckInterval`: Seconds between checks (default: 300 = 5 minutes)
- `-AutoFix`: Attempt to fix issues automatically

**Example:**
```powershell
# One-time check
.\monitor_malicious_collection.ps1

# Continuous monitoring (every 5 minutes)
.\monitor_malicious_collection.ps1 -Continuous

# Continuous monitoring (every 2 minutes)
.\monitor_malicious_collection.ps1 -Continuous -CheckInterval 120
```

## ⏱️ Expected Duration

| Configuration | Duration |
|--------------|----------|
| Standard (1,000 attacks) | ~30-40 minutes |
| Advanced (500 attacks) | ~25-30 minutes |
| Comprehensive (1,000 + 500) | ~1 hour |
| Large (2,000 + 1,000) | ~2 hours |

## ✅ Quick Decision Tree

```
Do you want the easiest option?
├─ YES → Use orchestrator: run_comprehensive_lolbin_attacks.ps1
└─ NO → Continue...

Do you need fine-grained control?
├─ YES → Run scripts individually
└─ NO → Use orchestrator

Do you want to monitor progress?
└─ YES → Run monitor_malicious_collection.ps1 in another terminal
```

## 🎯 Recommendations

1. **First Time Users:** Use the orchestrator
   ```powershell
   .\run_comprehensive_lolbin_attacks.ps1 -AutoExport
   ```

2. **Advanced Users:** Run individually for more control
   ```powershell
   .\generate_malicious_lolbin_attacks.ps1 -AttackCount 2000
   .\generate_advanced_lolbin_attacks.ps1 -AttackCount 1000
   ```

3. **Always Monitor:** Run monitor in a separate terminal
   ```powershell
   .\monitor_malicious_collection.ps1 -Continuous
   ```

## 📚 Related Documentation

- `MALICIOUS_ATTACK_GENERATION.md` - Complete guide
- `QUICK_START_MALICIOUS.md` - Quick start guide
- `ATTACK_GENERATION_SUMMARY.md` - Summary of what's generated







