@echo off
title Meeting AI
color 0A

echo ============================================
echo    Meeting AI - Запуск
echo ============================================
echo.

:: Проверяем venv
if not exist "venv\Scripts\python.exe" (
    color 0C
    echo [ОШИБКА] Приложение не установлено!
    echo.
    echo Запустите файл setup.ps1:
    echo 1. Правой кнопкой на setup.ps1
    echo 2. "Выполнить с помощью PowerShell"
    echo 3. Дождитесь окончания установки
    echo.
    pause
    exit /b 1
)

:: Запускаем
echo [OK] Запуск...
echo.
venv\Scripts\python.exe main.py

pause >nul