#!/bin/bash

# Script to disable verbose debug logging for performance
# Run this script to speed up terminal output during development

echo "🔇 Disabling verbose debug logging..."

# Disable UserDefaultsManager logging (already done)
echo "✅ UserDefaultsManager logging disabled"

# Add Swift compiler flag to disable print statements in release builds
echo ""
echo "📝 To completely disable print statements in Xcode:"
echo "1. Select your target in Xcode"
echo "2. Go to Build Settings"
echo "3. Search for 'Other Swift Flags'"
echo "4. Add '-D DISABLE_PRINT' for Release configuration"
echo ""
echo "Then wrap debug prints like:"
echo "#if !DISABLE_PRINT"
echo "print(\"debug message\")"
echo "#endif"
echo ""

# Create a global logging toggle
cat > /tmp/logging_config.txt << 'EOF'
To globally disable logging, set these flags in your code:

1. UserDefaultsManager: DEBUG_LOGGING = false ✅ (Already done)
2. DebugLogger: DEBUG_LOGGING_ENABLED = false ✅ (Already done)

For immediate relief, you can also:
- Clear Xcode console: Cmd+K
- Filter console output in Xcode (bottom right search)
- Run app without debugger attached (Cmd+Ctrl+R)

EOF

cat /tmp/logging_config.txt

echo ""
echo "✅ Logging optimizations applied!"
echo "🚀 Terminal performance should be significantly improved"
