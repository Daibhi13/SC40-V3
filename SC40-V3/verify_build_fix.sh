#!/bin/bash

# SC40-V3 Build Fix Verification Script

echo "🔧 SC40-V3 Build Fix Verification"
echo "================================="

# Check for duplicate HealthKitManager files
echo "1. Checking for duplicate HealthKitManager files..."
HEALTHKIT_FILES=$(find . -name "*HealthKitManager*" -type f)
echo "Found HealthKitManager files:"
echo "$HEALTHKIT_FILES"

if [ $(echo "$HEALTHKIT_FILES" | wc -l) -gt 1 ]; then
    echo "❌ Multiple HealthKitManager files found - this will cause build errors"
    echo "   Keep only: ./SC40-V3/Services/HealthKitManager.swift"
else
    echo "✅ Single HealthKitManager file found - good"
fi

# Check for other potential duplicate managers
echo ""
echo "2. Checking for other duplicate manager files..."
DUPLICATE_MANAGERS=$(find . -name "*Manager.swift" -type f | sort | uniq -d)
if [ -n "$DUPLICATE_MANAGERS" ]; then
    echo "❌ Potential duplicate managers found:"
    echo "$DUPLICATE_MANAGERS"
else
    echo "✅ No duplicate manager files found"
fi

# Check for common build issues
echo ""
echo "3. Checking for common build issues..."

# Check for missing imports
echo "   - Checking HealthKit imports..."
if grep -r "import HealthKit" ./SC40-V3/Services/HealthKitManager.swift > /dev/null; then
    echo "   ✅ HealthKit import found"
else
    echo "   ❌ HealthKit import missing"
fi

# Check for proper class declaration
echo "   - Checking class declaration..."
if grep -r "@MainActor" ./SC40-V3/Services/HealthKitManager.swift > /dev/null; then
    echo "   ✅ @MainActor annotation found"
else
    echo "   ❌ @MainActor annotation missing"
fi

echo ""
echo "4. Recommended actions:"
echo "   1. Clean Build Folder (⌘+Shift+K)"
echo "   2. Delete Derived Data"
echo "   3. Rebuild Project (⌘+B)"
echo ""
echo "If build still fails, check Xcode target membership for HealthKitManager.swift"
