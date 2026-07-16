# Meeting AI - Installer
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Meeting AI - Installation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Admin check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] Please run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click on setup.bat -> Run as administrator" -ForegroundColor Yellow
    pause
    exit 1
}

# 1. Python
Write-Host "[1/4] Checking Python..." -ForegroundColor Green
try {
    $pythonVer = python --version 2>&1
    Write-Host "[OK] Python found: $pythonVer" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python is not installed!" -ForegroundColor Red
    Write-Host "Download from https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "IMPORTANT: Check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    pause
    exit 1
}

# 2. Ollama
Write-Host ""
Write-Host "[2/4] Checking Ollama..." -ForegroundColor Green
$ollamaInstalled = $false
try {
    $ollamaVer = ollama --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Ollama found: $ollamaVer" -ForegroundColor Green
        $ollamaInstalled = $true
    }
} catch {}

if (-not $ollamaInstalled) {
    Write-Host "[INSTALL] Installing Ollama..." -ForegroundColor Yellow
    Invoke-WebRequest "https://ollama.com/download/OllamaSetup.exe" -OutFile "$env:TEMP\ollama.exe" -UseBasicParsing
    Start-Process "$env:TEMP\ollama.exe" -ArgumentList "/S" -Wait
    Write-Host "[OK] Ollama installed" -ForegroundColor Green
}

# Start Ollama server
Write-Host ""
Write-Host "[2.5] Starting Ollama server..." -ForegroundColor Green
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$ollamaRunning = $false
try {
    ollama list 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ollamaRunning = $true
        Write-Host "[OK] Ollama server is already running" -ForegroundColor Green
    }
} catch {}

if (-not $ollamaRunning) {
    Write-Host "Starting Ollama server in background..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    
    try {
        ollama list 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Ollama server started successfully" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Ollama is not responding. You may need to restart your PC." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Ollama is not responding. You may need to restart your PC." -ForegroundColor Yellow
    }
}

# 3. Model
Write-Host ""
Write-Host "[3/4] Installing model (4.7 GB)..." -ForegroundColor Green
Write-Host "This may take 5-15 minutes. Please wait..." -ForegroundColor Yellow

$modelExists = $false
try {
    $models = ollama list 2>&1
    if ($models -like "*qwen2.5*") {
        $modelExists = $true
        Write-Host "[OK] Model qwen2.5:7b is already installed" -ForegroundColor Green
    }
} catch {}

if (-not $modelExists) {
    Write-Host "Downloading model..." -ForegroundColor Yellow
    ollama pull qwen2.5:7b
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Model installed successfully" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to install model" -ForegroundColor Red
        Write-Host "Try running setup.bat again" -ForegroundColor Yellow
        pause
        exit 1
    }
}

# 4. Virtual Environment
Write-Host ""
Write-Host "[4/4] Setting up Python environment..." -ForegroundColor Green
if (Test-Path "venv") {
    Write-Host "[OK] Virtual environment exists" -ForegroundColor Green
} else {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

Write-Host "Installing libraries..." -ForegroundColor Yellow
& "venv\Scripts\pip.exe" install --upgrade pip | Out-Null
& "venv\Scripts\pip.exe" install -r requirements.txt

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Libraries installed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to install libraries" -ForegroundColor Red
    pause
    exit 1
}

# Create Shortcut
Write-Host ""
Write-Host "[FINAL] Creating desktop shortcut..." -ForegroundColor Green
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PSScriptRoot\Meeting AI.lnk")
$Shortcut.TargetPath = "cmd.exe"
$Shortcut.Arguments = "/c `"$PSScriptRoot\Запустить.bat`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = "shell32.dll,13"
$Shortcut.Description = "Meeting AI"
$Shortcut.Save()
Write-Host "[OK] Shortcut created" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now run the application:" -ForegroundColor Yellow
Write-Host "  - Double-click 'Meeting AI.lnk'" -ForegroundColor White
Write-Host "  - Or double-click 'Запустить.bat'" -ForegroundColor White
Write-Host ""
pause