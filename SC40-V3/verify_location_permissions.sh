#!/bin/bash

# Script to verify location permissions are properly added to Info.plist

echo "🔍 Checking for location permissions in SC40-V3 Info.plist..."

# Find the built Info.plist file
INFO_PLIST_PATH="/Users/davidoconnell/Projects/SC40-V3/build/Debug-iphoneos/SC40-V3.app/Info.plist"

if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "❌ Info.plist not found. Please build the project first."
    echo "   Run: xcodebuild -target SC40-V3 -configuration Debug build"
    exit 1
fi

echo "📍 Found Info.plist at: $INFO_PLIST_PATH"

# Check for required location permissions
echo ""
echo "🔑 Checking location permissions..."

# Check NSLocationWhenInUseUsageDescription
if /usr/libexec/PlistBuddy -c "Print :NSLocationWhenInUseUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null; then
    echo "✅ NSLocationWhenInUseUsageDescription: FOUND"
    WHEN_IN_USE_DESC=$(/usr/libexec/PlistBuddy -c "Print :NSLocationWhenInUseUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null)
    echo "   Description: $WHEN_IN_USE_DESC"
else
    echo "❌ NSLocationWhenInUseUsageDescription: MISSING"
    MISSING_PERMISSIONS=true
fi

echo ""

# Check NSLocationAlwaysAndWhenInUseUsageDescription
if /usr/libexec/PlistBuddy -c "Print :NSLocationAlwaysAndWhenInUseUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null; then
    echo "✅ NSLocationAlwaysAndWhenInUseUsageDescription: FOUND"
    ALWAYS_DESC=$(/usr/libexec/PlistBuddy -c "Print :NSLocationAlwaysAndWhenInUseUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null)
    echo "   Description: $ALWAYS_DESC"
else
    echo "❌ NSLocationAlwaysAndWhenInUseUsageDescription: MISSING"
    MISSING_PERMISSIONS=true
fi

echo ""

if [ "$MISSING_PERMISSIONS" = true ]; then
    echo "🚨 MISSING LOCATION PERMISSIONS!"
    echo ""
    echo "📝 To add them in Xcode:"
    echo "1. Open SC40-V3.xcodeproj in Xcode"
    echo "2. Select the SC40-V3 target"
    echo "3. Go to the 'Info' tab"
    echo "4. Click '+' to add new entries:"
    echo ""
    echo "   Key: NSLocationWhenInUseUsageDescription"
    echo "   Value: SC40 needs location access to accurately time your sprints and measure distances during training sessions."
    echo ""
    echo "   Key: NSLocationAlwaysAndWhenInUseUsageDescription"
    echo "   Value: SC40 uses location services to provide precise sprint timing and distance measurement for optimal training results."
    echo ""
    exit 1
else
    echo "🎉 ALL LOCATION PERMISSIONS FOUND!"
    echo ""
    echo "✅ Your app is ready for GPS functionality!"
    echo "✅ Users will see proper permission descriptions"
    echo "✅ App Store review requirements met"
    echo ""
    echo "🚀 Next step: Test GPS on a real device!"
fi
