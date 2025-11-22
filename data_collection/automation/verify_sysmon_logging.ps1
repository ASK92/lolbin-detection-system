# Quick verification script to check if Sysmon is logging attack events
# Run this while attacks are running to verify data collection is working

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sysmon Event Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Check Sysmon service
    $sysmon = Get-Service -Name "Sysmon" -ErrorAction SilentlyContinue
    if ($sysmon) {
        Write-Host "[OK] Sysmon service is running" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Sysmon service not found!" -ForegroundColor Red
        exit
    }
    
    # Get recent Event ID 1 (Process Creation) events
    Write-Host "`nChecking recent Sysmon Event ID 1 (Process Creation) events..." -ForegroundColor Cyan
    
    $recentEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=1]]" -MaxEvents 20 -ErrorAction SilentlyContinue
    
    if ($recentEvents) {
        Write-Host "[OK] Found $($recentEvents.Count) recent Event ID 1 events" -ForegroundColor Green
        Write-Host ""
        
        # Count by process name
        $processCounts = @{}
        foreach ($event in $recentEvents) {
            $xml = [xml]$event.ToXml()
            $eventData = $xml.Event.EventData.Data
            foreach ($data in $eventData) {
                if ($data.Name -eq "Image") {
                    $processName = Split-Path $data.'#text' -Leaf
                    if (-not $processCounts.ContainsKey($processName)) {
                        $processCounts[$processName] = 0
                    }
                    $processCounts[$processName]++
                    break
                }
            }
        }
        
        Write-Host "Process breakdown (last 20 events):" -ForegroundColor Cyan
        foreach ($proc in $processCounts.Keys | Sort-Object) {
            Write-Host "  $proc : $($processCounts[$proc])" -ForegroundColor Gray
        }
        
        # Check for LOLBin processes
        $lolbins = @('powershell.exe', 'cmd.exe', 'wmic.exe', 'certutil.exe', 'regsvr32.exe', 'mshta.exe', 'rundll32.exe', 'cscript.exe', 'wscript.exe', 'bitsadmin.exe', 'schtasks.exe')
        $foundLolbins = $processCounts.Keys | Where-Object { $lolbins -contains $_ }
        
        if ($foundLolbins) {
            Write-Host "`n[OK] Found LOLBin processes in recent events:" -ForegroundColor Green
            foreach ($lolbin in $foundLolbins) {
                Write-Host "  $lolbin : $($processCounts[$lolbin]) events" -ForegroundColor Green
            }
        } else {
            Write-Host "`n[INFO] No LOLBin processes in last 20 events (may need to wait for more events)" -ForegroundColor Yellow
        }
        
        # Show most recent event details
        Write-Host "`nMost recent Event ID 1:" -ForegroundColor Cyan
        $latest = $recentEvents[0]
        $xml = [xml]$latest.ToXml()
        $eventData = $xml.Event.EventData.Data
        
        foreach ($data in $eventData) {
            if ($data.Name -in @("Image", "CommandLine", "ParentImage")) {
                $value = $data.'#text'
                if ($value) {
                    if ($data.Name -eq "CommandLine" -and $value.Length -gt 100) {
                        $value = $value.Substring(0, 100) + "..."
                    }
                    Write-Host "  $($data.Name): $value" -ForegroundColor Gray
                }
            }
        }
        
        Write-Host "`n[SUCCESS] Sysmon is logging events! Data collection is working." -ForegroundColor Green
        Write-Host "Even if attacks fail, Sysmon is capturing the process creation events you need." -ForegroundColor Yellow
        
    } else {
        Write-Host "[WARN] No recent Event ID 1 events found" -ForegroundColor Yellow
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  1. Attacks haven't started yet" -ForegroundColor Gray
        Write-Host "  2. Sysmon isn't logging (check configuration)" -ForegroundColor Gray
        Write-Host "  3. Need admin privileges to read events" -ForegroundColor Gray
    }
    
    # Total event count
    Write-Host "`nTotal Sysmon Event ID 1 events in log:" -ForegroundColor Cyan
    try {
        $totalEvents = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=1]]" -ErrorAction SilentlyContinue).Count
        Write-Host "  Total: $totalEvents events" -ForegroundColor Gray
    } catch {
        Write-Host "  [INFO] Cannot read total count (may need admin privileges)" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You may need to run this script as Administrator" -ForegroundColor Yellow
}

Write-Host ""









