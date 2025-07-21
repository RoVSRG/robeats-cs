@echo off
REM File watcher script for Windows
echo 👀 Starting file watcher for src/ directory...
echo 📁 Files will be automatically transformed to dist/ on change
echo 🛑 Press Ctrl+C to stop

REM Ensure dist directory exists
if not exist "dist" mkdir dist

REM Check if Lune is available
where lune >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Lune not found. Please install Lune first.
    echo    Visit: https://lune-org.github.io/docs/getting-started/installation
    pause
    exit /b 1
)

REM Run the Lune-based file watcher
echo 🔄 Starting Lune file watcher...
lune run watch.luau
