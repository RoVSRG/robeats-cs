#!/bin/bash
# Cross-platform startup script for Two-Way Sync

echo "🚀 Starting Robeats Two-Way Sync (Bash)"

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
echo "🔧 Starting Rojo serve in background..."

# Start Rojo serve in the background
rojo serve default.project.json --port 34872 &

# Wait a moment for Rojo to start
sleep 2

echo "👀 Starting Studio watcher..."
echo "🛑 Press Ctrl+C to stop both services"
echo ""

# Start the Studio watcher (this will keep the script running)
lune run scripts/studio-watcher.luau
