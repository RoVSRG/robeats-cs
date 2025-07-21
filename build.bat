@echo off
REM Build script for Windows
echo 🔨 Building robeats-cs-scripts...

REM Check if Lune is available
where lune >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Lune not found. Please install Lune first.
    echo    Visit: https://lune-org.github.io/docs/getting-started/installation
    pause
    exit /b 1
)

REM Run the build script
lune run build.luau

if %errorlevel% equ 0 (
    echo ✅ Build completed successfully!
) else (
    echo ❌ Build failed!
    pause
    exit /b 1
)
