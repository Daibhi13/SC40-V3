#!/bin/bash

# SC40-V3 Derived Data Cleanup Script
# Fixes the 450 errors caused by corrupted derived data

echo "🧹 SC40-V3 Derived Data Cleanup Started..."

# Navigate to project directory
cd /Users/davidoconnell/Projects/SC40-V3

echo ""
echo "📂 Cleaning Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "✅ Derived Data cleared"

echo ""
echo "🧽 Cleaning Xcode build cache..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo "✅ Xcode cache cleared"

echo ""
echo "🔄 Cleaning project build artifacts..."
xcodebuild clean -project SC40-V3.xcodeproj -alltargets
echo "✅ Project cleaned"

echo ""
echo "📦 Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project SC40-V3.xcodeproj
echo "✅ Packages resolved"

echo ""
echo "🏗️ Test building iOS target..."
xcodebuild -project SC40-V3.xcodeproj -scheme "SC40-V3" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build -quiet

if [ $? -eq 0 ]; then
    echo "✅ iOS build successful!"
else
    echo "⚠️  iOS build has issues - check Xcode for details"
fi

echo ""
echo "🏗️ Test building Watch target..."
xcodebuild -project SC40-V3.xcodeproj -scheme "SC40-V3-W Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 2 (49mm)' build -quiet

if [ $? -eq 0 ]; then
    echo "✅ Watch build successful!"
else
    echo "⚠️  Watch build has issues - check Xcode for details"
fi

echo ""
echo "🎉 Cleanup completed!"
echo "💡 Next steps:"
echo "   1. Open Xcode"
echo "   2. Build your project (Cmd+B)"
echo "   3. The 450 errors should now be resolved"
echo ""
echo "🔍 If you still see errors, they're likely real code issues, not derived data corruption."
