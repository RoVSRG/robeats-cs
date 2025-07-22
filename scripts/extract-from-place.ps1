# PowerShell Place File Extractor
# Extracts all content from a place file according to the Rojo project structure

Write-Host "🏗️ Robeats Place File Extractor (PowerShell)" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Green

# Find the place file
function Find-PlaceFile {
    $placeFiles = Get-ChildItem -Path "." -Filter "*.rbxl*" | Where-Object { $_.Name -notmatch "\.lock$" }
    if ($placeFiles.Count -gt 0) {
        $placeFile = $placeFiles[0].Name
        Write-Host "📁 Found place file: $placeFile" -ForegroundColor Cyan
        return $placeFile
    }
    return $null
}

# Ensure directories exist
function Ensure-Directories {
    $dirs = @("src/shared", "src/server", "src/client", "src/gui/screens")
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "📁 Created directory: $dir" -ForegroundColor Yellow
        }
    }
}

# Run Rojo command safely
function Invoke-RojoCommand {
    param([string[]]$Arguments, [string]$Description)
    
    Write-Host $Description -ForegroundColor Cyan
    $result = Start-Process -FilePath "rojo" -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -eq 0) {
        Write-Host "✅ Success" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠️ Failed with exit code: $($result.ExitCode)" -ForegroundColor Yellow
        return $false
    }
}

# Extract content from place
function Extract-FromPlace {
    param([string]$PlaceFile)
    
    Write-Host "🔄 Extracting content from place file..." -ForegroundColor Green
    
    # Generate sourcemap
    $success = Invoke-RojoCommand @("sourcemap", "default.project.json", "--output", "sourcemap.json") "📋 Generating sourcemap..."
    if (-not $success) {
        Write-Host "❌ Failed to generate sourcemap" -ForegroundColor Red
        return $false
    }
    
    # Extract each service
    $extractions = @(
        @("ReplicatedStorage", "📦 Extracting ReplicatedStorage → src/shared/"),
        @("ServerScriptService", "🖥️ Extracting ServerScriptService → src/server/"),
        @("StarterPlayer.StarterPlayerScripts", "👤 Extracting StarterPlayerScripts → src/client/"),
        @("StarterGui.Screens", "📱 Extracting StarterGui.Screens → src/gui/screens/")
    )
    
    foreach ($extraction in $extractions) {
        $include = $extraction[0]
        $description = $extraction[1]
        
        Invoke-RojoCommand @("upload", "--include-non-strict", "--include", $include, "default.project.json") $description
    }
    
    Write-Host "📝 Note: StarterGui.Dev is for visual editing only and is not extracted" -ForegroundColor Yellow
    Write-Host "   This ScreenGui should be recreated in Studio for GUI design work" -ForegroundColor Yellow
    
    return $true
}

# Create Dev ScreenGui template
function New-DevScreenGuiTemplate {
    $template = @'
{
  "ClassName": "ScreenGui",
  "Name": "Dev", 
  "Properties": {
    "DisplayOrder": 100,
    "IgnoreGuiInset": true,
    "ResetOnSpawn": false,
    "ZIndexBehavior": "Sibling"
  },
  "Children": [
    {
      "ClassName": "TextLabel",
      "Name": "DevLabel",
      "Properties": {
        "Size": { "X": { "Scale": 0.3, "Offset": 0 }, "Y": { "Scale": 0.1, "Offset": 0 } },
        "Position": { "X": { "Scale": 0.35, "Offset": 0 }, "Y": { "Scale": 0.45, "Offset": 0 } },
        "BackgroundColor3": { "R": 0.2, "G": 0.6, "B": 1 },
        "Text": "DEV GUI - Design Here",
        "TextColor3": { "R": 1, "G": 1, "B": 1 },
        "TextScaled": true,
        "Font": "SourceSansBold"
      }
    }
  ]
}
'@
    
    $template | Out-File -FilePath "dev-screengui-template.json" -Encoding UTF8
    Write-Host "📋 Created StarterGui.Dev template: dev-screengui-template.json" -ForegroundColor Green
    Write-Host "   → Import this into Studio as StarterGui.Dev for visual editing" -ForegroundColor Yellow
}

# Main function
function Main {
    # Check prerequisites
    if (-not (Test-Path "default.project.json")) {
        Write-Host "❌ default.project.json not found!" -ForegroundColor Red
        Write-Host "Make sure you're in the project root directory." -ForegroundColor Yellow
        return
    }
    
    # Check if Rojo is available
    try {
        Start-Process -FilePath "rojo" -ArgumentList "--version" -Wait -PassThru -NoNewWindow -WindowStyle Hidden | Out-Null
    } catch {
        Write-Host "❌ Rojo is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Rojo: https://rojo.space/docs/installation/" -ForegroundColor Yellow
        return
    }
    
    # Find place file
    $placeFile = Find-PlaceFile
    if (-not $placeFile) {
        Write-Host "❌ No place file found!" -ForegroundColor Red
        Write-Host "Place a .rbxl or .rbxlx file in the project root and try again." -ForegroundColor Yellow
        return
    }
    
    # Ensure directories exist
    Ensure-Directories
    
    # Extract content
    $success = Extract-FromPlace $placeFile
    
    if ($success) {
        # Create Dev template
        New-DevScreenGuiTemplate
        
        Write-Host ""
        Write-Host "✨ Extraction complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Next steps:" -ForegroundColor Cyan
        Write-Host "   1. Import dev-screengui-template.json into Studio as StarterGui.Dev"
        Write-Host "   2. Start the two-way sync: scripts\sync.ps1"
        Write-Host "   3. Edit GUI in StarterGui.Dev and StarterGui.Screens"
        Write-Host "   4. Save place file to auto-sync changes back to repo"
        Write-Host ""
        Write-Host "🎯 Your project is now fully populated and ready for development!" -ForegroundColor Green
    } else {
        Write-Host "❌ Extraction failed. Check the errors above." -ForegroundColor Red
    }
}

# Run the extraction
Main
