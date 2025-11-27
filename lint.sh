#!/bin/bash
# Lint script for robeats-cs using luau-lsp
# Usage: ./lint.sh [files...] or ./lint.sh (for all source files)

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Regenerate sourcemap if project file changed
if [ default.project.json -nt sourcemap.json ]; then
    echo -e "${YELLOW}Regenerating sourcemap...${NC}"
    rojo sourcemap default.project.json --output sourcemap.json
fi

# Determine files to analyze
if [ $# -eq 0 ]; then
    echo -e "${GREEN}Analyzing all source files...${NC}"
    FILES="src"
else
    FILES="$@"
fi

# Run analysis
luau-lsp analyze \
    --sourcemap=sourcemap.json \
    --definitions=@roblox=.luau-lsp/globalTypes.d.lua \
    --formatter=plain \
    $FILES 2>&1 | grep -E "^(src/|Packages/)" | grep -v "Packages/_Index"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ No errors found${NC}"
else
    echo -e "${RED}✗ Type errors found${NC}"
    exit 1
fi
