# API Key Setup Instructions

## NewsAPI Key Setup

### Step 1: Get Your Free API Key

1. Visit https://newsapi.org/register
2. Fill out the registration form:
   - First Name
   - Email Address
   - Password
3. Click "Submit"
4. Check your email for verification
5. Click the verification link
6. Log in to your NewsAPI account
7. Your API key will be displayed on the dashboard

### Step 2: Update the App

1. Open `SC40-V3/UI/NewsViewModel.swift`
2. Find line 31:
```swift
private let apiKey = "YOUR_NEWSAPI_KEY_HERE" // ⚠️ REPLACE THIS
```
3. Replace `YOUR_NEWSAPI_KEY_HERE` with your actual API key
4. Save the file

### Step 3: Test the News Feed

1. Build and run the app
2. Navigate to Hamburger Menu → News
3. Verify that real news articles load
4. If you see mock news, check:
   - API key is correct
   - Device has internet connection
   - NewsAPI service is operational

### Free Tier Limits

**NewsAPI Free Plan**:
- 100 requests per day
- Access to 80,000+ news sources
- 1 month of historical data
- Development use only

**Upgrade Options**:
- Business Plan: $449/month
- Unlimited requests
- Production use allowed
- 2 years of historical data

### Production Considerations

For production apps, consider:

1. **Secure Storage**: Store API key in Keychain
2. **Backend Proxy**: Call NewsAPI from your server
3. **Caching**: Cache articles to reduce API calls
4. **Error Handling**: Graceful fallback to mock data
5. **Rate Limiting**: Track daily usage

### Alternative: Backend Implementation

Instead of client-side API calls, implement a backend:

```
iOS App → Your Backend → NewsAPI
```

**Benefits**:
- Hide API key from client
- Better rate limit control
- Custom filtering
- Caching layer
- Analytics

### Secure Implementation (Recommended)

Create a configuration file that's not committed to git:

1. Create `Config.swift`:
```swift
struct Config {
    static let newsAPIKey = "YOUR_KEY_HERE"
}
```

2. Add to `.gitignore`:
```
Config.swift
```

3. Update `NewsViewModel.swift`:
```swift
private let apiKey = Config.newsAPIKey
```

4. Provide `Config.swift.template` for other developers:
```swift
struct Config {
    static let newsAPIKey = "YOUR_NEWSAPI_KEY_HERE"
}
```

---

## Next Steps

After setting up the API key:

1. ✅ Test news feed functionality
2. ✅ Verify API calls work
3. ✅ Monitor daily usage
4. ✅ Plan for production (backend or paid plan)
5. ✅ Update before App Store submission

---

## Troubleshooting

**Problem**: News feed shows mock data
**Solution**: 
- Verify API key is correct
- Check internet connection
- Ensure NewsAPI service is up

**Problem**: "Rate limit exceeded" error
**Solution**:
- You've hit 100 requests/day limit
- Wait 24 hours or upgrade plan
- Implement caching to reduce calls

**Problem**: "Invalid API key" error
**Solution**:
- Double-check API key spelling
- Ensure no extra spaces
- Verify account is active

---

## Contact

Questions about API setup?
- Email: support@sc40app.com
- NewsAPI Support: https://newsapi.org/contact
