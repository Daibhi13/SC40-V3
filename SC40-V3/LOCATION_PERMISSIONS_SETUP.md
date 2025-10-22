# Location Permissions Setup for GPS Integration

## Required Info.plist Entries

Add these entries to your app's Info.plist file through Xcode:

### 1. Location When In Use Usage Description
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SC40 needs location access to accurately time your sprints and measure distances during training sessions.</string>
```

### 2. Location Always and When In Use Usage Description
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>SC40 uses location services to provide precise sprint timing and distance measurement for optimal training results.</string>
```

## How to Add in Xcode:

1. Open your project in Xcode
2. Select the SC40-V3 target
3. Go to the "Info" tab
4. Click the "+" button to add new entries
5. Add both keys above with their descriptions

## Alternative Method:

1. Right-click on Info.plist in Xcode navigator
2. Choose "Open As" → "Source Code"
3. Add the XML entries above inside the `<dict>` tags

## Verification:

After adding, your Info.plist should contain both location permission keys. The GPS integration will request permission when first used.
