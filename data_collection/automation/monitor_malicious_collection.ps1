# Monitor Malicious Data Collection Script
# Checks if malicious attack generation is running and verifies data quality
# Similar to monitor_benign_collection.ps1 but adapted for malicious data collection

[CmdletBinding()]
param(
    [string]$AutomationPath = "",  # Will default to script directory
    [string]$SysmonLogPath = "C:\SysmonLogs",
    [switch]$Continuous,      # Run continuously with periodic checks
    [int]$CheckInterval = 300, # Seconds between checks (default: 5 minutes)
    [switch]$AutoFix          # Attempt to fix issues automatically
)

$ErrorActionPreference = "Continue"

# Set default automation path to script directory if not specified
if ([string]::IsNullOrEmpty($AutomationPath)) {
    $AutomationPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($AutomationPath)) {
        $AutomationPath = $PSScriptRoot
    }
    if ([string]::IsNullOrEmpty($AutomationPath)) {
        $AutomationPath = Get-Location
    }
}

Write-Host "========================================" -ForegroundColor Red
Write-Host "Malicious Data Collection Monitor" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Automation Path: $AutomationPath" -ForegroundColor Gray
Write-Host "Sysmon Log Path: $SysmonLogPath" -ForegroundColor Gray
Write-Host ""

$allChecksPassed = $true
$warnings = @()
$errors = @()

# Function to check if attack generation process is running
function Test-AttackGenerationProcess {
    Write-Host "[1/9] Checking Attack Generation Process..." -ForegroundColor Cyan
    
    # Check for PowerShell processes running attack scripts
    $attackProcesses = Get-Process -Name "powershell*" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*generate_malicious_lolbin_attacks*" -or 
        $cmdLine -like "*generate_advanced_lolbin_attacks*" -or
        $cmdLine -like "*run_comprehensive_lolbin_attacks*"
    }
    
    if ($attackProcesses) {
        Write-Host "  [OK] Attack generation process(es) running" -ForegroundColor Green
        foreach ($proc in $attackProcesses) {
            Write-Host "    PID: $($proc.Id) - $($proc.ProcessName)" -ForegroundColor Gray
        }
        return $true
    } else {
        Write-Host "  [WARN] No attack generation processes found" -ForegroundColor Yellow
        Write-Host "    Attack generation may have completed or not started" -ForegroundColor Gray
        $script:warnings += "No attack generation processes running"
        return $false
    }
}

# Function to check attack log files
function Test-AttackLogs {
    Write-Host "[2/9] Checking Attack Log Files..." -ForegroundColor Cyan
    
    $logFiles = @(
        Get-ChildItem -Path $AutomationPath -Filter "malicious_attacks*.log" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AutomationPath -Filter "advanced_attacks*.log" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AutomationPath -Filter "comprehensive_attacks*.log" -ErrorAction SilentlyContinue
    )
    
    if (-not $logFiles -or $logFiles.Count -eq 0) {
        Write-Host "  [WARN] No attack log files found" -ForegroundColor Yellow
        $script:warnings += "No attack log files found"
        return $false
    }
    
    $totalSize = 0
    $latestLog = $null
    $latestTime = [DateTime]::MinValue
    
    foreach ($log in $logFiles) {
        $totalSize += $log.Length
        if ($log.LastWriteTime -gt $latestTime) {
            $latestTime = $log.LastWriteTime
            $latestLog = $log
        }
    }
    
    Write-Host "  [OK] Found $($logFiles.Count) attack log file(s)" -ForegroundColor Green
    Write-Host "    Total Size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "    Latest Log: $($latestLog.Name)" -ForegroundColor Gray
    Write-Host "    Last Modified: $($latestLog.LastWriteTime)" -ForegroundColor Gray
    
    # Check if log is being updated (should be recent if still running)
    $ageMinutes = ((Get-Date) - $latestLog.LastWriteTime).TotalMinutes
    if ($ageMinutes -gt 60) {
        Write-Host "  [INFO] Log file hasn't been updated in $([math]::Round($ageMinutes, 1)) minutes" -ForegroundColor Gray
        Write-Host "    Attack generation may have completed" -ForegroundColor Gray
    } else {
        Write-Host "  [OK] Log file is being updated (age: $([math]::Round($ageMinutes, 1)) minutes)" -ForegroundColor Green
    }
    
    # Check for errors in latest log
    if ($latestLog) {
        $errorCount = (Select-String -Path $latestLog.FullName -Pattern "ERROR|Error|error|Exception|Traceback|FAIL" -ErrorAction SilentlyContinue).Count
        if ($errorCount -gt 0) {
            Write-Host "  [WARN] Found $errorCount error(s) in log file" -ForegroundColor Yellow
            $script:warnings += "Errors found in attack log"
        } else {
            Write-Host "  [OK] No errors found in log file" -ForegroundColor Green
        }
        
        # Count successful attacks
        $attackCount = (Select-String -Path $latestLog.FullName -Pattern "Executed.*attack|Attack executed" -ErrorAction SilentlyContinue).Count
        if ($attackCount -gt 0) {
            Write-Host "    Successful Attacks: $attackCount" -ForegroundColor Gray
        }
    }
    
    return $true
}

# Function to check Sysmon events
function Test-SysmonEvents {
    Write-Host "[3/9] Checking Sysmon Events..." -ForegroundColor Cyan
    
    try {
        $sysmonService = Get-Service -Name "Sysmon" -ErrorAction SilentlyContinue
        if (-not $sysmonService) {
            Write-Host "  [FAIL] Sysmon service not found" -ForegroundColor Red
            $script:errors += "Sysmon not installed"
            return $false
        }
        
        if ($sysmonService.Status -ne "Running") {
            Write-Host "  [FAIL] Sysmon service is not running (Status: $($sysmonService.Status))" -ForegroundColor Red
            $script:errors += "Sysmon service not running"
            
            if ($AutoFix) {
                Write-Host "  Attempting to start Sysmon..." -ForegroundColor Yellow
                Start-Service -Name "Sysmon" -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                $sysmonService = Get-Service -Name "Sysmon"
                if ($sysmonService.Status -eq "Running") {
                    Write-Host "  [OK] Sysmon started successfully" -ForegroundColor Green
                }
            }
            return $false
        }
        
        Write-Host "  [OK] Sysmon is running" -ForegroundColor Green
        
        # Check event log (requires admin, may fail)
        try {
            $totalEvents = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue).Count
            if ($totalEvents -gt 0) {
                Write-Host "    Total Sysmon Events: $totalEvents" -ForegroundColor Gray
                
                # Check Event ID 1 (Process Creation) - most relevant for LOLBin attacks
                $eventId1Count = (Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=1]]" -ErrorAction SilentlyContinue).Count
                Write-Host "    Event ID 1 (Process Creation): $eventId1Count" -ForegroundColor Gray
                
                # Check for LOLBin processes in recent events
                $recentEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100 -ErrorAction SilentlyContinue
                $lolbinProcesses = @('powershell', 'cmd', 'wmic', 'certutil', 'regsvr32', 'mshta', 'rundll32', 'cscript', 'wscript', 'bitsadmin', 'schtasks')
                $lolbinCount = 0
                
                foreach ($event in $recentEvents) {
                    $xml = [xml]$event.ToXml()
                    $eventData = $xml.Event.EventData.Data
                    foreach ($data in $eventData) {
                        if ($data.Name -eq "Image" -or $data.Name -eq "CommandLine") {
                            $value = $data.'#text'
                            foreach ($lolbin in $lolbinProcesses) {
                                if ($value -like "*$lolbin*") {
                                    $lolbinCount++
                                    break
                                }
                            }
                        }
                    }
                }
                
                if ($lolbinCount -gt 0) {
                    Write-Host "    Recent LOLBin Events: $lolbinCount (in last 100 events)" -ForegroundColor Green
                } else {
                    Write-Host "    [WARN] No recent LOLBin events detected" -ForegroundColor Yellow
                    $script:warnings += "No recent LOLBin events"
                }
            }
        } catch {
            Write-Host "    [INFO] Cannot read Sysmon events (may need admin privileges)" -ForegroundColor Gray
        }
        
        return $true
    } catch {
        Write-Host "  [FAIL] Error checking Sysmon: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Error checking Sysmon"
        return $false
    }
}

# Function to check PowerShell logging
function Test-PowerShellLogging {
    Write-Host "[4/9] Checking PowerShell Logging..." -ForegroundColor Cyan
    
    try {
        $psEvents = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($psEvents) {
            $totalEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue).Count
            Write-Host "  [OK] PowerShell logging is enabled" -ForegroundColor Green
            Write-Host "    Total Events: $totalEvents" -ForegroundColor Gray
            
            # Check for Event ID 4104 (Script Block Logging)
            $scriptBlockEvents = (Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -FilterXPath "*[System[EventID=4104]]" -ErrorAction SilentlyContinue).Count
            Write-Host "    Script Block Events (4104): $scriptBlockEvents" -ForegroundColor Gray
            
            return $true
        } else {
            Write-Host "  [WARN] No PowerShell events found" -ForegroundColor Yellow
            $script:warnings += "PowerShell logging may not be enabled"
            return $false
        }
    } catch {
        Write-Host "  [WARN] Cannot check PowerShell logs: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to check exported EVTX files
function Test-ExportedEVTX {
    Write-Host "[5/9] Checking Exported EVTX Files..." -ForegroundColor Cyan
    
    if (-not (Test-Path $SysmonLogPath)) {
        Write-Host "  [WARN] Sysmon log directory not found: $SysmonLogPath" -ForegroundColor Yellow
        $script:warnings += "Sysmon log directory not found"
        return $false
    }
    
    $evtxFiles = Get-ChildItem -Path $SysmonLogPath -Filter "*Malicious*.evtx" -ErrorAction SilentlyContinue
    
    if (-not $evtxFiles -or $evtxFiles.Count -eq 0) {
        Write-Host "  [INFO] No malicious EVTX files found yet" -ForegroundColor Gray
        Write-Host "    Files will be created after attack generation completes" -ForegroundColor Gray
        return $true  # Not an error, just not created yet
    }
    
    $totalSize = ($evtxFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    $latestFile = $evtxFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    Write-Host "  [OK] Found $($evtxFiles.Count) malicious EVTX file(s)" -ForegroundColor Green
    Write-Host "    Total Size: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Gray
    Write-Host "    Latest File: $($latestFile.Name)" -ForegroundColor Gray
    Write-Host "    Latest Size: $([math]::Round($latestFile.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "    Last Modified: $($latestFile.LastWriteTime)" -ForegroundColor Gray
    
    return $true
}

# Function to check disk space
function Test-DiskSpace {
    Write-Host "[6/9] Checking Disk Space..." -ForegroundColor Cyan
    
    $drive = (Get-Item $SysmonLogPath).PSDrive.Name
    $driveInfo = Get-PSDrive -Name $drive
    
    $freeSpaceGB = $driveInfo.Free / 1GB
    $usedSpaceGB = ($driveInfo.Used + $driveInfo.Free) / 1GB
    $percentFree = ($driveInfo.Free / ($driveInfo.Used + $driveInfo.Free)) * 100
    
    Write-Host "  Drive: $drive" -ForegroundColor Gray
    Write-Host "    Free Space: $([math]::Round($freeSpaceGB, 2)) GB ($([math]::Round($percentFree, 1))%)" -ForegroundColor Gray
    
    if ($freeSpaceGB -lt 1) {
        Write-Host "  [FAIL] Less than 1 GB free space remaining!" -ForegroundColor Red
        $script:errors += "Low disk space"
        return $false
    } elseif ($freeSpaceGB -lt 5) {
        Write-Host "  [WARN] Less than 5 GB free space remaining" -ForegroundColor Yellow
        $script:warnings += "Low disk space"
    } else {
        Write-Host "  [OK] Sufficient disk space" -ForegroundColor Green
    }
    
    return $true
}

# Function to check attack statistics
function Test-AttackStatistics {
    Write-Host "[7/9] Checking Attack Statistics..." -ForegroundColor Cyan
    
    $logFiles = @(
        Get-ChildItem -Path $AutomationPath -Filter "malicious_attacks*.log" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AutomationPath -Filter "advanced_attacks*.log" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AutomationPath -Filter "comprehensive_attacks*.log" -ErrorAction SilentlyContinue
    )
    
    if (-not $logFiles) {
        Write-Host "  [INFO] No log files found for statistics" -ForegroundColor Gray
        return $true
    }
    
    $totalAttacks = 0
    $attackTypes = @{}
    
    foreach ($log in $logFiles) {
        $content = Get-Content $log.FullName -ErrorAction SilentlyContinue
        
        # Count total attacks
        $attacks = $content | Select-String -Pattern "Executed.*attack|Attack executed" -ErrorAction SilentlyContinue
        $totalAttacks += $attacks.Count
        
        # Count by type
        $types = @("PowerShell", "CMD", "WMIC", "CertUtil", "Regsvr32", "MSHTA", "Rundll32", "BITSAdmin", "SchTasks", "Registry", "Credential", "Lateral", "Discovery", "Fileless", "Evasion", "Obfuscated", "Polymorphic", "Memory", "DNS", "ADS")
        
        foreach ($type in $types) {
            $count = ($content | Select-String -Pattern $type -ErrorAction SilentlyContinue).Count
            if ($count -gt 0) {
                if (-not $attackTypes.ContainsKey($type)) {
                    $attackTypes[$type] = 0
                }
                $attackTypes[$type] += $count
            }
        }
    }
    
    if ($totalAttacks -gt 0) {
        Write-Host "  [OK] Attack Statistics:" -ForegroundColor Green
        Write-Host "    Total Attacks Executed: $totalAttacks" -ForegroundColor Gray
        
        if ($attackTypes.Count -gt 0) {
            Write-Host "    Attack Types Detected:" -ForegroundColor Gray
            foreach ($type in $attackTypes.Keys | Sort-Object) {
                Write-Host "      - $type : $($attackTypes[$type])" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  [INFO] No attack statistics available yet" -ForegroundColor Gray
    }
    
    return $true
}

# Function to check recent Sysmon activity
function Test-RecentSysmonActivity {
    Write-Host "[8/9] Checking Recent Sysmon Activity..." -ForegroundColor Cyan
    
    try {
        $recentEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 50 -ErrorAction SilentlyContinue
        
        if (-not $recentEvents) {
            Write-Host "  [WARN] No recent Sysmon events found" -ForegroundColor Yellow
            $script:warnings += "No recent Sysmon activity"
            return $false
        }
        
        $latestEvent = $recentEvents[0]
        $ageMinutes = ((Get-Date) - $latestEvent.TimeCreated).TotalMinutes
        
        Write-Host "  [OK] Recent Sysmon activity detected" -ForegroundColor Green
        Write-Host "    Latest Event: $($latestEvent.TimeCreated)" -ForegroundColor Gray
        Write-Host "    Age: $([math]::Round($ageMinutes, 1)) minutes ago" -ForegroundColor Gray
        Write-Host "    Event ID: $($latestEvent.Id)" -ForegroundColor Gray
        
        if ($ageMinutes -gt 60) {
            Write-Host "  [WARN] No Sysmon activity in the last hour" -ForegroundColor Yellow
            $script:warnings += "No recent Sysmon activity"
            return $false
        }
        
        return $true
    } catch {
        Write-Host "  [WARN] Cannot check recent Sysmon activity: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to check for completion
function Test-AttackCompletion {
    Write-Host "[9/9] Checking Attack Generation Completion..." -ForegroundColor Cyan
    
    $logFiles = @(
        Get-ChildItem -Path $AutomationPath -Filter "malicious_attacks*.log" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AutomationPath -Filter "advanced_attacks*.log" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AutomationPath -Filter "comprehensive_attacks*.log" -ErrorAction SilentlyContinue
    )
    
    if (-not $logFiles) {
        Write-Host "  [INFO] No completion data available" -ForegroundColor Gray
        return $true
    }
    
    foreach ($log in $logFiles) {
        $content = Get-Content $log.FullName -Tail 20 -ErrorAction SilentlyContinue
        $completion = $content | Select-String -Pattern "Attack Generation Complete|completed|Complete" -ErrorAction SilentlyContinue
        
        if ($completion) {
            Write-Host "  [OK] Attack generation completed: $($log.Name)" -ForegroundColor Green
            
            # Extract total attacks
            $totalLine = $content | Select-String -Pattern "Total attacks|Total Attacks" -ErrorAction SilentlyContinue
            if ($totalLine) {
                Write-Host "    $($totalLine.Line)" -ForegroundColor Gray
            }
            
            return $true
        }
    }
    
    Write-Host "  [INFO] Attack generation may still be running" -ForegroundColor Gray
    return $true
}

# Main monitoring function
function Start-Monitoring {
    $checkCount = 0
    
    while ($true) {
        $checkCount++
        $checkTime = Get-Date
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Malicious Collection Monitor Check #$checkCount" -ForegroundColor Red
        Write-Host "Time: $($checkTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        
        $script:allChecksPassed = $true
        $script:warnings = @()
        $script:errors = @()
        
        # Run all checks
        Test-AttackGenerationProcess | Out-Null
        Write-Host ""
        Test-AttackLogs | Out-Null
        Write-Host ""
        Test-SysmonEvents | Out-Null
        Write-Host ""
        Test-PowerShellLogging | Out-Null
        Write-Host ""
        Test-ExportedEVTX | Out-Null
        Write-Host ""
        Test-DiskSpace | Out-Null
        Write-Host ""
        Test-AttackStatistics | Out-Null
        Write-Host ""
        Test-RecentSysmonActivity | Out-Null
        Write-Host ""
        Test-AttackCompletion | Out-Null
        
        # Summary
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Summary" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        
        if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
            Write-Host "[OK] All checks passed!" -ForegroundColor Green
        } elseif ($errors.Count -eq 0) {
            Write-Host "[WARN] Checks passed with $($warnings.Count) warning(s)" -ForegroundColor Yellow
            foreach ($warn in $warnings) {
                Write-Host "  - $warn" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[FAIL] Found $($errors.Count) error(s) and $($warnings.Count) warning(s)" -ForegroundColor Red
            foreach ($err in $errors) {
                Write-Host "  ERROR: $err" -ForegroundColor Red
            }
            foreach ($warn in $warnings) {
                Write-Host "  WARN: $warn" -ForegroundColor Yellow
            }
        }
        
        if (-not $Continuous) {
            break
        }
        
        Write-Host ""
        Write-Host "Next check in $CheckInterval seconds..." -ForegroundColor Gray
        Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
        Start-Sleep -Seconds $CheckInterval
    }
}

# Run monitoring
Start-Monitoring









