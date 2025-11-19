# Export Sysmon Logs Script
# Exports Sysmon logs periodically to prevent data loss

[CmdletBinding()]
param(
    [string]$OutputPath = "C:\SysmonLogs",
    [string]$LogName = "Microsoft-Windows-Sysmon/Operational",
    [switch]$AutoExport,  # Auto-export without prompting
    [switch]$Continuous,  # Run continuously with periodic exports
    [int]$IntervalHours = 24  # Hours between exports (for continuous mode)
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sysmon Log Export Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    Write-Host "Creating output directory: $OutputPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

function Export-SysmonLog {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputFile = Join-Path $OutputPath "SysmonLogs_$timestamp.evtx"
    
    Write-Host "Exporting Sysmon logs..." -ForegroundColor Cyan
    Write-Host "  Output: $outputFile" -ForegroundColor Gray
    
    try {
        wevtutil epl $LogName $outputFile
        
        if (Test-Path $outputFile) {
            $fileSize = (Get-Item $outputFile).Length / 1MB
            Write-Host "[OK] Exported successfully" -ForegroundColor Green
            Write-Host "  File Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
            
            # Get event count from exported file (if possible)
            try {
                $eventCount = (Get-WinEvent -Path $outputFile -ErrorAction SilentlyContinue).Count
                if ($eventCount) {
                    Write-Host "  Event Count: $eventCount" -ForegroundColor Gray
                }
            } catch {
                # Ignore if can't read
            }
            
            return $true
        } else {
            Write-Host "[ERROR] Export file not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Export failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Single export
if (-not $Continuous) {
    Export-SysmonLog
    Write-Host ""
    Write-Host "Export complete!" -ForegroundColor Green
    exit 0
}

# Continuous mode
Write-Host "Running in continuous mode..." -ForegroundColor Cyan
Write-Host "  Export Interval: $IntervalHours hours" -ForegroundColor White
Write-Host "  Output Path: $OutputPath" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

$exportCount = 0

while ($true) {
    $exportCount++
    $exportTime = Get-Date
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Export #$exportCount" -ForegroundColor Cyan
    Write-Host "Time: $($exportTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Export-SysmonLog
    
    Write-Host ""
    Write-Host "Next export in $IntervalHours hours..." -ForegroundColor Gray
    Write-Host ""
    
    # Wait for next interval
    $secondsToWait = $IntervalHours * 3600
    Start-Sleep -Seconds $secondsToWait
}








