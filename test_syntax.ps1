try {
    $sysmonEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue -MaxEvents 1
    if ($sysmonEvents) {
        Write-Host "Found events"
    } else {
        Write-Host "No events"
    }
} catch {
    Write-Host "Error"
}












