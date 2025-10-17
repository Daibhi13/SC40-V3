#!/bin/bash
echo "🧹 Cleaning Xcode build artifacts..."

# Remove build directory
if [ -d "build" ]; then
    echo "Removing build directory..."
    rm -rf build/
fi

# Remove derived data for this project
echo "Removing Xcode derived data..."
find ~/Library/Developer/Xcode/DerivedData -name "*SC40-V3*" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean Xcode caches
echo "Cleaning Xcode caches..."
defaults delete com.apple.dt.Xcode 2>/dev/null || true

echo "✅ Build cleanup completed!"
echo ""
echo "You can now:"
echo "1. Open Xcode and try Clean Build Folder again"
echo "2. Or run a fresh build with: xcodebuild -project SC40-V3.xcodeproj -scheme \"SC40-V3\" clean build"
