# TestFlight Setup Guide 🧪

## Complete Guide to Beta Testing Your App

---

## Prerequisites Checklist

Before uploading to TestFlight:

- [x] App builds successfully
- [x] Core features working
- [ ] NewsAPI key configured
- [ ] App icon added (required)
- [ ] Bundle ID set
- [ ] Version number set
- [ ] Build number set

---

## Step 1: Prepare Your Xcode Project

### 1.1 Set Bundle Identifier

1. Open Xcode project
2. Select target "SC40-V3"
3. Go to "Signing & Capabilities"
4. Set Bundle Identifier: `com.yourcompany.sc40`
   - Replace `yourcompany` with your actual company name
   - Must be unique across App Store

### 1.2 Configure Signing

**Automatic Signing** (Recommended):
1. Check "Automatically manage signing"
2. Select your Team
3. Xcode handles certificates automatically

**Manual Signing** (Advanced):
1. Uncheck "Automatically manage signing"
2. Select Distribution provisioning profile
3. Select Distribution certificate

### 1.3 Set Version & Build Numbers

In Xcode target settings:
- **Version**: `1.0` (user-facing)
- **Build**: `1` (increments with each upload)

Or in Info.plist:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 1.4 Add App Icon

1. Open `Assets.xcassets`
2. Select `AppIcon`
3. Drag icon files to appropriate slots
4. Ensure all required sizes are filled

**Required Sizes**:
- 20×20 (2x, 3x)
- 29×29 (2x, 3x)
- 40×40 (2x, 3x)
- 60×60 (2x, 3x)
- 76×76 (1x, 2x)
- 83.5×83.5 (2x)
- 1024×1024 (1x)

---

## Step 2: Archive Your App

### 2.1 Select Device

1. In Xcode toolbar, select "Any iOS Device (arm64)"
2. Do NOT select a simulator

### 2.2 Clean Build

```
Product → Clean Build Folder
```
Or: `Cmd + Shift + K`

### 2.3 Archive

```
Product → Archive
```
Or: `Cmd + B` (build first), then `Product → Archive`

**Wait Time**: 2-5 minutes depending on project size

### 2.4 Verify Archive

1. Organizer window opens automatically
2. Verify:
   - App name correct
   - Version number correct
   - Build number correct
   - Archive date is today

---

## Step 3: Upload to App Store Connect

### 3.1 Distribute App

1. In Organizer, select your archive
2. Click "Distribute App"
3. Select "App Store Connect"
4. Click "Next"

### 3.2 Distribution Options

**App Store Connect Distribution**:
- [x] Upload
- [ ] Export (for manual upload)

Click "Next"

### 3.3 Distribution Options

**Select options**:
- [x] Include bitcode for iOS content (if available)
- [x] Upload your app's symbols
- [ ] Manage Version and Build Number (optional)

Click "Next"

### 3.4 Re-sign Options

**Automatic Signing** (Recommended):
- Select "Automatically manage signing"
- Click "Next"

### 3.5 Review & Upload

1. Review app information
2. Click "Upload"
3. Wait for upload (5-15 minutes)

**Progress Indicators**:
- Preparing archive
- Uploading
- Processing
- Complete

---

## Step 4: App Store Connect Setup

### 4.1 Create App Record

1. Go to https://appstoreconnect.apple.com/
2. Click "My Apps"
3. Click "+" → "New App"

**Required Information**:
- **Platforms**: iOS
- **Name**: Sprint Coach 40
- **Primary Language**: English (U.S.)
- **Bundle ID**: com.yourcompany.sc40
- **SKU**: SC40-001 (unique identifier)
- **User Access**: Full Access

### 4.2 App Information

**Category**:
- Primary: Health & Fitness
- Secondary: Sports

**Age Rating**:
- Complete questionnaire
- Likely result: 4+

**Privacy Policy URL**:
- Must be publicly accessible
- Example: https://yourwebsite.com/privacy

### 4.3 Pricing & Availability

**Price**:
- Free (with optional IAP)
- Or set price tier

**Availability**:
- All countries (recommended)
- Or select specific countries

**Pre-orders**: No (for first version)

### 4.4 App Privacy

**Data Types Collected**:
- [x] Location (Precise)
- [x] Health & Fitness
- [x] User Content (workout data)
- [x] Identifiers (for analytics)
- [x] Usage Data

**Purpose**:
- App Functionality
- Analytics
- Product Personalization

**Linked to User**: Yes
**Used for Tracking**: No (unless you add analytics)

---

## Step 5: Configure TestFlight

### 5.1 Wait for Processing

After upload:
1. Go to App Store Connect → TestFlight
2. Wait for "Processing" to complete (10-30 minutes)
3. You'll receive email when ready

### 5.2 Test Information

**What to Test**:
```
Welcome to Sprint Coach 40 Beta!

Please test the following features:

1. ONBOARDING
   - Complete profile setup
   - Enter your 40-yard dash time
   - Review training level assignment

2. GPS STOPWATCH
   - Test GPS accuracy outdoors
   - Run a short sprint
   - Verify time and distance tracking

3. TRAINING PROGRAM
   - Browse session library
   - View 12-week program
   - Check session details

4. LEADERBOARD
   - View global rankings
   - Check your position
   - Try different filters

5. SPRINT NEWS
   - Read news articles
   - Test article links

6. AUTOMATED WORKOUT
   - Start a workout session
   - Test pause/resume
   - Complete a full workout

KNOWN ISSUES:
- None currently

FEEDBACK NEEDED:
- GPS accuracy in your location
- UI/UX improvements
- Feature requests
- Bug reports

Report issues to: beta@sc40app.com
```

### 5.3 Add Internal Testers

**Internal Testers** (up to 25):
- Your team members
- Instant access
- No review required

**Steps**:
1. TestFlight → Internal Testing
2. Click "+" to add testers
3. Enter email addresses
4. Testers receive invite email
5. They download TestFlight app
6. Install your app

### 5.4 Add External Testers

**External Testers** (up to 10,000):
- Public beta testers
- Requires Apple review (1-2 days)
- More realistic feedback

**Steps**:
1. TestFlight → External Testing
2. Create test group
3. Add testers via:
   - Email addresses
   - Public link
4. Submit for review
5. Wait for approval
6. Testers receive invites

### 5.5 Public Link (Optional)

**Create Public Link**:
1. External Testing → Enable Public Link
2. Copy link
3. Share on:
   - Social media
   - Website
   - Email list
   - Reddit, forums

**Example**:
```
https://testflight.apple.com/join/ABC123XYZ
```

---

## Step 6: Monitor Beta Testing

### 6.1 Collect Feedback

**TestFlight Feedback**:
- Automatic crash reports
- Screenshot feedback
- Text feedback

**External Channels**:
- Email: beta@sc40app.com
- Survey: Google Forms
- Discord/Slack community
- Social media

### 6.2 Track Metrics

**Key Metrics**:
- Install rate
- Session count
- Crash rate
- Feedback volume
- Feature usage

**TestFlight Analytics**:
- Number of testers
- Number of sessions
- Crashes per session
- Device types
- iOS versions

### 6.3 Iterate

**Update Cycle**:
1. Collect feedback (1 week)
2. Fix critical bugs
3. Implement improvements
4. Increment build number
5. Upload new build
6. Repeat

**Recommended**: 2-4 beta iterations before App Store

---

## Step 7: Prepare for App Store Submission

### 7.1 Final Beta Build

**Checklist**:
- [ ] All critical bugs fixed
- [ ] Performance optimized
- [ ] GPS accuracy verified
- [ ] All features working
- [ ] Tested on multiple devices
- [ ] Positive beta feedback

### 7.2 Create Screenshots

**Required Sizes**:
- 6.7" (1290×2796) - iPhone 15 Pro Max
- 6.5" (1242×2688) - iPhone 11 Pro Max
- 5.5" (1242×2208) - iPhone 8 Plus

**Recommended Screens**:
1. Welcome/Onboarding
2. Training Dashboard
3. GPS Stopwatch
4. Workout in Progress
5. Leaderboard
6. Session Library
7. Sprint News
8. Achievement/Results

**Tools**:
- Screenshot directly from device
- Use Simulator (Cmd+S)
- Edit in Preview or Photoshop
- Add captions with tools like:
  - Figma
  - Canva
  - Screenshot Creator

### 7.3 App Preview Video (Optional)

**Specs**:
- Duration: 15-30 seconds
- Portrait orientation
- Same sizes as screenshots
- Show app in action
- No audio required (but recommended)

**Content**:
- Quick app tour
- Key features highlight
- Smooth transitions
- Call-to-action at end

### 7.4 Final Description

Use content from `APP_STORE_DESCRIPTION.md`:
- Copy app description
- Add keywords
- Write "What's New"
- Set categories

---

## Step 8: Submit for Review

### 8.1 Final Checklist

- [ ] All metadata complete
- [ ] Screenshots uploaded (all sizes)
- [ ] App icon uploaded
- [ ] Description finalized
- [ ] Keywords optimized
- [ ] Privacy policy URL working
- [ ] Terms of service URL working
- [ ] Support URL working
- [ ] Pricing set
- [ ] Age rating completed
- [ ] App privacy completed
- [ ] Build selected

### 8.2 Submit

1. Go to App Store Connect
2. Select your app
3. Click "Submit for Review"
4. Answer review questions:
   - Demo account (if needed)
   - Testing instructions
   - Contact information
   - Notes for reviewer

### 8.3 Review Process

**Timeline**:
- Waiting for Review: 0-2 days
- In Review: 1-24 hours
- Approved: Instant
- Total: Usually 1-3 days

**Possible Outcomes**:
- ✅ Approved → App goes live
- ⚠️ Metadata Rejected → Fix and resubmit
- ❌ Rejected → Address issues and resubmit

---

## Common Issues & Solutions

### Issue: "Invalid Bundle"

**Cause**: Missing required icons or info.plist entries

**Solution**:
1. Verify all icon sizes present
2. Check Info.plist for required keys
3. Validate archive before upload

### Issue: "Missing Compliance"

**Cause**: Encryption export compliance not answered

**Solution**:
1. In App Store Connect → App Information
2. Answer encryption questions
3. Most apps: "No" (unless using custom encryption)

### Issue: "Invalid Provisioning Profile"

**Cause**: Certificate or profile issues

**Solution**:
1. Use automatic signing
2. Or regenerate profiles in Developer Portal
3. Download and install new profiles

### Issue: "Processing Never Completes"

**Cause**: Server-side issue or invalid binary

**Solution**:
1. Wait 1 hour
2. If still processing, contact Apple Support
3. Try uploading again

### Issue: "TestFlight Crashes"

**Cause**: Various code issues

**Solution**:
1. Check crash logs in TestFlight
2. Reproduce locally
3. Fix and upload new build
4. Test thoroughly before next upload

---

## Beta Testing Best Practices

### 1. Clear Communication

**Onboarding Email**:
```
Subject: Welcome to Sprint Coach 40 Beta! 🏃‍♂️

Hi [Name],

Thanks for joining our beta test!

WHAT TO TEST:
- Complete onboarding
- Try GPS stopwatch outdoors
- Browse training sessions
- Check leaderboards
- Test automated workouts

HOW TO REPORT ISSUES:
- Email: beta@sc40app.com
- Include: Device, iOS version, steps to reproduce
- Screenshots helpful!

TIMELINE:
- Beta duration: 2-4 weeks
- Updates: Weekly
- Launch: [Estimated date]

Questions? Reply to this email!

Thanks,
[Your Name]
Sprint Coach 40 Team
```

### 2. Regular Updates

- Weekly build updates
- Changelog for each build
- Thank testers for feedback
- Show progress on fixes

### 3. Incentives (Optional)

- Free lifetime Pro access
- Beta tester badge in app
- Credits in app
- Early access to new features

### 4. Feedback Loop

- Acknowledge all feedback
- Explain what's being fixed
- Show appreciation
- Keep testers engaged

---

## TestFlight Limits

**Internal Testing**:
- 25 testers max
- 100 devices per tester
- 90 days per build
- Unlimited builds

**External Testing**:
- 10,000 testers max
- 90 days per build
- Requires Apple review
- Public link available

**Build Expiration**:
- Builds expire after 90 days
- Upload new build to continue testing
- Testers auto-update to latest

---

## Next Steps After Beta

1. **Analyze Feedback**:
   - Categorize issues
   - Prioritize fixes
   - Plan improvements

2. **Final Polish**:
   - Fix all critical bugs
   - Optimize performance
   - Refine UI/UX

3. **Prepare Launch**:
   - Create screenshots
   - Finalize description
   - Set pricing
   - Plan marketing

4. **Submit to App Store**:
   - Select final build
   - Complete all metadata
   - Submit for review

5. **Launch**:
   - Announce on social media
   - Email subscribers
   - Press release
   - Monitor reviews

---

## Resources

**Apple Documentation**:
- TestFlight: https://developer.apple.com/testflight/
- App Store Connect: https://developer.apple.com/app-store-connect/
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

**Tools**:
- TestFlight App: Download from App Store
- Xcode: https://developer.apple.com/xcode/
- Transporter: For manual uploads

**Support**:
- Apple Developer Forums: https://developer.apple.com/forums/
- Stack Overflow: https://stackoverflow.com/
- Contact Apple: https://developer.apple.com/contact/

---

## Summary

**TestFlight Process**:
1. ✅ Prepare Xcode project
2. ✅ Archive app
3. ✅ Upload to App Store Connect
4. ✅ Create app record
5. ✅ Configure TestFlight
6. ✅ Add testers
7. ✅ Collect feedback
8. ✅ Iterate and improve
9. ✅ Submit to App Store

**Timeline**: 2-4 weeks of beta testing recommended

**You're ready to start beta testing!** 🚀
