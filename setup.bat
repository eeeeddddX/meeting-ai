@echo off
title Meeting AI - Installer
color 0B

:: Проверяем права администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ============================================
    echo    Запрос прав администратора...
    echo ============================================
    echo.
    echo Сейчас откроется окно с запросом прав.
    echo Нажмите "Да" для продолжения установки.
    echo.
    pause
    
    :: Перезапуск с правами админа
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Если мы здесь — права есть, запускаем ps1
echo ============================================
echo    Meeting AI - Установка
echo ============================================
echo.
echo [OK] Права администратора получены.
echo [OK] Запуск установщика...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

echo.
echo Установка завершена.
pause