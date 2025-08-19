#!/bin/bash
# Initial setup script for RoBeats monorepo (Unix-like systems)

echo "🎮 RoBeats Monorepo Setup"
echo "========================="
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

missing=()

if ! command_exists node; then
    missing+=("Node.js (https://nodejs.org/)")
fi

if ! command_exists git; then
    missing+=("Git (https://git-scm.com/)")
fi

if ! command_exists lune; then
    missing+=("Lune (https://github.com/lune-org/lune)")
fi

if ! command_exists rojo; then
    missing+=("Rojo (https://rojo.space/docs/installation/)")
fi

if [ ${#missing[@]} -gt 0 ]; then
    echo "❌ Missing required tools:"
    for tool in "${missing[@]}"; do
        echo "   - $tool"
    done
    echo ""
    echo "Please install the missing tools and run this script again."
    exit 1
fi

echo "✅ All prerequisites found!"
echo ""

# Initialize Git submodules
echo "📦 Initializing Git submodules..."
git submodule update --init --recursive
if [ $? -ne 0 ]; then
    echo "❌ Failed to initialize submodules"
    exit 1
fi

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install Node.js dependencies"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  npm run dev        # Start development environment"
echo "  npm run sync       # Start two-way sync for GUI development"
echo "  npm run build:*    # Build individual components"
echo ""
echo "See README.md for detailed usage instructions."