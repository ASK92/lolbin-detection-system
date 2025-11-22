# Analyze Malicious Attack Logs
# Provides detailed analysis of generated attack logs

param(
    [string]$LogFile = "C:\SysmonLogs\advanced_attacks_20251117_184816.log"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Malicious Attack Log Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $LogFile)) {
    Write-Host "[ERROR] Log file not found: $LogFile" -ForegroundColor Red
    exit 1
}

$logContent = Get-Content $LogFile

Write-Host "Log File: $LogFile" -ForegroundColor White
Write-Host "Total Lines: $($logContent.Count)" -ForegroundColor White
Write-Host ""

# Extract start/end times
$startTime = ($logContent | Select-String -Pattern "Start Time:").Line
$endTime = ($logContent | Select-String -Pattern "End Time:").Line

if ($startTime) {
    Write-Host "Start Time: $($startTime -replace 'Start Time: ', '')" -ForegroundColor Gray
}
if ($endTime) {
    Write-Host "End Time: $($endTime -replace 'End Time: ', '')" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Attack Statistics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Count successful attacks
$successful = ($logContent | Select-String -Pattern "Executed.*attack").Count
Write-Host "Successful Attacks: $successful" -ForegroundColor Green

# Count failed attacks
$failed = ($logContent | Select-String -Pattern "Attack.*failed|Attack command failed").Count
Write-Host "Failed Attacks: $failed" -ForegroundColor Yellow

# Total attempts
$total = $successful + $failed
Write-Host "Total Attack Attempts: $total" -ForegroundColor White

if ($total -gt 0) {
    $successRate = [math]::Round(($successful / $total) * 100, 1)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -gt 50) { "Green" } else { "Yellow" })
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Attack Types Executed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Count by attack type
$attackTypes = @{
    "PowerShell" = ($logContent | Select-String -Pattern "PowerShell.*attack").Count
    "CMD" = ($logContent | Select-String -Pattern "CMD.*attack").Count
    "WMIC" = ($logContent | Select-String -Pattern "WMIC.*attack").Count
    "CertUtil" = ($logContent | Select-String -Pattern "CertUtil.*attack").Count
    "Regsvr32" = ($logContent | Select-String -Pattern "Regsvr32.*attack").Count
    "MSHTA" = ($logContent | Select-String -Pattern "MSHTA.*attack").Count
    "Rundll32" = ($logContent | Select-String -Pattern "Rundll32.*attack").Count
    "CScript/WScript" = ($logContent | Select-String -Pattern "CScript|WScript.*attack").Count
    "BITSAdmin" = ($logContent | Select-String -Pattern "BITSAdmin.*attack").Count
    "SchTasks" = ($logContent | Select-String -Pattern "SchTasks.*attack").Count
    "Registry" = ($logContent | Select-String -Pattern "Registry.*attack").Count
    "Credential" = ($logContent | Select-String -Pattern "Credential.*attack").Count
    "Lateral Movement" = ($logContent | Select-String -Pattern "Lateral.*attack").Count
    "Discovery" = ($logContent | Select-String -Pattern "Discovery.*attack").Count
    "Fileless" = ($logContent | Select-String -Pattern "Fileless.*attack").Count
    "Evasion" = ($logContent | Select-String -Pattern "Evasion.*attack").Count
    "Obfuscated" = ($logContent | Select-String -Pattern "Obfuscated.*attack").Count
    "Polymorphic" = ($logContent | Select-String -Pattern "Polymorphic.*attack").Count
    "Memory-Only" = ($logContent | Select-String -Pattern "Memory.*attack").Count
    "DNS-Based" = ($logContent | Select-String -Pattern "DNS.*attack").Count
    "ADS" = ($logContent | Select-String -Pattern "ADS.*attack").Count
    "Chained" = ($logContent | Select-String -Pattern "Chained.*attack").Count
    "Environment-Specific" = ($logContent | Select-String -Pattern "Environment.*attack").Count
}

foreach ($type in $attackTypes.Keys | Sort-Object) {
    $count = $attackTypes[$type]
    if ($count -gt 0) {
        Write-Host "  $type : $count" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Error Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Count error types
$accessDenied = ($logContent | Select-String -Pattern "Access is denied|Access denied").Count
$fileNotFound = ($logContent | Select-String -Pattern "cannot find the file").Count
$otherErrors = $failed - $accessDenied - $fileNotFound

Write-Host "Access Denied Errors: $accessDenied" -ForegroundColor Yellow
Write-Host "  [OK] These are expected - Sysmon still logs the events!" -ForegroundColor Green
Write-Host ""
Write-Host "File Not Found Errors: $fileNotFound" -ForegroundColor Yellow
Write-Host "  [OK] These are expected - Sysmon still logs the events!" -ForegroundColor Green
Write-Host ""
Write-Host "Other Errors: $otherErrors" -ForegroundColor Yellow

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Collection Assessment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ GOOD NEWS: Even failed attacks generate Sysmon events!" -ForegroundColor Green
Write-Host ""
Write-Host "What was collected:" -ForegroundColor White
Write-Host "  • Process creation events (Event ID 1)" -ForegroundColor Gray
Write-Host "  • Command lines for all attack attempts" -ForegroundColor Gray
Write-Host "  • Process names (powershell.exe, cmd.exe, etc.)" -ForegroundColor Gray
Write-Host "  • Parent process information" -ForegroundColor Gray
Write-Host "  • User context" -ForegroundColor Gray
Write-Host "  • Timestamps" -ForegroundColor Gray
Write-Host ""

Write-Host "Total Sysmon Events Generated: ~$total (estimated)" -ForegroundColor Cyan
Write-Host "  (Each attack attempt = 1+ Sysmon Event ID 1)" -ForegroundColor Gray
Write-Host ""

# Verify Sysmon is logging
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sysmon Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $recentEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=1]]" -MaxEvents 50 -ErrorAction SilentlyContinue
    
    if ($recentEvents) {
        Write-Host "[OK] Sysmon is logging Event ID 1 (Process Creation) events" -ForegroundColor Green
        Write-Host "  Recent events found: $($recentEvents.Count)" -ForegroundColor Gray
        
        # Check for LOLBin processes
        $lolbinCount = 0
        foreach ($event in $recentEvents) {
            $xml = [xml]$event.ToXml()
            $eventData = $xml.Event.EventData.Data
            foreach ($data in $eventData) {
                if ($data.Name -eq "Image") {
                    $procName = Split-Path $data.'#text' -Leaf
                    $lolbins = @('powershell.exe', 'cmd.exe', 'wmic.exe', 'certutil.exe', 'regsvr32.exe', 'mshta.exe', 'rundll32.exe', 'cscript.exe', 'wscript.exe', 'bitsadmin.exe', 'schtasks.exe')
                    if ($lolbins -contains $procName.ToLower()) {
                        $lolbinCount++
                        break
                    }
                }
            }
        }
        
        if ($lolbinCount -gt 0) {
            Write-Host "  [OK] Found $lolbinCount LOLBin process events in recent logs" -ForegroundColor Green
        } else {
            Write-Host "  [INFO] No LOLBin processes in last 50 events (may need to check more)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] No recent Sysmon events found" -ForegroundColor Yellow
        Write-Host "  This could mean:" -ForegroundColor Yellow
        Write-Host "    - Need admin privileges to read events" -ForegroundColor Gray
        Write-Host "    - Sysmon isn't logging" -ForegroundColor Gray
        Write-Host "    - Events are older than log retention" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARN] Cannot verify Sysmon events: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  You may need to run this script as Administrator" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($total -lt 100) {
    Write-Host "⚠️  Low attack count: $total" -ForegroundColor Yellow
    Write-Host "  Consider running more attacks for better training data" -ForegroundColor White
} elseif ($total -lt 500) {
    Write-Host "✅ Moderate attack count: $total" -ForegroundColor Green
    Write-Host "  Good for initial training, but more would be better" -ForegroundColor White
} else {
    Write-Host "✅ Excellent attack count: $total" -ForegroundColor Green
    Write-Host "  Great for comprehensive training data!" -ForegroundColor White
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Export Sysmon logs: wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx`"" -ForegroundColor White
Write-Host "2. Process the logs: python scripts/process_evtx_files.py --input-dir C:\SysmonLogs --output-dir data/processed/malicious --label 1" -ForegroundColor White
Write-Host "3. Analyze data quality: python scripts/analyze_data_quality.py data/processed/malicious/events.csv" -ForegroundColor White
Write-Host ""








