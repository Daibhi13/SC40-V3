#!/usr/bin/env python3
import re

with open('SC40-V3.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Fix iOS targets - use custom Info.plist
content = re.sub(
    r'(PRODUCT_BUNDLE_IDENTIFIER = "Acclerate\.SC40-V3";.*?)(GENERATE_INFOPLIST_FILE = YES;)',
    r'\1GENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = "SC40-V3/Info.plist";',
    content,
    flags=re.DOTALL
)

# Fix Watch targets - add INFOPLIST_VALUES dictionary with WatchKit keys
# Find Watch app configurations and add INFOPLIST_VALUES
watch_pattern = r'(PRODUCT_BUNDLE_IDENTIFIER = "Acclerate\.SC40-V3\.watchkitapp";.*?)(GENERATE_INFOPLIST_FILE = YES;)(.*?LD_RUNPATH_SEARCH_PATHS)'
watch_replacement = r'\1\2\n\t\t\t\tINFOPLIST_VALUES = {\n\t\t\t\t\tWKApplication = YES;\n\t\t\t\t\tWKWatchKitApp = YES;\n\t\t\t\t};\3LD_RUNPATH_SEARCH_PATHS'
content = re.sub(watch_pattern, watch_replacement, content, flags=re.DOTALL)

with open('SC40-V3.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Fixed all targets with INFOPLIST_VALUES")
