# Sprint Coach 40 - Legal Documents

This folder contains the legal documents for the Sprint Coach 40 iOS app.

## Documents

- **index.html** - Landing page with links to all legal documents
- **privacy.html** - Privacy Policy
- **terms.html** - Terms of Service

## GitHub Pages Setup

### Quick Setup (5 minutes)

1. **Create GitHub Repository**
   ```bash
   cd /Users/davidoconnell/Projects/SC40-V3
   git init
   git add docs/
   git commit -m "Add legal documents"
   ```

2. **Push to GitHub**
   ```bash
   # Create repo on github.com first, then:
   git remote add origin https://github.com/YOUR_USERNAME/sc40-legal.git
   git branch -M main
   git push -u origin main
   ```

3. **Enable GitHub Pages**
   - Go to repository Settings
   - Scroll to "Pages" section
   - Source: Deploy from branch
   - Branch: main
   - Folder: /docs
   - Click Save

4. **Get Your URLs**
   After a few minutes, your documents will be live at:
   - Landing: `https://YOUR_USERNAME.github.io/sc40-legal/`
   - Privacy: `https://YOUR_USERNAME.github.io/sc40-legal/privacy.html`
   - Terms: `https://YOUR_USERNAME.github.io/sc40-legal/terms.html`

## For App Store Connect

Use these URLs in App Store Connect:
- **Privacy Policy URL**: `https://YOUR_USERNAME.github.io/sc40-legal/privacy.html`
- **Terms of Service URL**: `https://YOUR_USERNAME.github.io/sc40-legal/terms.html`
- **Support URL**: `https://YOUR_USERNAME.github.io/sc40-legal/`

## Alternative: Custom Domain

If you have a domain (e.g., sc40app.com):

1. Add CNAME file in docs folder:
   ```
   echo "sc40app.com" > docs/CNAME
   ```

2. Configure DNS:
   - Add CNAME record pointing to: `YOUR_USERNAME.github.io`

3. URLs become:
   - Privacy: `https://sc40app.com/privacy.html`
   - Terms: `https://sc40app.com/terms.html`

## Local Testing

To test locally before deploying:
```bash
cd docs
python3 -m http.server 8000
# Visit: http://localhost:8000
```

## Updates

To update documents:
1. Edit HTML files in docs folder
2. Commit and push changes
3. GitHub Pages updates automatically

---

**Last Updated**: September 30, 2025
