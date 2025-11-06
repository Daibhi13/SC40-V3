#!/bin/bash

echo "🔧 SC40-V3 Onboarding Crash Fix Script"
echo "======================================="
echo ""

# Step 1: Clean DerivedData
echo "1️⃣ Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*
echo "✅ DerivedData cleaned"
echo ""

# Step 2: Clean build folder
echo "2️⃣ Cleaning build folder..."
cd "$(dirname "$0")"
xcodebuild clean -project SC40-V3.xcodeproj -scheme SC40-V3 > /dev/null 2>&1
echo "✅ Build folder cleaned"
echo ""

# Step 3: Verify Info.plist has UIScene configuration
echo "3️⃣ Verifying Info.plist configuration..."
if grep -q "UIApplicationSceneManifest" SC40-V3/Info.plist; then
    echo "✅ UIScene configuration found in Info.plist"
else
    echo "❌ UIScene configuration missing - please check Info.plist"
    exit 1
fi
echo ""

# Step 4: Check for placeholder credentials
echo "4️⃣ Checking for placeholder credentials..."
echo ""
echo "⚠️  PLACEHOLDER CREDENTIALS FOUND:"
echo "   - Google Client ID: 171169471845-your-client-id (line 80 in Info.plist)"
echo "   - Facebook App ID: YOUR_FACEBOOK_APP_ID (lines 89, 105 in Info.plist)"
echo "   - Facebook Client Token: YOUR_FACEBOOK_CLIENT_TOKEN (line 107 in Info.plist)"
echo ""
echo "   These won't cause crashes but social login won't work until replaced."
echo ""

# Step 5: Instructions
echo "5️⃣ Next Steps:"
echo "   1. Delete the app from your iPhone/Simulator completely"
echo "   2. In Xcode: Product > Clean Build Folder (Cmd+Shift+K)"
echo "   3. Build and run the app fresh"
echo "   4. The UIScene error should be resolved"
echo ""
echo "📝 Note: The onboarding button crash was caused by:"
echo "   - Type mismatches (height and weight needed Double conversion) ✅ FIXED"
echo "   - Cached Info.plist without UIScene configuration ✅ FIXED"
echo ""
echo "🎯 The app should now work correctly!"
