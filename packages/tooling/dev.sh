#!/bin/bash
# Development environment setup script for Unix-like systems

echo "🚀 Starting RoBeats Development Environment"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Node.js is installed
if ! command_exists node; then
    echo "❌ Node.js not found. Please install Node.js 18+ and try again."
    exit 1
fi

# Check if Lune is installed
if ! command_exists lune; then
    echo "❌ Lune not found. Please install Lune and try again."
    echo "   Install from: https://github.com/lune-org/lune"
    exit 1
fi

# Check if Rojo is installed
if ! command_exists rojo; then
    echo "❌ Rojo not found. Please install Rojo and try again."
    echo "   Install from: https://rojo.space/docs/installation/"
    exit 1
fi

echo "✅ All required tools found"
echo ""

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
fi

echo "🎮 Starting development servers..."
echo "   - API Server on http://localhost:3000"
echo "   - Rojo Server on http://localhost:34872"
echo ""
echo "Press Ctrl+C to stop all servers"
echo ""

# Start the development environment
npm run dev