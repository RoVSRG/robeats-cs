# PowerShell build script
Write-Host "🔨 Building robeats-cs-scripts..." -ForegroundColor Green

# Check if Lune is available
try {
    $null = Get-Command lune -ErrorAction Stop
    Write-Host "🔄 Running build..." -ForegroundColor Blue
    
    & lune run build.luau
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Host "❌ Lune not found. Please install Lune first." -ForegroundColor Red
    Write-Host "   Visit: https://lune-org.github.io/docs/getting-started/installation" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
