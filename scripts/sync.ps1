# PowerShell startup script for Two-Way Sync

Write-Host "🚀 Starting Robeats Two-Way Sync (PowerShell)" -ForegroundColor Green

# Check if lune is available
if (-not (Get-Command lune -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Lune is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Lune: https://github.com/lune-org/lune" -ForegroundColor Yellow
    exit 1
}

# Check if rojo is available
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Rojo is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Rojo: https://rojo.space/docs/installation/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green
Write-Host ""
Write-Host "🔧 Starting Rojo serve in background..." -ForegroundColor Cyan

# Start Rojo serve in the background
Start-Process -NoNewWindow -FilePath "rojo" -ArgumentList "serve", "default.project.json", "--port", "34872"

# Wait a moment for Rojo to start
Start-Sleep -Seconds 2

Write-Host "👀 Starting Studio watcher..." -ForegroundColor Cyan
Write-Host "🛑 Press Ctrl+C to stop both services" -ForegroundColor Yellow
Write-Host ""

# Start the Studio watcher (this will keep the script running)
lune run scripts/studio-watcher.luau
