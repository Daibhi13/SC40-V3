#!/bin/bash

# SC40-V3 Swift Package Manager Dependencies Fix Script

echo "🔧 SC40-V3 Package Dependencies Fix"
echo "===================================="

PROJECT_DIR="/Users/davidoconnell/Projects/SC40-V3"
cd "$PROJECT_DIR"

echo "1. Cleaning Swift Package Manager caches..."

# Remove Package.resolved to force fresh resolution
if [ -f "SC40-V3.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    rm -f "SC40-V3.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    echo "   ✅ Removed Package.resolved"
else
    echo "   ℹ️  Package.resolved not found"
fi

# Clear SPM caches
echo "2. Clearing SPM caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "   ✅ SPM caches cleared"

# Clear Xcode caches
echo "3. Clearing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf ~/Library/Caches/com.apple.dt.Xcode/
echo "   ✅ Xcode caches cleared"

# Check if SourcePackages directory exists and clean it
if [ -d "SourcePackages" ]; then
    echo "4. Cleaning SourcePackages directory..."
    rm -rf SourcePackages/
    echo "   ✅ SourcePackages directory cleaned"
fi

echo ""
echo "🎯 NEXT STEPS:"
echo "1. Restart Xcode completely"
echo "2. Open SC40-V3.xcodeproj"
echo "3. File → Package Dependencies → Reset Package Caches"
echo "4. File → Package Dependencies → Resolve Package Versions"
echo "5. Product → Clean Build Folder (⌘+Shift+K)"
echo "6. Product → Build (⌘+B)"
echo ""
echo "If packages are still missing:"
echo "- File → Package Dependencies"
echo "- Remove and re-add each missing package"
echo "- Use these URLs:"
echo "  • Firebase: https://github.com/firebase/firebase-ios-sdk"
echo "  • Facebook: https://github.com/facebook/facebook-ios-sdk"
echo "  • Google Sign-In: https://github.com/google/GoogleSignIn-iOS"
echo "  • Swift Algorithms: https://github.com/apple/swift-algorithms"
echo ""
echo "✅ Package dependency cleanup complete!"
