@echo off
REM Extract from Place File - Batch Launcher

echo 🏗️ Robeats Place File Extractor (Batch)
echo ==================================================

REM Check if lune is available
where lune >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Lune is not installed or not in PATH
    echo Falling back to PowerShell version...
    echo.
    powershell -ExecutionPolicy Bypass -File scripts\extract-from-place.ps1
    goto :end
)

REM Check if rojo is available
where rojo >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Rojo is not installed or not in PATH
    echo Please install Rojo: https://rojo.space/docs/installation/
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

REM Run the Lune extraction script
lune run extract_from_place.luau

:end
pause
