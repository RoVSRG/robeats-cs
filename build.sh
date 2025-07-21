#!/bin/bash
# Build script for robeats-cs-scripts

echo "🔨 Building robeats-cs-scripts..."

# Clean dist directory
echo "🧹 Cleaning dist directory..."
rm -rf dist
mkdir -p dist

# Transform source files using Lune
if ! lune run transform.luau; then
    echo "❌ File transformation failed"
    exit 1
fi

# Build with Rojo
echo "🏗️ Building place file with Rojo..."
if ! rojo build --output robeats-cs-built.rbxl build.project.json; then
    echo "❌ Rojo build failed"
    exit 1
fi

echo "✅ Build complete! Output: robeats-cs-built.rbxl"
echo "📦 You can now sync this file to Roblox Studio or upload it to Roblox."
