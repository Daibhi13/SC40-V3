# Xcode Derived Data Cleaner Macro

## Quick Usage (Shell Script)
Run the included `clear_derived_data.sh` script:
```bash
./clear_derived_data.sh
```

## Shell Function/Alias Setup

Add these lines to your `~/.zshrc` or `~/.bashrc` file:

```bash
# Xcode Derived Data Cleaner
clear_xcode_derived_data() {
    echo "🧹 Clearing Xcode Derived Data..."

    # Find and remove all Xcode derived data directories
    DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"
    if [ -d "$DERIVED_DATA_DIR" ]; then
        echo "📁 Found DerivedData directory: $DERIVED_DATA_DIR"
        rm -rf "$DERIVED_DATA_DIR"/*
        echo "✅ Cleared all derived data"
    else
        echo "📁 DerivedData directory not found: $DERIVED_DATA_DIR"
    fi

    # Also clear any project-specific derived data
    PROJECT_DERIVED=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "*SC40-V6*" -type d 2>/dev/null)
    if [ ! -z "$PROJECT_DERIVED" ]; then
        echo "🗑️  Removing project-specific derived data..."
        rm -rf $PROJECT_DERIVED
        echo "✅ Removed project derived data"
    fi

    echo "🎉 Derived data cleanup complete!"
    echo "💡 Next steps: xcodebuild clean && xcodebuild build"
}

# Alias for quick access
alias clearderived="clear_xcode_derived_data"
```

## Usage After Setup
Once added to your shell profile, you can use:
```bash
# Clear all derived data
clear_xcode_derived_data

# Or use the alias
clearderived
```

## What it does:
- 🧹 Removes all Xcode derived data (`~/Library/Developer/Xcode/DerivedData/*`)
- 🗑️ Removes project-specific derived data for SC40-V6
- 📢 Provides feedback on what was cleaned
- 💡 Suggests next steps (clean build)

## Alternative: Manual Cleanup
If you prefer manual cleanup:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

This macro automates the process and provides better feedback!
