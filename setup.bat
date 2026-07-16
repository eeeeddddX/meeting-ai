@echo off
title Meeting AI - Installer
color 0B

echo ====================================================
echo   Meeting AI - Installation
echo ====================================================
echo.
echo IMPORTANT: Run this file as Administrator!
echo Right-click -^> Run as administrator
echo.
pause

echo [1/4] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo [ERROR] Python not found!
    echo Opening Python download page...
    start https://www.python.org/downloads/
    echo.
    echo After installing Python (with "Add to PATH" checked), run install.bat again.
    pause
    exit /b
)
echo [OK] Python found.

echo.
echo [2/4] Checking Ollama...
ollama --version >nul 2>&1
if errorlevel 1 (
    echo [INSTALL] Downloading Ollama...
    curl -L https://ollama.com/download/OllamaSetup.exe -o %TEMP%\ollama.exe
    echo [INSTALL] Running Ollama installer...
    start /wait %TEMP%\ollama.exe /S
    echo [OK] Ollama installed.
) else (
    echo [OK] Ollama already installed.
)

echo.
echo [3/4] Downloading AI model (4.7 GB)...
echo THIS WILL TAKE 5-15 MINUTES. Do not close this window!
ollama pull qwen2.5:7b
if errorlevel 1 (
    color 0C
    echo [ERROR] Failed to download model. Check internet and run install.bat again.
    pause
    exit /b
)
echo [OK] Model downloaded successfully.

echo.
echo [4/4] Installing Python libraries...
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)
call venv\Scripts\activate
echo Updating pip...
python -m pip install --upgrade pip >nul
echo Installing libraries...
pip install -r requirements.txt
if errorlevel 1 (
    color 0C
    echo [ERROR] Failed to install libraries.
    pause
    exit /b
)
echo [OK] Libraries installed.

color 0A
echo.
echo ====================================================
echo   INSTALLATION COMPLETE!
echo ====================================================
echo.
echo Now double-click "run.bat" to start the application.
echo.
pause