#!/bin/bash

# Verification script for SC40-V3 clean rebuild

echo "🔍 Verifying SC40-V3 Clean Rebuild..."
echo ""

# Check Models
echo "📦 Checking Models..."
ls -1 SC40-V3/Models/ | head -10
echo "   Total models: $(ls -1 SC40-V3/Models/ | wc -l)"
echo ""

# Check Services
echo "🔧 Checking Services..."
ls -1 SC40-V3/Services/ | head -10
echo "   Total services: $(ls -1 SC40-V3/Services/ | wc -l)"
echo ""

# Check UI Views
echo "🎨 Checking UI Views..."
ls -1 SC40-V3/UI/*.swift 2>/dev/null | head -10
echo "   Total UI files: $(ls -1 SC40-V3/UI/*.swift 2>/dev/null | wc -l)"
echo ""

# Check Critical Files
echo "✅ Checking Critical Files..."
files=(
    "SC40-V3/ContentView.swift"
    "SC40-V3/UI/OnboardingView.swift"
    "SC40-V3/UI/WelcomeView.swift"
    "SC40-V3/UI/TrainingView.swift"
    "SC40-V3/Models/UserProfileViewModel.swift"
    "SC40-V3/Services/WatchConnectivityManager.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ MISSING: $file"
    fi
done

echo ""
echo "🔍 Checking for Corrupted Files (should be NONE)..."
corrupted=(
    "SC40-V3/UnifiedAppFlowView.swift"
    "SC40-V3/AlternativeAppDelegate.swift"
    "SC40-V3/AlternativeSprintCoachApp.swift"
)

corrupted_found=0
for file in "${corrupted[@]}"; do
    if [ -f "$file" ]; then
        echo "   ⚠️  FOUND CORRUPTED FILE: $file"
        corrupted_found=1
    fi
done

if [ $corrupted_found -eq 0 ]; then
    echo "   ✅ No corrupted files found"
fi

echo ""
echo "📊 Summary:"
echo "   Models: $(ls -1 SC40-V3/Models/ 2>/dev/null | wc -l) files"
echo "   Services: $(ls -1 SC40-V3/Services/ 2>/dev/null | wc -l) files"
echo "   UI Views: $(ls -1 SC40-V3/UI/*.swift 2>/dev/null | wc -l) files"
echo ""
echo "✅ Verification complete!"
