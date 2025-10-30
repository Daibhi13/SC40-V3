# 🔧 BUILD ERROR FIX - HealthKitManager Duplicate

## **Issue Identified**
```
error: Multiple commands produce 'HealthKitManager.stringsdata'
```

## **Root Cause**
- Duplicate HealthKitManager.swift files were found:
  - `/SC40-V3/Services/HealthKitManager.swift` (✅ Complete implementation)
  - `/SC40-V3/Shared/HealthKitManager.swift` (❌ Duplicate - REMOVED)

## **Fix Applied**
1. ✅ Removed duplicate file: `SC40-V3/Shared/HealthKitManager.swift`
2. ✅ Kept complete implementation: `SC40-V3/Services/HealthKitManager.swift`

## **Required Xcode Actions**

### **Step 1: Clean Build Folder**
```
Product → Clean Build Folder (⌘+Shift+K)
```

### **Step 2: Delete Derived Data**
```
Xcode → Preferences → Locations → Derived Data → Delete
```
Or manually delete:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*
```

### **Step 3: Verify Project Structure**
In Xcode Project Navigator, ensure:
- ✅ `Services/HealthKitManager.swift` exists
- ❌ No `Shared/HealthKitManager.swift` (should be removed)
- ✅ File is added to correct target (SC40-V3)

### **Step 4: Rebuild Project**
```
Product → Build (⌘+B)
```

## **If Build Still Fails**

### **Check Target Membership**
1. Select `HealthKitManager.swift` in Project Navigator
2. In File Inspector (right panel), verify:
   - ✅ SC40-V3 target is checked
   - ❌ No duplicate target memberships

### **Check for Phantom References**
If Xcode still shows the old file:
1. Right-click in Project Navigator → "Add Files to SC40-V3"
2. Navigate to `Services/HealthKitManager.swift`
3. Add with correct target membership

### **Nuclear Option - Re-add File**
If all else fails:
1. Remove `HealthKitManager.swift` from project (keep file)
2. Clean build folder
3. Re-add file to project with correct target

## **Verification**
After successful build, verify:
- ✅ HealthKit import works in UserProfileView
- ✅ No duplicate symbol errors
- ✅ App builds and runs successfully

## **Prevention**
- Always check for duplicate files before adding new implementations
- Use consistent file organization (Services/ for managers)
- Regularly clean build folder during development
