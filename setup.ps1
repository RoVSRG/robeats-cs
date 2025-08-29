# This script will initialize everything for you.

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js is not installed. Installing via winget..."
    winget install OpenJS.NodeJS --accept-source-agreements --accept-package-agreements
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Verify npm and npx are available (they come with Node.js)
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "npm is not available. Please ensure Node.js is properly installed."
    exit 1
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "npx is not available. Please ensure Node.js is properly installed."
    exit 1
}

node scripts/setup.mjs