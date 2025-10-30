#!/bin/bash

# Swift Package Manager Fix Script
# Resolves missing Firebase, Facebook, and other package dependencies

echo "📦 Fixing Swift Package Manager Dependencies..."
echo ""

# Navigate to project directory
cd /Users/davidoconnell/Projects/SC40-V3

echo "🧹 Cleaning package cache..."
# Remove Swift Package Manager cache
rm -rf .swiftpm/ 2>/dev/null
rm -f Package.resolved 2>/dev/null

echo "🧹 Cleaning Xcode derived data..."
# Clean Xcode derived data for this project
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3* 2>/dev/null

echo "🧹 Cleaning module cache..."
# Clean module cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex 2>/dev/null

echo "✅ Cache cleanup completed!"
echo ""
echo "🔨 Next steps in Xcode:"
echo "1. Open SC40-V3.xcodeproj"
echo "2. File → Packages → Reset Package Caches"
echo "3. File → Packages → Resolve Package Versions"
echo "4. Wait for packages to download (2-5 minutes)"
echo "5. Product → Clean Build Folder (⇧⌘K)"
echo "6. Product → Build (⌘B)"
echo ""
echo "📋 Missing packages that should resolve:"
echo "• Firebase (Core, Auth, Firestore, Analytics, etc.)"
echo "• Facebook (Core, Login, Share, etc.)"
echo "• Google Sign-In"
echo "• Swift Algorithms"
echo ""
echo "🎯 This should resolve all 'Missing package product' errors!"

# Make the script executable
chmod +x fix_packages.sh
