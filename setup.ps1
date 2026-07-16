# Meeting AI - Установщик
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Meeting AI - Установка" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Проверка админских прав
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] Запустите от имени администратора!" -ForegroundColor Red
    Write-Host "Правой кнопкой на setup.bat -> Запуск от имени администратора" -ForegroundColor Yellow
    pause
    exit 1
}

# Python
Write-Host "[1/4] Проверка Python..." -ForegroundColor Green
try {
    $pythonVer = python --version 2>&1
    Write-Host "[OK] Python найден: $pythonVer" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python не установлен!" -ForegroundColor Red
    Write-Host "Скачайте с https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "При установке отметьте 'Add Python to PATH'" -ForegroundColor Yellow
    pause
    exit 1
}

# Ollama
Write-Host ""
Write-Host "[2/4] Проверка Ollama..." -ForegroundColor Green
$ollamaInstalled = $false
try {
    $ollamaVer = ollama --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Ollama установлена: $ollamaVer" -ForegroundColor Green
        $ollamaInstalled = $true
    }
} catch {}

if (-not $ollamaInstalled) {
    Write-Host "[INSTALL] Установка Ollama..." -ForegroundColor Yellow
    Write-Host "Скачиваю установщик..." -ForegroundColor Yellow
    Invoke-WebRequest "https://ollama.com/download/OllamaSetup.exe" -OutFile "$env:TEMP\ollama.exe" -UseBasicParsing
    Write-Host "Запускаю установщик Ollama..." -ForegroundColor Yellow
    Start-Process "$env:TEMP\ollama.exe" -ArgumentList "/S" -Wait
    Write-Host "[OK] Ollama установлена" -ForegroundColor Green
}

# Запуск Ollama сервера (ВАЖНО!)
Write-Host ""
Write-Host "[2.5] Запуск Ollama сервера..." -ForegroundColor Green
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Проверяем, запущена ли Ollama
$ollamaRunning = $false
try {
    ollama list 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ollamaRunning = $true
        Write-Host "[OK] Ollama сервер уже запущен" -ForegroundColor Green
    }
} catch {}

if (-not $ollamaRunning) {
    Write-Host "Запускаю Ollama сервер..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5  # Ждём запуска
    
    # Проверяем снова
    try {
        ollama list 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Ollama сервер запущен" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Ollama не отвечает. Попробуйте перезапустить компьютер." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Ollama не отвечает. Попробуйте перезапустить компьютер." -ForegroundColor Yellow
    }
}

# Модель
Write-Host ""
Write-Host "[3/4] Установка модели (4.7 ГБ)..." -ForegroundColor Green
Write-Host "Это займёт 5-15 минут. Не закрывайте окно!" -ForegroundColor Yellow
Write-Host ""

# Проверяем, есть ли уже модель
$modelExists = $false
try {
    $models = ollama list 2>&1
    if ($models -like "*qwen2.5*") {
        $modelExists = $true
        Write-Host "[OK] Модель qwen2.5:7b уже установлена" -ForegroundColor Green
    }
} catch {}

if (-not $modelExists) {
    Write-Host "Скачиваю модель..." -ForegroundColor Yellow
    ollama pull qwen2.5:7b
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Модель установлена" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Ошибка установки модели" -ForegroundColor Red
        Write-Host "Попробуйте запустить setup.bat ещё раз" -ForegroundColor Yellow
        pause
        exit 1
    }
}

# venv
Write-Host ""
Write-Host "[4/4] Установка библиотек..." -ForegroundColor Green
if (Test-Path "venv") {
    Write-Host "[OK] Virtual environment существует" -ForegroundColor Green
} else {
    Write-Host "Создаю virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

Write-Host "Устанавливаю библиотеки..." -ForegroundColor Yellow
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
Write-Host "[OK] Ярлык создан" -ForegroundColor Green

# Итог
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  УСТАНОВКА ЗАВЕРШЕНА!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Теперь запустите:" -ForegroundColor Yellow
Write-Host "  - Meeting AI.lnk (ярлык)" -ForegroundColor White
Write-Host "  - или Запустить.bat" -ForegroundColor White
Write-Host ""
pause