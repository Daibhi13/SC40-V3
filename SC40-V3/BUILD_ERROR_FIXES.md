# Build Error Fixes - SC40-V3

## 🔧 Common Build Errors & Solutions

---

## Error 1: Info.plist Duplicate Output

### Error Message:
```
Multiple commands produce '.../SC40-V3.app/Info.plist'
duplicate output file '.../Info.plist' on task: ProcessInfoPlistFile
```

### Cause:
`Info.plist` was accidentally added to "Copy Bundle Resources" build phase when dragging files into Xcode.

### ✅ Solution (Xcode UI - RECOMMENDED):

1. **Open Xcode**: `open SC40-V3.xcodeproj`

2. **Select Target**:
   - Click on "SC40-V3" project in left sidebar
   - Select "SC40-V3" target (under TARGETS)

3. **Go to Build Phases**:
   - Click "Build Phases" tab at top

4. **Remove Info.plist**:
   - Expand "Copy Bundle Resources" section
   - Find "Info.plist" in the list
   - Select it
   - Click the "−" (minus) button to remove it

5. **Clean & Build**:
   ```
   Clean: Cmd + Shift + K
   Build: Cmd + B
   ```

### Why This Works:
Info.plist is automatically processed by Xcode's build system. It should NOT be in Copy Bundle Resources - Xcode handles it automatically.

---

## Error 2: Cannot Find Types in Scope

### Error Messages:
```
Cannot find 'UserProfileViewModel' in scope
Cannot find 'WelcomeView' in scope
Cannot find 'OnboardingView' in scope
Cannot find 'TrainingView' in scope
```

### Cause:
Files exist in filesystem but haven't been added to Xcode project target.

### ✅ Solution:

1. **Add Models Folder**:
   - Right-click on "SC40-V3" group in Xcode
   - Select "Add Files to SC40-V3..."
   - Navigate to `SC40-V3/Models`
   - Select the `Models` folder
   - ✅ Check "Create groups"
   - ✅ Check "Add to targets: SC40-V3"
   - Click "Add"

2. **Add Services Folder**:
   - Same process for `SC40-V3/Services`

3. **Add UI Folder**:
   - Same process for `SC40-V3/UI`

4. **Build**:
   ```
   Cmd + B
   ```

### Why This Works:
Xcode needs to know which files belong to which target. Adding folders to the target makes them available for compilation.

---

## Error 3: Missing Swift Algorithms Package

### Error Message:
```
Unable to find module dependency: 'Algorithms'
import Algorithms
```

### Cause:
The project uses Swift Algorithms package which hasn't been added yet.

### ✅ Solution:

1. **Add Swift Package**:
   - File → Add Package Dependencies...
   - Enter URL: `https://github.com/apple/swift-algorithms`
   - Click "Add Package"
   - Select version: "Up to Next Major Version"
   - Click "Add Package"

2. **Verify Target**:
   - Ensure "SC40-V3" target is checked
   - Click "Add Package"

3. **Build**:
   ```
   Clean: Cmd + Shift + K
   Build: Cmd + B
   ```

See **SWIFT_PACKAGE_DEPENDENCIES.md** for complete package guide.

---

## Error 4: Missing Firebase SDK (Optional)

### Error Messages:
```
Cannot find 'Firebase' in scope
Cannot find 'FirebaseAuth' in scope
Cannot find 'FirebaseFirestore' in scope
```

### Note:
Only add Firebase if you're using backend services. The app may work without it.

### ✅ Solution:

1. **Add Swift Package**:
   - File → Add Package Dependencies...
   - Enter URL: `https://github.com/firebase/firebase-ios-sdk`
   - Click "Add Package"

2. **Select Products**:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseAnalytics (optional)
   - Click "Add Package"

3. **Build**:
   ```
   Cmd + B
   ```

---

## Error 4: Watch App - Duplicate @main Entry Points

### Error Message:
```
'main' attribute can only apply to one type in a module
```

### Cause:
Multiple files have `@main` attribute. Only one entry point is allowed per app.

### ✅ Solution:

**Quick Fix**: Remove `@main` from duplicate files.

1. **Find Duplicate @main Files**:
   ```bash
   grep -r "@main" "SC40-V3-W Watch App Watch App" --include="*.swift"
   ```

2. **Keep Only One**:
   - Keep: `SC40_V3_W_Watch_AppApp.swift` (Xcode-generated)
   - Remove `@main` from: `SprintCoachWatchApp.swift`

3. **Edit SprintCoachWatchApp.swift**:
   ```swift
   // Remove @main, rename struct
   struct SprintCoachWatchApp_Unused: App {
       var body: some Scene {
           WindowGroup {
               EntryViewWatch()
           }
       }
   }
   ```

4. **Build**:
   ```
   Cmd + Shift + K (Clean)
   Cmd + B (Build)
   ```

See **WATCH_BUILD_FIX.md** for detailed explanation.

---

## Error 5: Watch App Build Errors

### Error Messages:
```
Cannot find type 'WatchConnectivityManager' in scope
Missing Watch target files
```

### ✅ Solution:

1. **Add Watch Files**:
   - Select "SC40-V3-W Watch App Watch App" target
   - Right-click on Watch app group
   - Add Files to "SC40-V3-W Watch App Watch App"
   - Add all Watch folders:
     - Views Watch/
     - Services Watch/
     - Models Watch/
     - ViewModels Watch/
     - Utils Watch/

2. **Verify Target Membership**:
   - Select a Watch file in Xcode
   - Check File Inspector (right panel)
   - Ensure "SC40-V3-W Watch App Watch App" is checked

3. **Build Watch App**:
   - Select Watch scheme from scheme selector
   - Cmd + B

---

## Error 5: Derived Data Corruption

### Symptoms:
- Random build errors
- "Command failed" errors
- Inconsistent build results

### ✅ Solution:

1. **Clean Build Folder**:
   ```
   Cmd + Shift + K
   ```

2. **Delete Derived Data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*
   ```

3. **Restart Xcode**:
   - Quit Xcode completely
   - Reopen project

4. **Build**:
   ```
   Cmd + B
   ```

---

## Error 6: Multiple Targets with Same Files

### Error Message:
```
Duplicate symbols for architecture arm64
```

### ✅ Solution:

1. **Check Target Membership**:
   - Select problematic file in Xcode
   - Check File Inspector (right panel)
   - Ensure file is ONLY in correct target
   - Uncheck other targets

2. **Common Issue**:
   - iPhone files should only be in "SC40-V3" target
   - Watch files should only be in "SC40-V3-W Watch App Watch App" target

---

## Quick Fix Checklist

When you get build errors, try these in order:

- [ ] **Clean Build**: Cmd + Shift + K
- [ ] **Check Info.plist**: Remove from Copy Bundle Resources
- [ ] **Check Target Membership**: Files in correct target only
- [ ] **Add Missing Folders**: Models, Services, UI to project
- [ ] **Delete Derived Data**: `rm -rf ~/Library/Developer/Xcode/DerivedData/SC40-V3-*`
- [ ] **Restart Xcode**: Quit and reopen
- [ ] **Check Swift Package Dependencies**: Firebase SDK added
- [ ] **Verify Scheme**: Correct scheme selected (iPhone vs Watch)

---

## Still Having Issues?

### Check These:

1. **Xcode Version**: Ensure you're using Xcode 15.0+
2. **iOS Deployment Target**: Set to iOS 17.0+
3. **watchOS Deployment Target**: Set to watchOS 10.0+
4. **Swift Version**: Swift 5.9+

### Get Help:

1. Review **XCODE_SETUP_GUIDE.md** for detailed setup
2. Check **README.md** for project overview
3. Run `./verify_rebuild.sh` to verify files are in place

---

## Common Xcode Settings to Check

### Build Settings:
- **Info.plist File**: Should point to `SC40-V3/Info.plist`
- **Product Bundle Identifier**: `com.yourcompany.SC40-V3`
- **Swift Language Version**: Swift 5
- **Enable Bitcode**: No (for modern apps)

### Build Phases:
- **Compile Sources**: Should have all .swift files
- **Copy Bundle Resources**: Should NOT have Info.plist
- **Link Binary With Libraries**: Should have required frameworks

---

## Success Indicators

You'll know everything is working when:

- ✅ Build completes without errors
- ✅ No "duplicate output" warnings
- ✅ All types found in scope
- ✅ App runs on simulator
- ✅ Watch app builds successfully

---

**Most Common Issue**: Info.plist in Copy Bundle Resources

**Quick Fix**: Remove it from Build Phases → Copy Bundle Resources

**Then**: Clean (Cmd + Shift + K) and Build (Cmd + B)
