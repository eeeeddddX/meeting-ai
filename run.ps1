$venvPython = Join-Path $PSScriptRoot "venv\Scripts\python.exe"
$mainScript = Join-Path $PSScriptRoot "main.py"

if (Test-Path $venvPython) {
    & $venvPython $mainScript
} else {
    Write-Host "⚠️ Виртуальное окружение не найдено. Запустите setup.ps1" -ForegroundColor Red
    pause
}