# Comprehensive LOLBin Attack Orchestrator
# Master script that runs all attack generation scripts in a coordinated manner
# WARNING: This script generates malicious attack patterns. Use only in isolated test environments.

[CmdletBinding()]
param(
    [int]$StandardAttackCount = 1000,
    [int]$AdvancedAttackCount = 500,
    [int]$DelayBetweenAttacks = 2,
    [switch]$StandardOnly,
    [switch]$AdvancedOnly,
    [switch]$IncludeObfuscation,
    [switch]$IncludePolymorphic,
    [string]$OutputDir = "C:\SysmonLogs",
    [switch]$AutoExport,
    [switch]$SkipConfirmation  # Skip interactive confirmation prompt
)

$ErrorActionPreference = "Continue"

Write-Host @"
╔══════════════════════════════════════════════════════════════════════╗
║     COMPREHENSIVE LOLBIN ATTACK ORCHESTRATOR                          ║
║     Generates the most realistic malicious LOLBin attack data          ║
║     WARNING: Use only in isolated test environments!                   ║
╚══════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Red

Write-Host "`nThis script will generate comprehensive malicious LOLBin attack data covering:" -ForegroundColor Cyan
Write-Host "  [*] All major LOLBin processes (PowerShell, CMD, WMIC, CertUtil, etc.)" -ForegroundColor Green
Write-Host "  [*] All attack phases (Execution, Persistence, Lateral Movement, etc.)" -ForegroundColor Green
Write-Host "  [*] All evasion techniques (Encoding, Obfuscation, Bypass, etc.)" -ForegroundColor Green
Write-Host "  [*] Edge cases and advanced techniques" -ForegroundColor Green
Write-Host "  [*] Real-world attack patterns" -ForegroundColor Green
Write-Host ""

if (-not $SkipConfirmation) {
    $confirm = Read-Host "Are you sure you want to proceed? (YES to continue)"
    if ($confirm -ne "YES") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit
    }
} else {
    Write-Host "Skipping confirmation (SkipConfirmation flag set)" -ForegroundColor Gray
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$standardScript = Join-Path $scriptDir "generate_malicious_lolbin_attacks.ps1"
$advancedScript = Join-Path $scriptDir "generate_advanced_lolbin_attacks.ps1"

$startTime = Get-Date
$logFile = Join-Path $OutputDir "comprehensive_attacks_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host "  STARTING COMPREHENSIVE ATTACK GENERATION" -ForegroundColor Cyan
Write-Host "="*70 -ForegroundColor Cyan
Write-Host "Start Time: $startTime" -ForegroundColor White
Write-Host "Output Directory: $OutputDir" -ForegroundColor White
Write-Host "Log File: $logFile" -ForegroundColor White
Write-Host ""

# Phase 1: Standard Attacks
if (-not $AdvancedOnly) {
    Write-Host "`n" + "="*70 -ForegroundColor Yellow
    Write-Host "  PHASE 1: STANDARD ATTACKS" -ForegroundColor Yellow
    Write-Host "="*70 -ForegroundColor Yellow
    Write-Host "Generating $StandardAttackCount standard attacks..." -ForegroundColor White
    
    $standardLog = Join-Path $OutputDir "standard_attacks_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    try {
        & $standardScript -AttackCount $StandardAttackCount -DelayBetweenAttacks $DelayBetweenAttacks -LogFile $standardLog -Verbose
        Write-Host "[OK] Standard attacks completed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Standard attacks failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "Waiting 5 seconds before next phase..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

# Phase 2: Advanced Attacks
if (-not $StandardOnly) {
    Write-Host "`n" + "="*70 -ForegroundColor Magenta
    Write-Host "  PHASE 2: ADVANCED ATTACKS" -ForegroundColor Magenta
    Write-Host "="*70 -ForegroundColor Magenta
    Write-Host "Generating $AdvancedAttackCount advanced attacks..." -ForegroundColor White
    
    $advancedLog = Join-Path $OutputDir "advanced_attacks_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $advancedParams = @{
        AttackCount = $AdvancedAttackCount
        DelayBetweenAttacks = $DelayBetweenAttacks
        LogFile = $advancedLog
    }
    
    if ($IncludeObfuscation) {
        $advancedParams['IncludeObfuscation'] = $true
    }
    
    if ($IncludePolymorphic) {
        $advancedParams['IncludePolymorphic'] = $true
    }
    
    try {
        & $advancedScript @advancedParams
        Write-Host "[OK] Advanced attacks completed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Advanced attacks failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host "  ATTACK GENERATION COMPLETE" -ForegroundColor Cyan
Write-Host "="*70 -ForegroundColor Cyan
Write-Host "Start Time: $startTime" -ForegroundColor White
Write-Host "End Time: $endTime" -ForegroundColor White
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Host ""

# Export Sysmon logs if requested
if ($AutoExport) {
    Write-Host "Exporting Sysmon logs..." -ForegroundColor Cyan
    $exportFile = Join-Path $OutputDir "Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx"
    
    try {
        Start-Process -FilePath "wevtutil.exe" -ArgumentList @("epl", "Microsoft-Windows-Sysmon/Operational", $exportFile) -Verb RunAs -Wait -ErrorAction Stop
        Write-Host "[OK] Sysmon logs exported to: $exportFile" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Could not auto-export Sysmon logs (may require elevation)" -ForegroundColor Yellow
        Write-Host "   Manual export command:" -ForegroundColor Yellow
        Write-Host "   wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"$exportFile`"" -ForegroundColor Gray
    }
} else {
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Export Sysmon logs:" -ForegroundColor White
    Write-Host "   wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"$OutputDir\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Process the logs:" -ForegroundColor White
    Write-Host "   python scripts/process_evtx_files.py --input-dir `"$OutputDir`" --output-dir data/processed/malicious --label 1 --format csv" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Analyze data quality:" -ForegroundColor White
    Write-Host "   python scripts/analyze_data_quality.py data/processed/malicious/events.csv" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "[OK] Comprehensive attack generation complete!" -ForegroundColor Green
Write-Host ""

