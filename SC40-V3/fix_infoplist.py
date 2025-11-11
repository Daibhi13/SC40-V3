#!/usr/bin/env python3
import re

# Read the project file
with open('SC40-V3.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Fix iOS app targets (SC40-V3)
# Replace GENERATE_INFOPLIST_FILE = YES with NO and add INFOPLIST_FILE for iOS targets
ios_pattern = r'(06A66E5B2EBB6AE5007E8098.*?buildSettings = \{.*?)(GENERATE_INFOPLIST_FILE = YES;)'
ios_replacement = r'\1GENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = "SC40-V3/Info.plist";'
content = re.sub(ios_pattern, ios_replacement, content, flags=re.DOTALL)

# Fix Watch app targets (SC40-V3-W Watch App Watch App)  
# Replace GENERATE_INFOPLIST_FILE = YES with NO and add INFOPLIST_FILE for Watch targets
watch_pattern = r'(06A66E892EBB6AE7007E8098.*?buildSettings = \{.*?)(GENERATE_INFOPLIST_FILE = YES;)'
watch_replacement = r'\1GENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = "SC40-V3-W Watch App Watch App/Info.plist";'
content = re.sub(watch_pattern, watch_replacement, content, flags=re.DOTALL)

# Also fix the Release configuration for Watch app
watch_release_pattern = r'(06A66E8A2EBB6AE7007E8098.*?buildSettings = \{.*?)(GENERATE_INFOPLIST_FILE = YES;)'
watch_release_replacement = r'\1GENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = "SC40-V3-W Watch App Watch App/Info.plist";'
content = re.sub(watch_release_pattern, watch_release_replacement, content, flags=re.DOTALL)

# Write back
with open('SC40-V3.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Fixed Info.plist configuration for iOS and Watch targets")
