#!/bin/bash

# Clean Build Script for SC40-V3
# Resolves XCTest import caching issues

echo "🧹 Cleaning SC40-V3 Build Cache..."

# Clean Xcode derived data
echo "Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3*

# Clean module cache
echo "Cleaning Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Clean build folder in project
echo "Cleaning project build folder..."
cd /Users/davidoconnell/Projects/SC40-V3
rm -rf build/

echo "✅ Clean completed!"
echo ""
echo "🔨 Now rebuild your project in Xcode:"
echo "1. Product → Clean Build Folder (⇧⌘K)"
echo "2. Product → Build (⌘B)"
echo ""
echo "This should resolve the XCTest import caching issue."
