# Meeting AI - Установщик
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Meeting AI - Установка" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Проверка админских прав
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] Запустите от имени администратора!" -ForegroundColor Red
    Write-Host "Правой кнопкой на setup.ps1 -> Запуск от имени администратора" -ForegroundColor Yellow
    pause
    exit 1
}

# Python
Write-Host "[1/4] Проверка Python..." -ForegroundColor Green
try {
    $pythonVer = python --version 2>&1
    Write-Host "[OK] Python найден: $pythonVer" -ForegroundColor Green
} catch {
    Write-Host "[INSTALL] Установка Python..." -ForegroundColor Yellow
    Start-Process "https://www.python.org/downloads/" 
    Write-Host "Установите Python и отметьте 'Add Python to PATH'" -ForegroundColor Yellow
    Write-Host "После установки запустите setup.ps1 снова" -ForegroundColor Yellow
    pause
    exit 0
}

# Ollama
Write-Host ""
Write-Host "[2/4] Проверка Ollama..." -ForegroundColor Green
try {
    ollama --version | Out-Null
    Write-Host "[OK] Ollama установлена" -ForegroundColor Green
} catch {
    Write-Host "[INSTALL] Установка Ollama..." -ForegroundColor Yellow
    Invoke-WebRequest "https://ollama.com/download/OllamaSetup.exe" -OutFile "$env:TEMP\ollama.exe"
    Start-Process "$env:TEMP\ollama.exe" -ArgumentList "/S" -Wait
    Write-Host "[OK] Ollama установлена" -ForegroundColor Green
}

# Модель
Write-Host ""
Write-Host "[3/4] Установка модели (4.7 ГБ)..." -ForegroundColor Green
Write-Host "Это займёт 5-15 минут..." -ForegroundColor Yellow
ollama pull qwen2.5:7b
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Модель установлена" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Ошибка установки модели" -ForegroundColor Red
    pause
    exit 1
}

# venv
Write-Host ""
Write-Host "[4/4] Установка библиотек..." -ForegroundColor Green
if (Test-Path "venv") {
    Write-Host "[OK] Virtual environment существует" -ForegroundColor Green
} else {
    python -m venv venv
}
& "venv\Scripts\pip.exe" install --upgrade pip | Out-Null
& "venv\Scripts\pip.exe" install -r requirements.txt
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Библиотеки установлены" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Ошибка установки библиотек" -ForegroundColor Red
    pause
    exit 1
}

# Создание ярлыка
Write-Host ""
Write-Host "[FINAL] Создание ярлыка..." -ForegroundColor Green
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PSScriptRoot\Meeting AI.lnk")
$Shortcut.TargetPath = "cmd.exe"
$Shortcut.Arguments = "/c `"$PSScriptRoot\Запустить.bat`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = "shell32.dll,13"
$Shortcut.Description = "Meeting AI - Анализ совещаний"
$Shortcut.Save()

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  УСТАНОВКА ЗАВЕРШЕНА!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Запуск:" -ForegroundColor Yellow
Write-Host "  - Дважды кликните на 'Meeting AI.lnk'" -ForegroundColor White
Write-Host "  - Или на 'Запустить.bat'" -ForegroundColor White
Write-Host ""
Write-Host "Удалить установку:" -ForegroundColor Yellow
Write-Host "  - Удалите папку venv" -ForegroundColor White
Write-Host "  - ollama rm qwen2.5:7b" -ForegroundColor White
Write-Host ""
pause