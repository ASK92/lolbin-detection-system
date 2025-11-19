# Quick Export Latest Sysmon Logs
# Exports current Sysmon logs to Master_sysmon folder

[CmdletBinding()]
param(
    [string]$OutputPath = "C:\Users\adity\lolbin-detection-system\data\Master_sysmon",
    [string]$LogName = "Microsoft-Windows-Sysmon/Operational"
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Export Latest Sysmon Logs" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[WARN] Not running as Administrator. Export may fail." -ForegroundColor Yellow
    Write-Host "For best results, run PowerShell as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    Write-Host "Creating output directory: $OutputPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputFile = Join-Path $OutputPath "SysmonLogs_$timestamp.evtx"

Write-Host "Exporting Sysmon logs..." -ForegroundColor Cyan
Write-Host "  Log: $LogName" -ForegroundColor Gray
Write-Host "  Output: $outputFile" -ForegroundColor Gray
Write-Host ""

try {
    # Export using wevtutil
    wevtutil epl $LogName $outputFile
    
    if (Test-Path $outputFile) {
        $fileSize = (Get-Item $outputFile).Length / 1MB
        Write-Host "[OK] Export successful!" -ForegroundColor Green
        Write-Host "  File: $outputFile" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
        
        # Try to get event count
        try {
            $events = Get-WinEvent -Path $outputFile -ErrorAction SilentlyContinue
            if ($events) {
                Write-Host "  Events: $($events.Count)" -ForegroundColor White
            }
        } catch {
            # Ignore if can't read
        }
        
        Write-Host ""
        Write-Host "Export complete! File saved to Master_sysmon folder." -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Export file not found after export" -ForegroundColor Red
        Write-Host "You may need to run this script as Administrator." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Export failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Run PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "  2. Check if Sysmon is installed: Get-Service | Where-Object {$_.Name -like '*sysmon*'}" -ForegroundColor Gray
    Write-Host "  3. Check log name: wevtutil el | Select-String -Pattern 'sysmon'" -ForegroundColor Gray
    exit 1
}

Write-Host ""

