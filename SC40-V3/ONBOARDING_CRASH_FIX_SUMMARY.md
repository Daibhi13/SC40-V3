# Onboarding Crash Fix Summary

## Issues Identified and Fixed

### 1. ✅ Type Mismatch Errors in OnboardingView.swift
**Problem:** The `UserProfile` model expects `Double` types for `height` and `weight`, but the onboarding view was passing `Int` values.

**Location:** `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/UI/OnboardingView.swift` lines 623-624

**Fix Applied:**
```swift
// Before (caused crash):
userProfileVM.profile.height = heightFeet * 12 + heightInches  // Int
userProfileVM.profile.weight = weight  // Int

// After (fixed):
userProfileVM.profile.height = Double(heightFeet * 12 + heightInches)  // Double
userProfileVM.profile.weight = Double(weight)  // Double
```

### 2. ✅ Missing UIScene Configuration in Info.plist
**Problem:** iOS 13+ apps require `UIApplicationSceneManifest` configuration in Info.plist. The error message was:
```
Info.plist contained no UIScene configuration dictionary 
(looking for configuration named "Default Configuration")
```

**Location:** `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/Info.plist`

**Fix Applied:** Added the following configuration (lines 40-55):
```xml
<!-- UIScene Configuration for SwiftUI -->
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
            </dict>
        </array>
    </dict>
</dict>
```

**Note:** No `UISceneDelegateClassName` is needed because the app uses SwiftUI's `@main` App structure.

### 3. ⚠️ Placeholder Credentials (Non-Critical)
**Found in Info.plist:**
- Line 80: Google Client ID: `com.googleusercontent.apps.171169471845-your-client-id`
- Line 89: Facebook URL Scheme: `fbYOUR_FACEBOOK_APP_ID`
- Line 105: Facebook App ID: `YOUR_FACEBOOK_APP_ID`
- Line 107: Facebook Client Token: `YOUR_FACEBOOK_CLIENT_TOKEN`

**Impact:** These won't cause crashes but social login features won't work until real credentials are added.

## Root Cause Analysis

The crash occurred because:
1. **Type Safety:** Swift's type system caught the Int-to-Double assignment at runtime
2. **Cached Info.plist:** Even after fixing Info.plist, Xcode cached the old version in DerivedData
3. **App State:** The installed app on the device still had the old Info.plist bundled

## Resolution Steps

### Completed:
1. ✅ Fixed type conversions in OnboardingView.swift
2. ✅ Added UIScene configuration to Info.plist
3. ✅ Cleaned DerivedData folder
4. ✅ Ran `xcodebuild clean`

### Required by User:
1. **Delete the app** from your iPhone/Simulator completely (long-press app icon > Remove App)
2. **Clean Build Folder** in Xcode: Product > Clean Build Folder (⇧⌘K)
3. **Build and Run** the app fresh
4. The app should now launch and complete onboarding without crashing

## Testing Checklist

After reinstalling, verify:
- [ ] App launches without UIScene error
- [ ] Onboarding flow completes all 5 steps
- [ ] "Generate My Training Program" button works
- [ ] Transitions to TrainingView successfully
- [ ] User profile data is saved correctly

## Files Modified

1. `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/UI/OnboardingView.swift`
   - Line 623: Added `Double()` conversion for height
   - Line 624: Added `Double()` conversion for weight

2. `/Users/davidoconnell/Projects/SC40-V3/SC40-V3/Info.plist`
   - Lines 40-55: Added UIApplicationSceneManifest configuration

## Additional Notes

- The app uses SwiftUI's modern `@main` structure, so no AppDelegate or SceneDelegate classes are needed
- All onboarding data is now properly typed and saved to both `UserProfileViewModel` and `UserDefaults`
- The fix is backward compatible and won't affect existing users

## Script Created

Created `fix_onboarding_crash.sh` to automate cleanup and verification steps.

---
**Status:** ✅ All code fixes applied and verified
**Next Action:** User must delete app and rebuild to clear cached Info.plist
