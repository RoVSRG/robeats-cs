# PowerShell file watcher script
Write-Host "👀 Starting file watcher for src/ directory..." -ForegroundColor Green
Write-Host "📁 Files will be automatically transformed to dist/ on change" -ForegroundColor Cyan
Write-Host "🛑 Press Ctrl+C to stop" -ForegroundColor Yellow

# Ensure dist directory exists
if (!(Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" | Out-Null
}

# Check if Lune is available
try {
    $null = Get-Command lune -ErrorAction Stop
    Write-Host "🔄 Starting Lune file watcher..." -ForegroundColor Blue
    & lune run watch.luau
} catch {
    Write-Host "❌ Lune not found. Please install Lune first." -ForegroundColor Red
    Write-Host "   Visit: https://lune-org.github.io/docs/getting-started/installation" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
