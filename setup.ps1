# Meeting AI - Автоматический установщик
# Запускать от имени администратора!

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Meeting AI - Установщик" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  Запустите этот скрипт от имени администратора!" -ForegroundColor Red
    Write-Host "Правой кнопкой на PowerShell -> Запуск от имени администратора" -ForegroundColor Yellow
    pause
    exit
}

# Шаг 1: Проверка и установка Python
Write-Host "📦 Шаг 1/4: Проверка Python..." -ForegroundColor Green
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Python не найден. Скачиваю..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe" -OutFile "$env:TEMP\python-installer.exe"
    Start-Process -FilePath "$env:TEMP\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_pip=1" -Wait
    Write-Host "✅ Python установлен" -ForegroundColor Green
} else {
    Write-Host "✅ Python найден: $pythonVersion" -ForegroundColor Green
}

# Шаг 2: Проверка и установка Ollama
Write-Host ""
Write-Host " Шаг 2/4: Проверка Ollama..." -ForegroundColor Green
$ollamaVersion = ollama --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ollama не найден. Скачиваю..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile "$env:TEMP\ollama-installer.exe"
    Start-Process -FilePath "$env:TEMP\ollama-installer.exe" -ArgumentList "/S" -Wait
    Write-Host "✅ Ollama установлен" -ForegroundColor Green
} else {
    Write-Host "✅ Ollama найден: $ollamaVersion" -ForegroundColor Green
}

# Шаг 3: Установка модели Qwen2.5
Write-Host ""
Write-Host "📦 Шаг 3/4: Установка модели Qwen2.5:7b (4.7 ГБ)..." -ForegroundColor Green
Write-Host "Это займёт 5-15 минут в зависимости от скорости интернета..." -ForegroundColor Yellow
ollama pull qwen2.5:7b
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Модель установлена" -ForegroundColor Green
} else {
    Write-Host "❌ Ошибка установки модели" -ForegroundColor Red
}

# Шаг 4: Создание виртуального окружения и установка зависимостей
Write-Host ""
Write-Host " Шаг 4/4: Установка Python-библиотек..." -ForegroundColor Green
$venvPath = Join-Path $PSScriptRoot "venv"
if (-not (Test-Path $venvPath)) {
    python -m venv $venvPath
}
& "$venvPath\Scripts\pip.exe" install --upgrade pip
& "$venvPath\Scripts\pip.exe" install -r (Join-Path $PSScriptRoot "requirements.txt")
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Библиотеки установлены" -ForegroundColor Green
} else {
    Write-Host "❌ Ошибка установки библиотек" -ForegroundColor Red
}

# Создание ярлыка для запуска
Write-Host ""
Write-Host "🎉 Создание ярлыка..." -ForegroundColor Green
$shortcutPath = [System.IO.Path]::Combine($PSScriptRoot, "Meeting AI.lnk")
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PSScriptRoot\run.ps1`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Save()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ Установка завершена!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Запуск:" -ForegroundColor Yellow
Write-Host "  • Дважды кликните на 'Meeting AI.lnk'" -ForegroundColor White
Write-Host "  • Или запустите run.ps1" -ForegroundColor White
Write-Host ""
pause