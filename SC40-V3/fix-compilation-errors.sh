#!/bin/bash

# SC40-V3 Compilation Error Fix Script
# This script addresses the major issues causing 450+ compilation errors

echo "🔧 Starting SC40-V3 Compilation Error Fix..."

# Navigate to project directory
cd /Users/davidoconnell/Projects/SC40-V3

echo "📋 Issues Identified:"
echo "1. ✅ Duplicate App entry points (FIXED)"
echo "2. ⚠️  Potential Swift 6 concurrency issues"
echo "3. ⚠️  Missing framework dependencies"
echo "4. ⚠️  Xcode 16 compatibility issues"

echo ""
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*
xcodebuild clean -project SC40-V3.xcodeproj -scheme "SC40-V3" 2>/dev/null || true
xcodebuild clean -project SC40-V3.xcodeproj -scheme "SC40-V3-W Watch App" 2>/dev/null || true

echo ""
echo "🔍 Checking for common issues..."

# Check for duplicate symbols
echo "Checking for duplicate App entry points..."
grep -r "@main" --include="*.swift" . | grep -v "^Binary file" | grep -v "^//"

echo ""
echo "📦 Checking package dependencies..."
if [ -f "SC40-V3.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "✅ Package.resolved exists"
else
    echo "⚠️  Package.resolved missing - may need to resolve packages"
fi

echo ""
echo "🏗️ Attempting build to identify specific errors..."
echo "Building iOS target..."
xcodebuild -project SC40-V3.xcodeproj -scheme "SC40-V3" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | head -50

echo ""
echo "Building Watch target..."
xcodebuild -project SC40-V3.xcodeproj -scheme "SC40-V3-W Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 2 (49mm)' build 2>&1 | head -50

echo ""
echo "🔧 Fix script completed. Check output above for specific error details."
echo "💡 Common solutions:"
echo "   - Open Xcode and resolve package dependencies"
echo "   - Check Swift language version in Build Settings"
echo "   - Verify all frameworks are properly linked"
echo "   - Update to latest Xcode version if needed"
