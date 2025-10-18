# Xcode Configuration Fix for SC40-V3

## Issue: Source Files Not Included in Target Build Phases

The current compilation errors indicate that source files are not properly included in the target build phases. Here's how to fix this:

### **Step 1: Verify File Locations**
Ensure all source files are in the correct locations:

**iOS App Files:**
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/` (main iOS app files)
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/Models/` (iOS models)
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/UI/` (iOS views)
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/Shared/` (shared types)

**Watch App Files:**
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3-W Watch App Watch App/` (main Watch files)
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3-W Watch App Watch App/Models Watch/` (Watch models)
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3-W Watch App Watch App/Views Watch/` (Watch views)
- `/Users/davidoconnell/Projects/SC40-V3/SC40-V3-W Watch App Watch App/Utils Watch/` (Watch utilities)

### **Step 2: Configure Target Membership**

**For iOS App Target (`SC40-V3`):**
1. In Xcode, select the `SC40-V3` target
2. Go to **Build Phases** → **Compile Sources**
3. Add all `.swift` files from:
   - `SC40-V3/` directory
   - `SC40-V3/Models/` directory
   - `SC40-V3/UI/` directory
   - `SC40-V3/Shared/` directory
   - `SC40-V3/Services/` directory
   - `SC40-V3/Utils/` directory

**For Watch App Target (`SC40-V3-W Watch App Watch App`):**
1. In Xcode, select the `SC40-V3-W Watch App Watch App` target
2. Go to **Build Phases** → **Compile Sources**
3. Add all `.swift` files from:
   - `SC40-V3-W Watch App Watch App/` directory
   - `SC40-V3-W Watch App Watch App/Models Watch/` directory
   - `SC40-V3-W Watch App Watch App/Views Watch/` directory
   - `SC40-V3-W Watch App Watch App/Utils Watch/` directory
   - `SC40-V3-W Watch App Watch App/Services Watch/` directory
   - `SC40-V3-W Watch App Watch App/ViewModels Watch/` directory

### **Step 3: Verify Target Dependencies**

**Watch App should depend on iOS App:**
1. Select `SC40-V3-W Watch App Watch App` target
2. Go to **Build Phases** → **Target Dependencies**
3. Ensure `SC40-V3` (iOS app) is listed as a dependency

### **Step 4: Fix Import Statements**

**Remove incorrect module imports:**
- Files in the same target don't need import statements for other files in the same target
- Only import external frameworks (SwiftUI, CoreLocation, etc.)
- Remove any `import BrandColorsWatch`, `import WorkoutWatchViewModel`, etc.

**Example fix for SummaryReportView.swift:**
```swift
// BEFORE (incorrect):
import SwiftUI
import BrandColorsWatch

// AFTER (correct):
import SwiftUI
```

### **Step 5: Clean and Rebuild**

1. **Clean Build Folder**: `Product` → `Clean Build Folder`
2. **Delete Derived Data**: Remove `/Users/davidoconnell/Library/Developer/Xcode/DerivedData/SC40-V3-*`
3. **Rebuild**: `Product` → `Build`

### **Step 6: Verify Compilation**

Both targets should now compile successfully:
- **iOS App**: Should build without errors
- **Watch App**: Should build without errors and access shared types

### **Alternative Solution: Shared Framework**

If target dependencies continue to cause issues, consider creating a shared framework:

1. **Create new target**: File → New → Target → Framework
2. **Name**: `SC40Shared`
3. **Move shared types** to the framework
4. **Link both targets** to the framework

This approach provides better separation and avoids target dependency issues.

### **Common Issues to Watch For**

1. **Entitlements Warning**: The iOS app entitlements file in Compile Sources - this is normal
2. **Module Not Found**: Usually means files aren't in target build phases
3. **Type Not Found**: Usually means wrong import statements or missing target membership

### **Testing Checklist**

- ✅ iOS app compiles successfully
- ✅ Watch app compiles successfully
- ✅ No "Cannot find type" errors
- ✅ No "No such module" errors
- ✅ Cross-platform communication works
- ✅ Shared types accessible from both targets

After following these steps, the project should compile successfully with all 213+ issues resolved.
