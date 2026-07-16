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
    echo Запустите файл setup.bat:
    echo 1. Дважды кликните на setup.bat
    echo 2. Нажмите "Да" в окне запроса прав
    echo 3. Дождитесь окончания установки
    echo.
    pause
    exit /b 1
)

:: Запускаем Ollama сервер (если не запущен)
echo [OK] Проверка Ollama...
ollama list >nul 2>&1
if errorlevel 1 (
    echo [OK] Запуск Ollama сервера...
    start /B ollama serve
    timeout /t 3 /nobreak >nul
)

:: Запускаем приложение
echo [OK] Запуск приложения...
echo.
venv\Scripts\python.exe main.py

if errorlevel 1 (
    color 0C
    echo.
    echo [ОШИБКА] Приложение завершилось с ошибкой!
    echo.
    pause
    exit /b 1
)

pause >nul