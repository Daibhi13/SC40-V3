# 🔐 Authentication Setup Guide for Sprint Coach 40

## ✅ **What's Already Implemented**

### Core Authentication System:
- ✅ **AuthenticationManager.swift** - Centralized authentication handling
- ✅ **EmailSignupView.swift** - Premium email signup modal
- ✅ **InstagramAuthService.swift** - Instagram OAuth implementation
- ✅ **FirebaseService.swift** - Backend integration service
- ✅ **AppDelegate.swift** - SDK configuration
- ✅ **WelcomeView** - Updated with real authentication flows

### Authentication Methods:
- ✅ **Apple Sign-In**: Fully functional with AuthenticationServices
- ✅ **Facebook Login**: Real SDK integration (needs SDK installation)
- ✅ **Google Sign-In**: Real SDK integration (needs SDK installation)
- ✅ **Instagram OAuth**: Custom OAuth implementation
- ✅ **Email Registration**: Full validation and user creation

## 📦 **Step 1: Add SDK Dependencies**

### Option A: Using Xcode Package Manager (Recommended)
1. Open Xcode project
2. Go to **File → Add Package Dependencies**
3. Add these URLs one by one:

```
Firebase SDK:
https://github.com/firebase/firebase-ios-sdk

Facebook SDK:
https://github.com/facebook/facebook-ios-sdk

Google Sign-In SDK:
https://github.com/google/GoogleSignIn-iOS
```

4. Select these products:
   - **Firebase**: FirebaseAuth, FirebaseFirestore, FirebaseAnalytics
   - **Facebook**: FacebookLogin, FacebookCore
   - **Google**: GoogleSignIn

### Option B: Using Swift Package Manager
The `Package.swift` file is already created with dependencies.

## 🔧 **Step 2: Configure SDKs**

### Firebase Configuration:
1. **Create Firebase Project**: Go to [Firebase Console](https://console.firebase.google.com)
2. **Add iOS App**: Use bundle ID `com.accelerate.SC40-V3`
3. **Download GoogleService-Info.plist**: Replace the placeholder file
4. **Enable Authentication**: Enable Apple, Google, Facebook, Email providers

### Facebook Configuration:
1. **Create Facebook App**: Go to [Facebook Developers](https://developers.facebook.com)
2. **Add iOS Platform**: Configure bundle ID and App Store ID
3. **Update Info.plist**: Add Facebook App ID and URL schemes
4. **Get App ID and Secret**: Update InstagramAuthService.swift

### Google Configuration:
1. **Google Cloud Console**: Enable Google Sign-In API
2. **OAuth 2.0 Client**: Create iOS client ID
3. **Update GoogleService-Info.plist**: With correct client ID

### Instagram Configuration:
1. **Instagram Basic Display**: Create app at [Facebook Developers](https://developers.facebook.com)
2. **Update InstagramAuthService.swift**:
   ```swift
   private let clientId = "YOUR_ACTUAL_INSTAGRAM_CLIENT_ID"
   private let clientSecret = "YOUR_ACTUAL_INSTAGRAM_CLIENT_SECRET"
   private let redirectURI = "https://your-domain.com/auth/instagram/callback"
   ```

## 📱 **Step 3: Update Info.plist**

Add these entries to your `Info.plist`:

```xml
<!-- Facebook Configuration -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.accelerate.SC40-V3</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb[YOUR_FACEBOOK_APP_ID]</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLName</key>
        <string>google</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>[YOUR_REVERSED_CLIENT_ID]</string>
        </array>
    </dict>
</array>

<key>FacebookAppID</key>
<string>[YOUR_FACEBOOK_APP_ID]</string>
<key>FacebookClientToken</key>
<string>[YOUR_FACEBOOK_CLIENT_TOKEN]</string>
<key>FacebookDisplayName</key>
<string>Sprint Coach 40</string>

<!-- LSApplicationQueriesSchemes for Facebook -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>fbauth2</string>
    <string>fbshareextension</string>
</array>
```

## 🧪 **Step 4: Testing Authentication Flows**

### Test on Device (Required for Social Login):
1. **Build and Run** on physical device (simulators don't support social login)
2. **Test Each Provider**:
   - ✅ Apple Sign-In: Should work immediately
   - ✅ Email Signup: Should work immediately
   - 🔧 Facebook: Requires SDK installation and configuration
   - 🔧 Google: Requires SDK installation and configuration
   - 🔧 Instagram: Requires app credentials

### Testing Checklist:
- [ ] Apple Sign-In returns name and email
- [ ] Facebook login returns profile data
- [ ] Google Sign-In returns profile data
- [ ] Instagram OAuth returns username
- [ ] Email signup validates and creates user
- [ ] Firebase backend saves user data
- [ ] Error handling works for failed logins
- [ ] Navigation to OnboardingView after success

## 🔥 **Step 5: Firebase Backend Integration**

### Firestore Database Structure:
```
users/
  {userId}/
    - id: string
    - name: string
    - email: string
    - profileImageURL: string
    - provider: string
    - createdAt: timestamp
    - lastLoginAt: timestamp

trainingSessions/
  {sessionId}/
    - userId: string
    - type: string
    - completedAt: timestamp
    - sprints: array

performanceData/
  {dataId}/
    - userId: string
    - timestamp: timestamp
    - metrics: object
```

### Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /trainingSessions/{sessionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

## 🚀 **Step 6: Production Deployment**

### Before App Store Submission:
1. **Test All Flows**: On multiple devices and iOS versions
2. **Privacy Policy**: Update with social login data usage
3. **App Store Connect**: Configure Sign in with Apple capability
4. **Facebook Review**: Submit for public use if needed
5. **Analytics**: Verify Firebase Analytics integration

### Performance Monitoring:
- Monitor authentication success rates
- Track user registration funnel
- Monitor Firebase backend performance
- Set up crash reporting for auth failures

## 🔧 **Troubleshooting**

### Common Issues:
1. **"Cannot find module"**: SDKs not properly added to project
2. **Facebook login fails**: Info.plist not configured correctly
3. **Google Sign-In crashes**: GoogleService-Info.plist missing or incorrect
4. **Instagram OAuth fails**: Redirect URI not matching
5. **Firebase errors**: Project not configured or rules too restrictive

### Debug Steps:
1. Check Xcode console for detailed error messages
2. Verify all configuration files are in project
3. Test on physical device (not simulator)
4. Check Firebase console for authentication events
5. Verify bundle IDs match across all platforms

## 📊 **Expected Results**

After complete setup:
- ✅ **Apple Sign-In**: Native iOS experience with Face ID/Touch ID
- ✅ **Facebook Login**: Seamless login with profile data
- ✅ **Google Sign-In**: Quick authentication with Google account
- ✅ **Instagram OAuth**: Username-based authentication
- ✅ **Email Signup**: Full validation and user creation
- ✅ **Firebase Backend**: Automatic user data synchronization
- ✅ **Cross-Device Sync**: User data available across devices

The authentication system will provide a professional, secure login experience that matches industry standards while maintaining Sprint Coach 40's premium design aesthetic.
