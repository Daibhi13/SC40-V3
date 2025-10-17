#!/bin/bash
echo "🧹 Comprehensive Xcode Cleanup for SC40-V3"

# Remove all Xcode caches and derived data
echo "Removing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/UserData/xcschemes

# Clean project build artifacts
echo "Cleaning project build artifacts..."
rm -rf build/
find . -name "*.swp" -delete
find . -name "*.tmp" -delete
find . -name ".DS_Store" -delete

# Reset Xcode preferences for this project
echo "Resetting Xcode preferences..."
defaults delete com.apple.dt.Xcode 2>/dev/null || true

echo "✅ Xcode cleanup completed!"
echo ""
echo "Next steps:"
echo "1. Quit Xcode completely (⌘Q)"
echo "2. Reopen Xcode"
echo "3. Open the workspace: SC40-V3.xcodeproj/project.xcworkspace"
echo "4. Try opening the project again"
echo ""
echo "If issues persist, try opening the .xcworkspace file directly."
