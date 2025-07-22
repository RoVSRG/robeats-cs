#!/bin/bash
# Extract from Place File - Bash Script

echo "🏗️ Robeats Place File Extractor (Bash)"
echo "=================================================="

# Check if lune is available
if ! command -v lune &> /dev/null; then
    echo "❌ Lune is not installed or not in PATH"
    echo "Please install Lune: https://github.com/lune-org/lune"
    exit 1
fi

# Check if rojo is available
if ! command -v rojo &> /dev/null; then
    echo "❌ Rojo is not installed or not in PATH"
    echo "Please install Rojo: https://rojo.space/docs/installation/"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Run the Lune extraction script
lune run extract_from_place.luau
