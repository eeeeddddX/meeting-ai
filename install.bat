@echo off
chcp 65001 >nul
title Meeting AI - Installer
color 0B

echo ==========================================
echo   Meeting AI - Installation
echo ==========================================
echo.
echo IMPORTANT: Right-click this file and select "Run as administrator"
pause

echo [1/4] Checking Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Python not found!
    echo Please install Python from python.org and check "Add to PATH"
    pause
    exit /b
)
echo [OK] Python found.

echo [2/4] Checking Ollama...
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [INSTALL] Downloading and installing Ollama...
    curl -L https://ollama.com/download/OllamaSetup.exe -o %TEMP%\ollama.exe
    start /wait %TEMP%\ollama.exe /S
)
echo [OK] Ollama is ready.

echo [3/4] Downloading AI model (4.7 GB)...
echo THIS WILL TAKE 5-15 MINUTES. Do not close this window!
ollama pull qwen2.5:7b
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Failed to download model. Check internet and try again.
    pause
    exit /b
)

echo [4/4] Creating virtual environment and installing libs...
python -m venv venv
call venv\Scripts\activate
pip install --upgrade pip >nul
pip install -r requirements.txt

color 0A
echo.
echo ==========================================
echo   INSTALLATION COMPLETE!
echo ==========================================
echo Now double-click "run.bat" to start the app.
pause