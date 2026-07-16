@echo off
title Meeting AI - Launcher
color 0A

echo ===================================================
echo   Starting Meeting AI...
echo ===================================================
echo.

if exist "venv\Scripts\python.exe" (
    echo [OK] Virtual environment found.
    echo [OK] Launching application...
    echo.
    
    venv\Scripts\python.exe main.py
    
    echo.
    echo Application closed. Press any key to exit...
    pause >nul
) else (
    color 0C
    echo [ERROR] Virtual environment not found!
    echo.
    echo Please run "setup.ps1" as Administrator first:
    echo Right-click on setup.ps1 -^> "Run with PowerShell"
    echo.
    pause
)