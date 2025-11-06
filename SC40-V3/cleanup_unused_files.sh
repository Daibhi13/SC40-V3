#!/bin/bash

# SC40-V3 Unused Files Cleanup Script
# This script removes confirmed unused files to improve build performance
# A backup is created before deletion

set -e  # Exit on error

PROJECT_DIR="/Users/davidoconnell/Projects/SC40-V3/SC40-V3"
BACKUP_DIR="/Users/davidoconnell/Projects/SC40-V3/backup_$(date +%Y%m%d_%H%M%S)"

echo "🧹 SC40-V3 Cleanup Script"
echo "========================="
echo ""
echo "📦 Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to safely remove file with backup
remove_file() {
    local file="$1"
    if [ -f "$file" ]; then
        # Create backup directory structure
        local rel_path="${file#$PROJECT_DIR/}"
        local backup_path="$BACKUP_DIR/$rel_path"
        mkdir -p "$(dirname "$backup_path")"
        
        # Copy to backup
        cp "$file" "$backup_path"
        echo "✅ Backed up: $rel_path"
        
        # Remove original
        rm "$file"
        echo "🗑️  Removed: $rel_path"
    else
        echo "⚠️  Not found: $file"
    fi
}

echo ""
echo "🗑️  PHASE 1: Removing deprecated EntryIOSView"
echo "=============================================="
remove_file "$PROJECT_DIR/UI/EntryIOSView.swift"

echo ""
echo "🗑️  PHASE 2: Removing empty/stub files"
echo "======================================="
remove_file "$PROJECT_DIR/UI/SharedViews.swift"
remove_file "$PROJECT_DIR/UI/SocialFeaturesView.swift"
remove_file "$PROJECT_DIR/UI/SocialFeaturesView.swift.disabled"
remove_file "$PROJECT_DIR/UI/CalendarRoadmapView.swift"
remove_file "$PROJECT_DIR/UI/SessionView.swift"
remove_file "$PROJECT_DIR/UI/PerformanceView.swift"
remove_file "$PROJECT_DIR/UI/EditProfileView.swift"
remove_file "$PROJECT_DIR/UI/CombineView.swift"

echo ""
echo "🗑️  PHASE 3: Removing demo/mock files"
echo "======================================"
remove_file "$PROJECT_DIR/UI/AdaptiveWorkoutDemo.swift"
remove_file "$PROJECT_DIR/UI/HistoryViewDemo.swift"
remove_file "$PROJECT_DIR/UI/HistoryViewPreview.swift"
remove_file "$PROJECT_DIR/UI/MockTrainingData.swift"

echo ""
echo "🗑️  PHASE 4: Removing unused social/auth services"
echo "=================================================="
remove_file "$PROJECT_DIR/Services/InstagramAuthService.swift"
remove_file "$PROJECT_DIR/Services/GameKitManager.swift"

echo ""
echo "🗑️  PHASE 5: Removing news features"
echo "===================================="
remove_file "$PROJECT_DIR/Configuration/NewsAPIConfig.swift"
remove_file "$PROJECT_DIR/UI/SprintNewsView.swift"
remove_file "$PROJECT_DIR/Services/NewsService.swift"

echo ""
echo "🗑️  PHASE 6: Removing advanced analytics (not in MVP)"
echo "======================================================"
remove_file "$PROJECT_DIR/UI/AdvancedAnalyticsMonetizationView.swift"
remove_file "$PROJECT_DIR/Services/ARKitManager.swift"

echo ""
echo "✅ CLEANUP COMPLETE!"
echo "===================="
echo ""
echo "📊 Summary:"
echo "  - Backup created at: $BACKUP_DIR"
echo "  - Files removed from project"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "  1. Open Xcode"
echo "  2. Remove deleted files from Xcode project navigator (they'll show in red)"
echo "  3. Clean build folder: Product > Clean Build Folder (Cmd+Shift+K)"
echo "  4. Build project: Product > Build (Cmd+B)"
echo ""
echo "💡 If anything breaks, restore from: $BACKUP_DIR"
echo ""
