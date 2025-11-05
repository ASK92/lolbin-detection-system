@echo off
echo ========================================
echo 5-Day Continuous Automation Runner
echo ========================================
echo.

cd /d C:\Automation

if not exist "user_behavior_simulator.py" (
    echo ERROR: Automation scripts not found in C:\Automation
    echo Please copy automation scripts to C:\Automation
    pause
    exit /b 1
)

echo Starting 5-day continuous automation...
echo Duration: 5 days (120 hours)
echo Activity Interval: 60 seconds
echo.
echo This will run continuously for 5 days.
echo Press Ctrl+C to stop.
echo.

python user_behavior_simulator.py --days 5 --interval 60

echo.
echo Automation completed!
pause

