# 📱⌚ PAIRED DEVICE TESTING GUIDE

## ✅ SETUP COMPLETE
- **iPhone 14**: `59E325AA-923D-4DD8-AAEF-DACE181F8ACC` (Booted)
- **Apple Watch Ultra 2**: `AD663721-ACEF-42DE-9C8D-ED7643AA20E5` (Booted)
- **Pair ID**: `0ED88135-02A1-4041-AF08-AF73194806D7` (Active)

## 🎯 REAL USER EXPERIENCE TESTING

### **Test Scenario 1: Fresh Install (Real User Flow)**
```
1. In Xcode:
   - Select "iPhone 14 + Apple Watch Ultra 2" destination
   - Run Sprint Coach 40 (Cmd+R)
   
2. Expected Behavior:
   ✅ iPhone app installs and launches
   ✅ Watch app automatically installs in background
   ✅ Watch shows "Sprint Coach" app icon
   ✅ No manual watch app installation needed
```

### **Test Scenario 2: Cross-Device Sync**
```
1. Complete onboarding on iPhone:
   - Enter name: "Test User"
   - Select 3 days/week frequency
   - Complete profile setup
   
2. Check Apple Watch:
   ✅ Sessions should appear automatically
   ✅ No manual sync required
   ✅ Watch shows current week's workouts
```

### **Test Scenario 3: Workout Flow**
```
1. Start workout on iPhone:
   - Navigate to TrainingView
   - Start Week 1 Day 1 workout
   
2. Switch to Apple Watch:
   ✅ Same workout should be available
   ✅ Can start/continue from watch
   ✅ Voice cues work properly
   ✅ Data syncs back to iPhone
```

## 🔧 XCODE SETUP INSTRUCTIONS

### **Device Selection:**
1. In Xcode toolbar, click device selector
2. Choose: **"iPhone 14"** 
3. Verify it shows paired with **"Apple Watch Ultra 2"**
4. Run project (Cmd+R)

### **Watch App Verification:**
1. After iPhone app launches, check Watch simulator
2. Look for Sprint Coach app icon on watch home screen
3. If not visible, swipe to find it or check App Library

### **Debugging Paired Installation:**
```bash
# Check if watch app installed
xcrun simctl list apps AD663721-ACEF-42DE-9C8D-ED7643AA20E5 | grep -i sprint

# Force install watch app if needed
xcrun simctl install AD663721-ACEF-42DE-9C8D-ED7643AA20E5 /path/to/watch/app
```

## 🚨 TROUBLESHOOTING

### **If Watch App Doesn't Auto-Install:**
1. Check Xcode scheme includes Watch target
2. Verify Watch app bundle ID matches iPhone app
3. Ensure proper entitlements for watch companion

### **If Pairing Issues:**
```bash
# Reset pairing
xcrun simctl unpair 0ED88135-02A1-4041-AF08-AF73194806D7
xcrun simctl pair 59E325AA-923D-4DD8-AAEF-DACE181F8ACC AD663721-ACEF-42DE-9C8D-ED7643AA20E5
```

### **If Sync Issues:**
1. Check WatchConnectivity framework integration
2. Verify session transfer in WatchSessionManager
3. Test manual sync from iPhone settings

## ✅ SUCCESS CRITERIA

### **Automatic Installation:**
- [ ] iPhone app installs when run from Xcode
- [ ] Watch app appears automatically (no manual install)
- [ ] Both apps launch successfully

### **Data Synchronization:**
- [ ] Onboarding data syncs to watch
- [ ] Training sessions appear on watch
- [ ] Workout progress syncs back to phone

### **Real User Experience:**
- [ ] No technical setup required
- [ ] Seamless cross-device experience
- [ ] Professional app behavior

## 🎯 NEXT STEPS

1. **Run iPhone app** from Xcode with paired destination
2. **Verify watch app** appears automatically
3. **Test complete user flow** from onboarding to workout
4. **Document any issues** for next week's testing

**This setup now mirrors the real App Store user experience!** 📱⌚✨
