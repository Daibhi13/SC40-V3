#!/bin/bash

echo "═══════════════════════════════════════════════════════════════"
echo "  SC40-V3 FINAL REBUILD VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# iPhone App Files
echo "📱 IPHONE APP FILES:"
echo "  Models:      $(ls -1 SC40-V3/Models/*.swift 2>/dev/null | wc -l) files"
echo "  Services:    $(ls -1 SC40-V3/Services/*.swift 2>/dev/null | wc -l) files"
echo "  UI:          $(ls -1 SC40-V3/UI/*.swift 2>/dev/null | wc -l) files"
echo "  Total:       $(find SC40-V3 -name "*.swift" -type f | wc -l) Swift files"
echo ""

# Watch App Files
echo "⌚ APPLE WATCH APP FILES:"
echo "  Views:       $(find "SC40-V3-W Watch App Watch App/Views Watch" -name "*.swift" -type f 2>/dev/null | wc -l) files"
echo "  Services:    $(ls -1 "SC40-V3-W Watch App Watch App/Services Watch"/*.swift 2>/dev/null | wc -l) files"
echo "  Root:        $(ls -1 "SC40-V3-W Watch App Watch App"/*.swift 2>/dev/null | wc -l) files"
echo "  Total:       $(find "SC40-V3-W Watch App Watch App" -name "*.swift" -type f | wc -l) Swift files"
echo ""

# Critical Files Check
echo "✅ CRITICAL FILES:"
files=(
    "SC40-V3/ContentView.swift"
    "SC40-V3/UI/OnboardingView.swift"
    "SC40-V3/UI/WelcomeView.swift"
    "SC40-V3/UI/TrainingView.swift"
    "SC40-V3/Models/UserProfileViewModel.swift"
    "SC40-V3/Services/WatchConnectivityManager.swift"
    "SC40-V3-W Watch App Watch App/EntryViewWatch.swift"
    "SC40-V3-W Watch App Watch App/Views Watch/MainProgramWorkoutWatchView.swift"
)

all_present=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $(basename "$file")"
    else
        echo "  ❌ MISSING: $(basename "$file")"
        all_present=false
    fi
done
echo ""

# Corrupted Files Check
echo "🔍 CORRUPTED FILES CHECK (should be NONE):"
corrupted=(
    "SC40-V3/UnifiedAppFlowView.swift"
    "SC40-V3/AlternativeAppDelegate.swift"
    "SC40-V3/AlternativeSprintCoachApp.swift"
)

corrupted_found=false
for file in "${corrupted[@]}"; do
    if [ -f "$file" ]; then
        echo "  ⚠️  FOUND: $(basename "$file")"
        corrupted_found=true
    fi
done

if [ "$corrupted_found" = false ]; then
    echo "  ✅ No corrupted files found"
fi
echo ""

# Documentation Check
echo "📖 DOCUMENTATION:"
docs=(
    "README.md"
    "CLEAN_REBUILD_COMPLETE.md"
    "REBUILD_SUMMARY.md"
    "WATCH_APP_REBUILD_SUMMARY.md"
    "XCODE_SETUP_GUIDE.md"
    "verify_rebuild.sh"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✅ $doc"
    else
        echo "  ❌ MISSING: $doc"
    fi
done
echo ""

# Final Summary
echo "═══════════════════════════════════════════════════════════════"
echo "  FINAL SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  📱 iPhone Files:  $(find SC40-V3 -name "*.swift" -type f | wc -l) Swift files"
echo "  ⌚ Watch Files:   $(find "SC40-V3-W Watch App Watch App" -name "*.swift" -type f | wc -l) Swift files"
echo "  📄 Documentation: $(ls -1 *.md 2>/dev/null | wc -l) guides"
echo ""

if [ "$all_present" = true ] && [ "$corrupted_found" = false ]; then
    echo "  ✅ STATUS: REBUILD COMPLETE AND VERIFIED"
    echo "  🚀 READY FOR: Xcode project setup"
else
    echo "  ⚠️  STATUS: Issues detected - review above"
fi
echo ""
echo "═══════════════════════════════════════════════════════════════"

