# Development environment setup script for Windows PowerShell

Write-Host "🚀 Starting RoBeats Development Environment" -ForegroundColor Green
Write-Host ""

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js not found. Please install Node.js 18+ and try again." -ForegroundColor Red
    exit 1
}

# Check if Lune is installed
if (-not (Get-Command lune -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Lune not found. Please install Lune and try again." -ForegroundColor Red
    Write-Host "   Install from: https://github.com/lune-org/lune" -ForegroundColor Yellow
    exit 1
}

# Check if Rojo is installed
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Rojo not found. Please install Rojo and try again." -ForegroundColor Red
    Write-Host "   Install from: https://rojo.space/docs/installation/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ All required tools found" -ForegroundColor Green
Write-Host ""

# Check if dependencies are installed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

Write-Host "🎮 Starting development servers..." -ForegroundColor Blue
Write-Host "   - API Server on http://localhost:3000" -ForegroundColor Cyan
Write-Host "   - Rojo Server on http://localhost:34872" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop all servers" -ForegroundColor Yellow
Write-Host ""

# Start the development environment
npm run dev