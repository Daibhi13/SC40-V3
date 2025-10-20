# Legal Documents - GitHub Pages Setup Guide

## ✅ What's Ready

I've created professional HTML versions of your legal documents:

- ✅ **index.html** - Beautiful landing page
- ✅ **privacy.html** - Complete Privacy Policy
- ✅ **terms.html** - Complete Terms of Service
- ✅ All documents are mobile-responsive
- ✅ Professional styling with your brand colors

**Location**: `/Users/davidoconnell/Projects/SC40-V3/docs/`

---

## 🚀 Quick Setup (10 minutes)

### Option 1: GitHub Pages (FREE - Recommended)

#### Step 1: Create GitHub Repository (2 minutes)

```bash
# Navigate to your project
cd /Users/davidoconnell/Projects/SC40-V3

# Initialize git (if not already done)
git init

# Add docs folder
git add docs/

# Commit
git commit -m "Add legal documents for App Store"
```

#### Step 2: Push to GitHub (3 minutes)

1. **Go to GitHub.com**
2. **Click "New Repository"**
3. **Name**: `sc40-legal` (or any name)
4. **Public** (required for free GitHub Pages)
5. **Click "Create repository"**

6. **Push your code**:
```bash
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/sc40-legal.git
git branch -M main
git push -u origin main
```

#### Step 3: Enable GitHub Pages (2 minutes)

1. **Go to your repository on GitHub**
2. **Click "Settings"** (top menu)
3. **Scroll to "Pages"** (left sidebar)
4. **Under "Source"**:
   - Branch: `main`
   - Folder: `/docs`
5. **Click "Save"**
6. **Wait 1-2 minutes** for deployment

#### Step 4: Get Your URLs (1 minute)

Your documents will be live at:

```
Landing Page:
https://YOUR_USERNAME.github.io/sc40-legal/

Privacy Policy:
https://YOUR_USERNAME.github.io/sc40-legal/privacy.html

Terms of Service:
https://YOUR_USERNAME.github.io/sc40-legal/terms.html
```

**Replace `YOUR_USERNAME` with your actual GitHub username**

---

## 📝 For App Store Connect

When you submit your app, use these URLs:

**Privacy Policy URL**:
```
https://YOUR_USERNAME.github.io/sc40-legal/privacy.html
```

**Terms of Service URL** (if asked):
```
https://YOUR_USERNAME.github.io/sc40-legal/terms.html
```

**Support URL**:
```
https://YOUR_USERNAME.github.io/sc40-legal/
```

---

## 🧪 Test Before Publishing

Test locally first:

```bash
cd /Users/davidoconnell/Projects/SC40-V3/docs
python3 -m http.server 8000
```

Then visit: http://localhost:8000

Check:
- ✅ All links work
- ✅ Mobile responsive
- ✅ Content is correct
- ✅ No typos

---

## 🎨 Customization (Optional)

### Update Contact Email

In all three HTML files, replace:
- `privacy@sc40app.com` → Your actual email
- `support@sc40app.com` → Your actual email

### Update Company Info

If you have a company name or address, add it to the footer sections.

---

## 🌐 Alternative: Custom Domain (Optional)

If you buy a domain like `sc40app.com`:

### Step 1: Add CNAME file

```bash
cd /Users/davidoconnell/Projects/SC40-V3/docs
echo "sc40app.com" > CNAME
git add CNAME
git commit -m "Add custom domain"
git push
```

### Step 2: Configure DNS

In your domain registrar (Namecheap, GoDaddy, etc.):

Add CNAME record:
```
Type: CNAME
Name: www (or @)
Value: YOUR_USERNAME.github.io
```

### Step 3: Enable HTTPS

In GitHub Pages settings:
- Check "Enforce HTTPS"

Your URLs become:
```
https://sc40app.com/privacy.html
https://sc40app.com/terms.html
```

---

## ✅ Verification Checklist

After setup:

- [ ] Privacy Policy loads correctly
- [ ] Terms of Service loads correctly
- [ ] Landing page loads correctly
- [ ] All links work
- [ ] Mobile responsive (test on phone)
- [ ] HTTPS enabled (secure)
- [ ] URLs saved for App Store Connect

---

## 🔄 Updating Documents

To update in the future:

```bash
# Edit HTML files
nano /Users/davidoconnell/Projects/SC40-V3/docs/privacy.html

# Commit and push
git add docs/
git commit -m "Update privacy policy"
git push

# GitHub Pages updates automatically in 1-2 minutes
```

---

## 🆘 Troubleshooting

### "404 Not Found"
- Wait 2-3 minutes after enabling Pages
- Check branch is set to `main`
- Check folder is set to `/docs`
- Verify files are in docs folder

### "Page not updating"
- Clear browser cache
- Wait a few minutes
- Check git push was successful

### "Can't enable Pages"
- Repository must be Public
- Verify you're on a free GitHub plan

---

## 📊 What You Get

### Professional Legal Pages

**Privacy Policy includes**:
- Data collection disclosure
- Location data usage
- User rights (GDPR, CCPA)
- Health data handling
- Third-party services
- Contact information

**Terms of Service includes**:
- Health disclaimers
- User responsibilities
- Intellectual property
- Subscription terms
- Liability limitations
- Apple-specific terms

**Landing Page includes**:
- Beautiful design
- Easy navigation
- Contact information
- Mobile responsive

---

## 🎉 Summary

**Time**: 10 minutes
**Cost**: FREE
**Result**: Professional legal documents hosted and ready for App Store

**Your URLs** (after setup):
```
Privacy: https://YOUR_USERNAME.github.io/sc40-legal/privacy.html
Terms: https://YOUR_USERNAME.github.io/sc40-legal/terms.html
```

**Next Step**: Copy these URLs and save them for App Store Connect submission!

---

## 📞 Need Help?

If you get stuck:
1. Check GitHub Pages documentation
2. Verify repository is Public
3. Wait a few minutes after enabling Pages
4. Clear browser cache

**You're almost done! Just 10 minutes to host your legal documents!** 🚀
