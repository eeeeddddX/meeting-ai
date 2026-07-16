@echo off
title Meeting AI
color 0A

echo ====================================================
echo   Starting Meeting AI
echo ====================================================
echo.

if not exist "venv\Scripts\python.exe" (
    color 0C
    echo [ERROR] Application not installed!
    echo.
    echo First run "install.bat" as Administrator.
    echo.
    pause
    exit /b 1
)

echo [OK] Starting application...
echo.
call venv\Scripts\activate
python main.py

if errorlevel 1 (
    color 0C
    echo.
    echo [ERROR] Application crashed!
    echo.
    pause
)