# Malicious LOLBin Attack Generation Guide

Complete guide for generating realistic malicious LOLBin attack data for ML model training.

## ⚠️ WARNING

**These scripts generate malicious attack patterns. Use ONLY in isolated test environments with proper security controls.**

## Overview

This suite of scripts generates comprehensive malicious LOLBin attack data covering:

- **All major LOLBin processes**: PowerShell, CMD, WMIC, CertUtil, Regsvr32, MSHTA, Rundll32, CScript, WScript, BITSAdmin, SchTasks, SC, Net, etc.
- **All attack phases**: Initial Access, Execution, Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection, Exfiltration, Command and Control
- **All evasion techniques**: Base64 encoding, obfuscation, bypass techniques, hidden execution, process injection
- **Edge cases**: Advanced evasion, polymorphic attacks, memory-only attacks, DNS-based attacks, alternative data streams
- **Real-world patterns**: Based on actual attack frameworks (Empire, Nishang, PowerSploit, Mimikatz)

## Scripts

### 1. `generate_malicious_lolbin_attacks.ps1`

**Standard comprehensive attack generator**

Generates 1,000+ realistic malicious LOLBin attack patterns covering all major techniques.

**Usage:**
```powershell
.\generate_malicious_lolbin_attacks.ps1 -AttackCount 1000 -DelayBetweenAttacks 2
```

**Parameters:**
- `-AttackCount`: Number of attacks to generate (default: 1000)
- `-DelayBetweenAttacks`: Delay in seconds between attacks (default: 2)
- `-Verbose`: Show detailed progress
- `-LogFile`: Path to log file (default: malicious_attacks.log)

**Attack Categories:**
- PowerShell Encoded Attacks (150 variations)
- PowerShell Download Attacks (100 variations)
- PowerShell Execution Attacks (100 variations)
- PowerShell Evasion Attacks (100 variations)
- CMD Execution Attacks (80 variations)
- WMIC Attacks (80 variations)
- CertUtil Attacks (60 variations)
- Regsvr32 Attacks (60 variations)
- MSHTA Attacks (60 variations)
- Rundll32 Attacks (60 variations)
- CScript/WScript Attacks (50 variations)
- BITSAdmin Attacks (50 variations)
- SchTasks Persistence Attacks (50 variations)
- Registry Persistence Attacks (50 variations)
- Credential Access Attacks (50 variations)
- Lateral Movement Attacks (50 variations)
- Discovery/Recon Attacks (50 variations)
- Fileless Attacks (50 variations)
- Advanced Evasion Attacks (50 variations)

### 2. `generate_advanced_lolbin_attacks.ps1`

**Advanced edge-case attack generator**

Generates sophisticated and edge-case malicious LOLBin attack patterns.

**Usage:**
```powershell
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 500 -IncludeObfuscation -IncludePolymorphic
```

**Parameters:**
- `-AttackCount`: Number of attacks to generate (default: 500)
- `-DelayBetweenAttacks`: Delay in seconds between attacks (default: 3)
- `-IncludeObfuscation`: Include obfuscation techniques
- `-IncludePolymorphic`: Include polymorphic techniques
- `-LogFile`: Path to log file (default: advanced_attacks.log)

**Advanced Techniques:**
- Obfuscated PowerShell Attacks
- Polymorphic Attacks
- Environment-Specific Attacks
- Chained Attacks
- Memory-Only Attacks
- DNS-Based Attacks
- Alternative Data Stream Attacks

### 3. `run_comprehensive_lolbin_attacks.ps1`

**Master orchestrator script**

Runs both standard and advanced attack generators in a coordinated manner.

**Usage:**
```powershell
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1000 -AdvancedAttackCount 500 -AutoExport
```

**Parameters:**
- `-StandardAttackCount`: Number of standard attacks (default: 1000)
- `-AdvancedAttackCount`: Number of advanced attacks (default: 500)
- `-DelayBetweenAttacks`: Delay between attacks (default: 2)
- `-StandardOnly`: Run only standard attacks
- `-AdvancedOnly`: Run only advanced attacks
- `-IncludeObfuscation`: Include obfuscation in advanced attacks
- `-IncludePolymorphic`: Include polymorphic in advanced attacks
- `-OutputDir`: Output directory for logs (default: C:\SysmonLogs)
- `-AutoExport`: Automatically export Sysmon logs after completion

## Complete Workflow

### Step 1: Prepare Environment

1. **Isolated Test VM**: Use a Windows VM with Sysmon installed
2. **Sysmon Configuration**: Ensure Sysmon is logging all Event IDs (1, 7, 10, 11, 13, 22)
3. **PowerShell Logging**: Enable PowerShell script block logging
4. **Network Isolation**: Isolate the VM from production networks

### Step 2: Run Attack Generation

```powershell
# Option 1: Run comprehensive attacks (recommended)
.\run_comprehensive_lolbin_attacks.ps1 -StandardAttackCount 1000 -AdvancedAttackCount 500 -AutoExport

# Option 2: Run standard attacks only
.\generate_malicious_lolbin_attacks.ps1 -AttackCount 1000 -DelayBetweenAttacks 2

# Option 3: Run advanced attacks only
.\generate_advanced_lolbin_attacks.ps1 -AttackCount 500 -IncludeObfuscation -IncludePolymorphic
```

### Step 3: Export Sysmon Logs

```powershell
# If not auto-exported
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx"
```

### Step 4: Process the Data

```bash
# Process malicious EVTX files
python scripts/process_evtx_files.py \
    --input-dir C:\SysmonLogs \
    --output-dir data/processed/malicious \
    --label 1 \
    --format csv
```

### Step 5: Analyze Data Quality

```bash
# Analyze the processed data
python scripts/analyze_data_quality.py data/processed/malicious/events.csv
```

### Step 6: Combine with Benign Data

```bash
# Combine benign and malicious datasets
python scripts/prepare_training_pipeline.py \
    --benign-input data/processed/benign/events.csv \
    --malicious-input data/processed/malicious/events.csv \
    --combined-output data/processed/training_data.csv \
    --step combine
```

## Attack Patterns Generated

### PowerShell Attacks

1. **Encoded Commands**
   - Base64 encoded payloads
   - Unicode encoding
   - Multiple encoding layers

2. **Download Cradles**
   - `IEX (New-Object Net.WebClient).DownloadString()`
   - `Invoke-WebRequest` with `IEX`
   - `Invoke-Expression` with web requests

3. **Execution Bypass**
   - `-ExecutionPolicy Bypass`
   - `-NoProfile`
   - `-WindowStyle Hidden`
   - `-NonInteractive`

4. **Obfuscation**
   - String replacement
   - Variable obfuscation
   - Reverse strings
   - XOR encoding

### CMD Attacks

1. **Process Creation**
   - Chained command execution
   - Hidden window execution
   - Multiple command layers

2. **LOLBin Chaining**
   - CMD -> PowerShell
   - CMD -> CertUtil
   - CMD -> BITSAdmin

### WMIC Attacks

1. **Remote Process Creation**
   - `wmic process call create`
   - Remote node execution
   - Process spawning

### CertUtil Attacks

1. **File Download**
   - `certutil -urlcache -split -f`
   - Base64 encoding/decoding
   - File caching manipulation

### Regsvr32 Attacks

1. **SCT File Execution**
   - Remote SCT file execution
   - COM object registration
   - Scriptlet execution

### MSHTA Attacks

1. **HTA File Execution**
   - Remote HTA execution
   - JavaScript/VBScript execution
   - ActiveX object creation

### Rundll32 Attacks

1. **JavaScript Execution**
   - `javascript:\\..\\mshtml,RunHTMLApplication`
   - ActiveX object execution
   - Script execution

### Persistence Mechanisms

1. **Scheduled Tasks**
   - `schtasks /create` with malicious commands
   - Multiple trigger types (onlogon, daily, hourly)

2. **Registry Run Keys**
   - `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
   - `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
   - RunOnce keys

### Credential Access

1. **Mimikatz-style Attacks**
   - Credential dumping simulation
   - SAM/SYSTEM file access
   - WMI credential queries

### Lateral Movement

1. **Remote Execution**
   - WMIC remote process creation
   - PowerShell remoting
   - Service creation on remote hosts

### Discovery/Recon

1. **System Information Gathering**
   - Process enumeration
   - Network connection enumeration
   - User account enumeration
   - System configuration queries

### Advanced Techniques

1. **Memory-Only Attacks**
   - Reflective DLL loading
   - In-memory script execution
   - Process hollowing simulation

2. **DNS-Based Attacks**
   - DNS exfiltration
   - DNS tunneling
   - DNS command and control

3. **Alternative Data Streams**
   - Hiding payloads in ADS
   - Executing from ADS

## Expected Results

After running the comprehensive attack generator, you should have:

- **1,000-1,500+ malicious events** (depending on configuration)
- **High diversity** across all LOLBin processes
- **All attack phases** represented
- **All evasion techniques** covered
- **Edge cases** included

## Data Quality Metrics

After processing, verify:

- ✅ **Event Count**: 1,000+ malicious events
- ✅ **Process Diversity**: 15+ different LOLBin processes
- ✅ **Command Line Coverage**: 100% of events have command lines
- ✅ **Pattern Diversity**: Multiple variations of each technique
- ✅ **Label Distribution**: All events labeled as 1 (malicious)

## Troubleshooting

### Attacks Not Generating Events

1. **Check Sysmon**: Verify Sysmon is running and logging
   ```powershell
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
   ```

2. **Check Permissions**: Some attacks may require elevated privileges

3. **Check Network**: Some attacks require network access (use isolated network)

### Low Event Count

1. **Increase Attack Count**: Use `-AttackCount 2000` or higher
2. **Reduce Delays**: Use `-DelayBetweenAttacks 1`
3. **Check Logs**: Review log files for errors

### Processing Errors

1. **Verify EVTX Files**: Ensure files are valid EVTX format
2. **Check Python Dependencies**: Ensure `python-evtx` is installed
3. **Review Error Messages**: Check processing script output

## Security Considerations

1. **Isolation**: Always run in isolated test environments
2. **Network Isolation**: Isolate from production networks
3. **Logging**: Monitor all activities
4. **Cleanup**: Remove all generated files after data collection
5. **Access Control**: Restrict access to attack scripts

## Next Steps

After generating malicious data:

1. ✅ Process EVTX files to CSV
2. ✅ Analyze data quality
3. ✅ Combine with benign data
4. ✅ Train ML models
5. ✅ Evaluate model performance

## References

- [LOLBAS Project](https://lolbas-project.github.io/)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [Sysmon Documentation](https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon)









