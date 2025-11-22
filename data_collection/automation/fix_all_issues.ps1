# Comprehensive Fix Script for Antivirus and Access Issues
# Run this as Administrator to fix all issues

param(
    [switch]$SkipAntivirus,
    [switch]$SkipPermissions
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Antivirus and Access Issues" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To run as Administrator:" -ForegroundColor Yellow
    Write-Host "1. Right-click PowerShell" -ForegroundColor White
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "3. Navigate to: $PSScriptRoot" -ForegroundColor White
    Write-Host "4. Run: .\fix_all_issues.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "[OK] Running as Administrator" -ForegroundColor Green
Write-Host ""

$exclusionPath = "C:\Users\adity\lolbin-detection-system\data_collection\automation"
$sysmonLogPath = "C:\SysmonLogs"

# ============================================================================
# Fix 1: Antivirus Exclusion
# ============================================================================

if (-not $SkipAntivirus) {
    Write-Host "[1/3] Adding Antivirus Exclusion..." -ForegroundColor Cyan
    
    try {
        # Check if Windows Defender is available
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        if ($defender) {
            # Add folder exclusion
            Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction Stop
            Write-Host "  [OK] Added exclusion for: $exclusionPath" -ForegroundColor Green
            
            # Also add process exclusions for PowerShell
            Add-MpPreference -ExclusionProcess "powershell.exe" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess "pwsh.exe" -ErrorAction SilentlyContinue
            Write-Host "  [OK] Added process exclusions for PowerShell" -ForegroundColor Green
            
            # Verify
            $exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
            if ($exclusions -contains $exclusionPath) {
                Write-Host "  [OK] Exclusion verified" -ForegroundColor Green
            }
        } else {
            Write-Host "  [WARN] Windows Defender not found or not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [ERROR] Failed to add exclusion: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [INFO] You may need to add it manually via Windows Security GUI" -ForegroundColor Yellow
    }
} else {
    Write-Host "[1/3] Skipping Antivirus Exclusion (SkipAntivirus flag set)" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Fix 2: File Permissions
# ============================================================================

if (-not $SkipPermissions) {
    Write-Host "[2/3] Fixing File Permissions..." -ForegroundColor Cyan
    
    try {
        # Ensure automation directory has proper permissions
        $acl = Get-Acl $exclusionPath
        $permission = "$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $exclusionPath -AclObject $acl
        Write-Host "  [OK] Fixed permissions for: $exclusionPath" -ForegroundColor Green
        
        # Ensure Sysmon log directory exists and has permissions
        if (-not (Test-Path $sysmonLogPath)) {
            New-Item -ItemType Directory -Path $sysmonLogPath -Force | Out-Null
            Write-Host "  [OK] Created directory: $sysmonLogPath" -ForegroundColor Green
        }
        
        $acl = Get-Acl $sysmonLogPath
        $permission = "$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $sysmonLogPath -AclObject $acl
        Write-Host "  [OK] Fixed permissions for: $sysmonLogPath" -ForegroundColor Green
        
    } catch {
        Write-Host "  [ERROR] Failed to fix permissions: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[2/3] Skipping Permissions Fix (SkipPermissions flag set)" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Fix 3: Execution Policy
# ============================================================================

Write-Host "[3/3] Fixing PowerShell Execution Policy..." -ForegroundColor Cyan

try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Host "  Current execution policy: $currentPolicy" -ForegroundColor Gray
    
    if ($currentPolicy -eq "Restricted") {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "  [OK] Changed execution policy to RemoteSigned" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Execution policy is already permissive ($currentPolicy)" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARN] Could not change execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fix Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Try running the attack script again:" -ForegroundColor White
Write-Host "   .\run_comprehensive_lolbin_attacks.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "2. If antivirus still blocks, you may need to:" -ForegroundColor White
Write-Host "   - Temporarily disable real-time protection (test VM only!)" -ForegroundColor Gray
Write-Host "   - Or add exclusions manually via Windows Security GUI" -ForegroundColor Gray
Write-Host ""
Write-Host "3. If you still get access denied errors:" -ForegroundColor White
Write-Host "   - Make sure you're running PowerShell as Administrator" -ForegroundColor Gray
Write-Host "   - Check that Sysmon service is running" -ForegroundColor Gray
Write-Host ""

# Test if scripts are accessible
Write-Host "Testing script accessibility..." -ForegroundColor Cyan
$testScript = Join-Path $exclusionPath "generate_malicious_lolbin_attacks.ps1"
if (Test-Path $testScript) {
    Write-Host "  [OK] Script file is accessible: $testScript" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Script file not found: $testScript" -ForegroundColor Red
}

Write-Host ""
Write-Host "[DONE] Fix script completed!" -ForegroundColor Green
Write-Host ""









