# Initial setup script for RoBeats monorepo (Windows PowerShell)

Write-Host "🎮 RoBeats Monorepo Setup" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""

# Function to check command existence
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

$missing = @()

if (-not (Test-Command "node")) {
    $missing += "Node.js (https://nodejs.org/)"
}

if (-not (Test-Command "git")) {
    $missing += "Git (https://git-scm.com/)"
}

if (-not (Test-Command "lune")) {
    $missing += "Lune (https://github.com/lune-org/lune)"
}

if (-not (Test-Command "rojo")) {
    $missing += "Rojo (https://rojo.space/docs/installation/)"
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required tools:" -ForegroundColor Red
    foreach ($tool in $missing) {
        Write-Host "   - $tool" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please install the missing tools and run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ All prerequisites found!" -ForegroundColor Green
Write-Host ""

# Initialize Git submodules
Write-Host "📦 Initializing Git submodules..." -ForegroundColor Yellow
git submodule update --init --recursive
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to initialize submodules" -ForegroundColor Red
    exit 1
}

# Install Node.js dependencies
Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install Node.js dependencies" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  npm run dev        # Start development environment" -ForegroundColor White
Write-Host "  npm run sync       # Start two-way sync for GUI development" -ForegroundColor White
Write-Host "  npm run build:*    # Build individual components" -ForegroundColor White
Write-Host ""
Write-Host "See README.md for detailed usage instructions." -ForegroundColor Yellow