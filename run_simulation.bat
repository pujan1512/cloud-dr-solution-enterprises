@echo off
title Enterprise Cloud Disaster Recovery - CLI Simulation Drill
color 0B
echo ======================================================================
echo   Enterprise Cloud Disaster Recovery Drill Simulation
echo   Multi-Region Automated Failover Demonstration (us-east-1 ^<--^> us-west-2)
echo ======================================================================
echo.

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python 3.8+ to execute the simulation.
    pause
    exit /b 1
)

python simulation\simulate_dr.py

echo.
echo ======================================================================
echo   Drill complete! Press any key to exit...
echo ======================================================================
pause >nul
