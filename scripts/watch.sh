#!/bin/bash
# File watcher script using fswatch for automatic transformation

echo "👀 Starting file watcher for src/ directory..."
echo "📁 Files will be automatically transformed to dist/ on change"
echo "🛑 Press Ctrl+C to stop"

# Ensure dist directory exists
mkdir -p dist

# Initial transformation
echo "🔄 Performing initial transformation..."
lune run transform.luau
echo "✅ Initial transformation complete"

# Function to transform a single file
transform_single_file() {
    local changed_file="$1"
    
    # Check if it's a lua/luau file in src/
    if [[ "$changed_file" == src/*.lua ]] || [[ "$changed_file" == src/*.luau ]]; then
        echo "🔄 File changed: $changed_file"
        
        # Get relative path from src/
        local rel_path="${changed_file#src/}"
        local output_file="dist/$rel_path"
        
        # Create output directory if needed
        mkdir -p "$(dirname "$output_file")"
        
        # Transform the file
        echo "   Transforming to: $output_file"
        
        # Use sed to transform @shared/ imports (same logic as in build.sh)
        sed -e 's|require("@shared/\([^"]*\)")|require(game.ReplicatedStorage.\1)|g' \
            -e "s|require('@shared/\([^']*\)')|require(game.ReplicatedStorage.\1)|g" \
            "$changed_file" | \
        sed -e 's|game\.ReplicatedStorage\.\([^)]*\)/|game.ReplicatedStorage.\1.|g' \
            -e 's|game\.ReplicatedStorage\.\([^)]*\)/|game.ReplicatedStorage.\1.|g' \
            -e 's|game\.ReplicatedStorage\.\([^)]*\)/|game.ReplicatedStorage.\1.|g' > "$output_file"
        
        echo "   ✅ Transformed: $rel_path"
    fi
}

# Check if fswatch is available
if command -v fswatch >/dev/null 2>&1; then
    echo "Using fswatch for file monitoring..."
    fswatch -o src/ | while read f; do
        # On change, run full transformation (simpler approach)
        echo "🔄 Changes detected, running transformation..."
        lune run transform.luau
    done
elif command -v inotifywait >/dev/null 2>&1; then
    echo "Using inotifywait for file monitoring..."
    inotifywait -m -r -e modify,create,delete src/ --format '%w%f' | while read changed_file; do
        transform_single_file "$changed_file"
    done
else
    echo "⚠️  No file watcher available (fswatch/inotifywait)"
    echo "   Installing fswatch: brew install fswatch"
    echo "   Or use the Lune-based watcher: lune run watch.luau"
    echo ""
    echo "🔄 Falling back to simple polling..."
    while true; do
        sleep 2
        lune run transform.luau >/dev/null 2>&1
    done
fi
