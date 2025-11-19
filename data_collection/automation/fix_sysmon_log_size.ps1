# Fix Sysmon Event Log Size
# Increases log size and enables retention to prevent data loss

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sysmon Event Log Configuration Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

$logName = "Microsoft-Windows-Sysmon/Operational"

Write-Host "Current Configuration:" -ForegroundColor Yellow
wevtutil gl $logName | Select-String -Pattern "maxSize|retention|autoBackup"
Write-Host ""

# Current max size is 64 MB (67108864 bytes)
# Increase to 512 MB (536870912 bytes) or 1 GB (1073741824 bytes)
$newMaxSize = 1073741824  # 1 GB

Write-Host "Updating Sysmon log configuration..." -ForegroundColor Cyan
Write-Host "  New Max Size: $([math]::Round($newMaxSize / 1MB, 0)) MB" -ForegroundColor White
Write-Host "  Retention: true (overwrite as needed)" -ForegroundColor White
Write-Host ""

# Update log size
try {
    wevtutil sl $logName /ms:$newMaxSize
    Write-Host "[OK] Log size updated successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to update log size: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify the change
Write-Host ""
Write-Host "Updated Configuration:" -ForegroundColor Yellow
wevtutil gl $logName | Select-String -Pattern "maxSize|retention|autoBackup"

Write-Host ""
Write-Host "[OK] Sysmon log configuration updated!" -ForegroundColor Green
Write-Host ""
Write-Host "Recommendation: Export logs periodically to prevent data loss:" -ForegroundColor Cyan
Write-Host "  wevtutil epl `"$logName`" `"C:\SysmonLogs\SysmonLogs_`$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx`"" -ForegroundColor White








