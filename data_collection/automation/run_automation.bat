@echo off
REM Run User Behavior Automation
REM This script runs the automation for generating benign data

echo Starting User Behavior Automation...
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Python not found. Using PowerShell instead.
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0powershell_automation.ps1" -DurationHours 24 -ActivityInterval 60
) else (
    echo Python found. Running Python automation...
    echo.
    cd /d "%~dp0"
    python user_behavior_simulator.py --duration 24 --interval 60
)

echo.
echo Automation completed.
pause


