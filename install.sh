#!/bin/bash

# Cops & Robbers FiveM Installation Script

echo "==================================="
echo "  Cops & Robbers FiveM Installer"
echo "==================================="
echo

# Check if we're in a FiveM resources directory
if [ ! -f "../../server.cfg" ] && [ ! -f "../server.cfg" ]; then
    echo "⚠️  Warning: This doesn't appear to be a FiveM resources directory."
    echo "   Make sure you're running this script from your server's resources folder."
    echo
fi

# Get resource name
RESOURCE_NAME=$(basename "$(pwd)")
echo "📦 Installing resource: $RESOURCE_NAME"
echo

# Check file permissions
echo "🔍 Checking file permissions..."
if [ ! -w . ]; then
    echo "❌ Error: No write permission in current directory"
    exit 1
fi

# Verify all required files exist
echo "📋 Verifying files..."
required_files=(
    "fxmanifest.lua"
    "config.lua"
    "server/main.lua"
    "server/game.lua"
    "client/main.lua"
    "client/blips.lua"
    "client/arrest.lua"
    "html/ui.html"
    "html/style.css"
    "html/script.js"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing: $file"
        missing_files=$((missing_files + 1))
    else
        echo "✅ Found: $file"
    fi
done

if [ $missing_files -gt 0 ]; then
    echo
    echo "❌ Installation failed: $missing_files file(s) missing"
    exit 1
fi

echo
echo "✅ All files verified successfully!"
echo

# Check for server.cfg
SERVER_CFG=""
if [ -f "../../server.cfg" ]; then
    SERVER_CFG="../../server.cfg"
elif [ -f "../server.cfg" ]; then
    SERVER_CFG="../server.cfg"
fi

if [ -n "$SERVER_CFG" ]; then
    echo "🔍 Found server.cfg at: $SERVER_CFG"
    
    # Check if resource is already in server.cfg
    if grep -q "start $RESOURCE_NAME" "$SERVER_CFG" || grep -q "ensure $RESOURCE_NAME" "$SERVER_CFG"; then
        echo "✅ Resource already configured in server.cfg"
    else
        echo "📝 Adding resource to server.cfg..."
        echo "start $RESOURCE_NAME" >> "$SERVER_CFG"
        echo "✅ Added 'start $RESOURCE_NAME' to server.cfg"
    fi
else
    echo "⚠️  Could not find server.cfg"
    echo "   Please manually add 'start $RESOURCE_NAME' to your server.cfg"
fi

echo
echo "🎉 Installation completed successfully!"
echo
echo "📖 Next steps:"
echo "   1. Restart your FiveM server"
echo "   2. Use '/startcopsrobbers' in-game to start a match"
echo "   3. Minimum 4 players required to begin"
echo
echo "📚 Configuration:"
echo "   Edit 'config.lua' to customize game settings"
echo
echo "🆘 Support:"
echo "   Check README.md for troubleshooting and usage information"
echo

# Make install script executable
chmod +x install.sh 2>/dev/null

echo "==================================="
