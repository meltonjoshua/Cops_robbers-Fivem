#!/bin/bash

# Test script for Cops & Robbers FiveM resource

echo "🧪 Testing Cops & Robbers FiveM Resource"
echo "========================================"

# Function to check file
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
        return 0
    else
        echo "❌ $1 (missing)"
        return 1
    fi
}

# Function to check syntax
check_lua_syntax() {
    if command -v luac >/dev/null 2>&1; then
        if luac -p "$1" >/dev/null 2>&1; then
            echo "✅ $1 (syntax OK)"
            return 0
        else
            echo "❌ $1 (syntax error)"
            return 1
        fi
    else
        echo "⚠️  $1 (luac not available, skipping syntax check)"
        return 0
    fi
}

# Function to check HTML syntax
check_html_syntax() {
    # Basic HTML validation - check for proper tags
    if grep -q "<!DOCTYPE html>" "$1" && grep -q "</html>" "$1"; then
        echo "✅ $1 (structure OK)"
        return 0
    else
        echo "❌ $1 (structure issues)"
        return 1
    fi
}

echo
echo "📋 Checking file structure..."

# Check all required files
files_missing=0

# Lua files
lua_files=(
    "fxmanifest.lua"
    "config.lua"
    "server/main.lua"
    "server/game.lua"
    "server/version.lua"
    "client/main.lua"
    "client/blips.lua"
    "client/arrest.lua"
    "client/character_selection.lua"
)

for file in "${lua_files[@]}"; do
    if ! check_file "$file"; then
        files_missing=$((files_missing + 1))
    fi
done

# HTML/CSS/JS files
web_files=(
    "html/ui.html"
    "html/style.css"
    "html/script.js"
    "html/character_selection.html"
    "html/character_selection.css"
    "html/character_selection.js"
)

for file in "${web_files[@]}"; do
    if ! check_file "$file"; then
        files_missing=$((files_missing + 1))
    fi
done

# Other files
other_files=(
    "README.md"
    "install.sh"
)

for file in "${other_files[@]}"; do
    if ! check_file "$file"; then
        files_missing=$((files_missing + 1))
    fi
done

echo
echo "🔍 Checking syntax..."

# Check Lua syntax
for file in "${lua_files[@]}"; do
    if [ -f "$file" ]; then
        check_lua_syntax "$file"
    fi
done

# Check HTML structure
if [ -f "html/ui.html" ]; then
    check_html_syntax "html/ui.html"
fi

echo
echo "📊 Test Results:"
echo "================"

if [ $files_missing -eq 0 ]; then
    echo "✅ All files present"
else
    echo "❌ $files_missing file(s) missing"
fi

# Check for common configuration issues
echo
echo "⚙️  Configuration Check:"
echo "========================"

if [ -f "config.lua" ]; then
    # Check if basic config values are set
    if grep -q "Config.GameDuration" config.lua; then
        echo "✅ Game duration configured"
    else
        echo "❌ Game duration not found in config"
    fi
    
    if grep -q "Config.CopSpawns" config.lua; then
        echo "✅ Cop spawns configured"
    else
        echo "❌ Cop spawns not found in config"
    fi
    
    if grep -q "Config.RobberSpawns" config.lua; then
        echo "✅ Robber spawns configured"
    else
        echo "❌ Robber spawns not found in config"
    fi
else
    echo "❌ config.lua not found"
fi

echo
echo "📝 Installation Check:"
echo "======================"

# Check if resource name is valid
resource_name=$(basename "$(pwd)")
if [[ "$resource_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "✅ Resource name valid: $resource_name"
else
    echo "⚠️  Resource name may contain invalid characters: $resource_name"
fi

# Check permissions
if [ -r "fxmanifest.lua" ]; then
    echo "✅ File permissions OK"
else
    echo "❌ File permission issues detected"
fi

echo
echo "🎯 Quick Start:"
echo "==============="
echo "1. Place this folder in your FiveM resources directory"
echo "2. Add 'start $resource_name' to your server.cfg"
echo "3. Restart your FiveM server"
echo "4. Use '/startcr' in-game to start a match"
echo
echo "For detailed instructions, see README.md"
echo

if [ $files_missing -eq 0 ]; then
    echo "🎉 Resource appears to be ready for use!"
    exit 0
else
    echo "❌ Issues detected - please resolve before use"
    exit 1
fi
