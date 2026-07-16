@echo off
chcp 65001 >nul
title Meeting AI
color 0A

if not exist "venv\Scripts\python.exe" (
    color 0C
    echo [ERROR] Not installed!
    echo Please run "install.bat" as Administrator first.
    pause
    exit /b
)

echo [OK] Starting Meeting AI...
echo.
call venv\Scripts\activate
python main.py

if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERROR] Application crashed. Check logs above.
    pause
)