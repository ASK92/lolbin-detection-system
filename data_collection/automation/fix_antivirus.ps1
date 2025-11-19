# Quick script to add antivirus exclusion
# Run this as Administrator to allow the attack scripts to run

Write-Host "Adding antivirus exclusion for attack scripts..." -ForegroundColor Cyan

try {
    $exclusionPath = "C:\Users\adity\lolbin-detection-system\data_collection\automation"
    
    # Add exclusion
    Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction Stop
    
    Write-Host "[OK] Successfully added exclusion for: $exclusionPath" -ForegroundColor Green
    Write-Host "You can now run the standard attack script." -ForegroundColor Green
    
} catch {
    Write-Host "[ERROR] Failed to add exclusion: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you're running as Administrator!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual steps:" -ForegroundColor Cyan
    Write-Host "1. Open Windows Security" -ForegroundColor White
    Write-Host "2. Go to Virus & threat protection" -ForegroundColor White
    Write-Host "3. Click 'Manage settings' under Virus & threat protection settings" -ForegroundColor White
    Write-Host "4. Scroll to Exclusions" -ForegroundColor White
    Write-Host "5. Click 'Add or remove exclusions'" -ForegroundColor White
    Write-Host "6. Add folder: $exclusionPath" -ForegroundColor White
}







