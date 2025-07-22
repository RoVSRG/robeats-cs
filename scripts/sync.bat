@echo off
REM Batch startup script for Two-Way Sync

echo 🚀 Starting Robeats Two-Way Sync (Batch)

REM Check if lune is available
where lune >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Lune is not installed or not in PATH
    echo Please install Lune: https://github.com/lune-org/lune
    exit /b 1
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
echo 🔧 Starting Rojo serve in background...

REM Start Rojo serve in the background
start /B rojo serve default.project.json --port 34872

REM Wait a moment for Rojo to start
timeout /t 2 /nobreak >nul

echo 👀 Starting Studio watcher...
echo 🛑 Press Ctrl+C to stop both services
echo.

REM Start the Studio watcher (this will keep the script running)
lune run scripts/studio-watcher.luau
