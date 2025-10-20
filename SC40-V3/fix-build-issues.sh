#!/bin/bash

# Fix Build Issues Script for Sprint Coach 40
echo "🔧 Fixing Sprint Coach 40 build issues..."

# 1. Remove problematic Package.swift (not needed for Xcode project)
if [ -f "Package.swift" ]; then
    echo "📦 Removing Package.swift (not needed for Xcode project)"
    rm Package.swift
fi

# 2. Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*

# 3. Check for missing files that are referenced
echo "🔍 Checking for missing referenced files..."

# Check if AuthenticationManager exists
if [ ! -f "SC40-V3/Services/AuthenticationManager.swift" ]; then
    echo "⚠️  AuthenticationManager.swift is missing"
else
    echo "✅ AuthenticationManager.swift found"
fi

# Check if EmailSignupView exists
if [ ! -f "SC40-V3/UI/EmailSignupView.swift" ]; then
    echo "⚠️  EmailSignupView.swift is missing"
else
    echo "✅ EmailSignupView.swift found"
fi

# Check if EntryIOSView exists
ENTRY_VIEW=$(find . -name "*Entry*View*.swift" -type f | head -1)
if [ -z "$ENTRY_VIEW" ]; then
    echo "⚠️  EntryIOSView.swift is missing"
else
    echo "✅ Entry view found: $ENTRY_VIEW"
fi

# 4. Create placeholder app icons if missing
WATCH_ICON_DIR="SC40-V3-W Watch App Watch App/Assets.xcassets/AppIcon.appiconset"
if [ -d "$WATCH_ICON_DIR" ]; then
    echo "📱 Checking Watch App icons..."
    MISSING_ICONS=0
    for size in 48 55 58 66 80 87 88 92 100 102 108 172 196 216 234 258 1024; do
        if [ ! -f "$WATCH_ICON_DIR/${size}.png" ]; then
            echo "⚠️  Missing icon: ${size}.png"
            MISSING_ICONS=$((MISSING_ICONS + 1))
        fi
    done
    
    if [ $MISSING_ICONS -gt 0 ]; then
        echo "📝 Note: $MISSING_ICONS watch app icons are missing"
        echo "   This causes the 'Failed to generate flattened icon stack' warning"
        echo "   Add your app icons to: $WATCH_ICON_DIR"
    else
        echo "✅ All watch app icons present"
    fi
fi

# 5. Build recommendations
echo ""
echo "🚀 Build Recommendations:"
echo "1. Add SDKs via Xcode Package Manager:"
echo "   - Firebase: https://github.com/firebase/firebase-ios-sdk"
echo "   - Facebook: https://github.com/facebook/facebook-ios-sdk"
echo "   - Google: https://github.com/google/GoogleSignIn-iOS"
echo ""
echo "2. The conditional imports will prevent build errors until SDKs are added"
echo ""
echo "3. Current build status should be: ⚠️  BUILDS WITH WARNINGS"
echo "   - Missing SDKs cause import warnings (expected)"
echo "   - Missing icons cause asset warnings (cosmetic)"
echo "   - Core functionality should work"
echo ""
echo "4. After adding SDKs, update configuration files:"
echo "   - GoogleService-Info.plist (Firebase)"
echo "   - Info.plist (URL schemes and permissions)"
echo "   - InstagramAuthService.swift (app credentials)"

echo ""
echo "✅ Build issue analysis complete!"
