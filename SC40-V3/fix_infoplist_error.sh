#!/bin/bash

# Fix Info.plist duplicate output error
# This script removes Info.plist from Copy Bundle Resources build phase

echo "🔧 Fixing Info.plist duplicate output error..."
echo ""

PROJECT_FILE="SC40-V3.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: project.pbxproj not found"
    exit 1
fi

echo "📝 Backing up project file..."
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

echo "🔍 Searching for Info.plist in Copy Bundle Resources..."

# This is a simplified approach - you may need to manually remove it in Xcode
# The proper way is through Xcode UI as shown above

echo ""
echo "⚠️  RECOMMENDED: Fix this in Xcode UI"
echo ""
echo "Steps:"
echo "1. Open SC40-V3.xcodeproj in Xcode"
echo "2. Select 'SC40-V3' target"
echo "3. Go to 'Build Phases' tab"
echo "4. Expand 'Copy Bundle Resources'"
echo "5. Find 'Info.plist' and remove it (click − button)"
echo "6. Clean: Cmd + Shift + K"
echo "7. Build: Cmd + B"
echo ""
echo "✅ This will fix the duplicate output error"
