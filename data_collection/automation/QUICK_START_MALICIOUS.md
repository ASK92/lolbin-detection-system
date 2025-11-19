# Quick Start: Generate Malicious LOLBin Attack Data

## 🚀 Fastest Way to Generate Attack Data

### Option 1: One-Command Comprehensive Generation (Recommended)

```powershell
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1000 -AdvancedAttackCount 500 -AutoExport
```

This will:
- ✅ Generate 1,000 standard attacks
- ✅ Generate 500 advanced attacks
- ✅ Automatically export Sysmon logs
- ✅ Create comprehensive log files

### Option 2: Standard Attacks Only

```powershell
.\generate_malicious_lolbin_attacks.ps1 -AttackCount 1000 -DelayBetweenAttacks 2
```

### Option 3: Advanced Attacks Only

```powershell
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 500 -IncludeObfuscation -IncludePolymorphic
```

## 📋 Prerequisites Checklist

Before running:

- [ ] Windows VM with Sysmon installed
- [ ] Sysmon logging Event IDs 1, 7, 10, 11, 13, 22
- [ ] PowerShell script block logging enabled
- [ ] VM isolated from production networks
- [ ] Administrator privileges available

## ⚡ Quick Workflow

```powershell
# 1. Run attack generation
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1000 -AdvancedAttackCount 500 -AutoExport

# 2. Process the data (if not auto-exported)
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx"

# 3. Process EVTX to CSV
python scripts/process_evtx_files.py --input-dir C:\SysmonLogs --output-dir data/processed/malicious --label 1 --format csv

# 4. Analyze quality
python scripts/analyze_data_quality.py data/processed/malicious/events.csv
```

## 🎯 What Gets Generated

- **1,500+ malicious events** covering:
  - All major LOLBin processes
  - All attack phases
  - All evasion techniques
  - Edge cases and advanced techniques

## ⏱️ Expected Duration

- **Standard attacks (1,000)**: ~30-40 minutes
- **Advanced attacks (500)**: ~25-30 minutes
- **Total**: ~1 hour

## 📊 Expected Results

After processing, you should have:
- ✅ 1,000-1,500+ malicious events
- ✅ 15+ different LOLBin processes
- ✅ 100% command line coverage
- ✅ All events labeled as malicious (1)

## 🔍 Verify It Worked

```powershell
# Check Sysmon events
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Measure-Object

# Check exported files
Get-ChildItem C:\SysmonLogs\*.evtx

# Check log files
Get-ChildItem *.log
```

## 🆘 Troubleshooting

**No events generated?**
- Check Sysmon is running: `Get-Service Sysmon`
- Check logs: `Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5`

**Low event count?**
- Increase `-AttackCount` parameter
- Reduce `-DelayBetweenAttacks` to 1

**Script errors?**
- Run PowerShell as Administrator
- Check execution policy: `Get-ExecutionPolicy`
- Set execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

## 📚 Full Documentation

See `MALICIOUS_ATTACK_GENERATION.md` for complete documentation.







