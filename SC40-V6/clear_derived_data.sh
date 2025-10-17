#!/bin/bash
# Xcode Derived Data Cleaner Macro
# Usage: ./clear_derived_data.sh

echo "�� Clearing Xcode Derived Data..."

# Find and remove all Xcode derived data directories
DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA_DIR" ]; then
    echo "📁 Found DerivedData directory: $DERIVED_DATA_DIR"
    rm -rf "$DERIVED_DATA_DIR"/*
    echo "✅ Cleared all derived data"
else
    echo "📁 DerivedData directory not found: $DERIVED_DATA_DIR"
fi

# Also clear any SC40-V6 specific derived data
SC40_DERIVED=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "*SC40-V6*" -type d 2>/dev/null)
if [ ! -z "$SC40_DERIVED" ]; then
    echo "🗑️  Removing SC40-V6 specific derived data..."
    rm -rf $SC40_DERIVED
    echo "✅ Removed SC40-V6 derived data"
fi

echo "🎉 Derived data cleanup complete!"
echo "💡 You can now run: xcodebuild clean && xcodebuild build"
