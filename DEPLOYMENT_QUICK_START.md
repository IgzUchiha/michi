# 🚀 Quick Deployment Guide

Get Rustaceaans from localhost to production in 30 minutes!

---

## ✅ What's Ready

- ✅ **Database:** PostgreSQL support added (sqlx)
- ✅ **Cloud Storage:** AWS S3 support added
- ✅ **Privacy Policy:** `privacy-policy.html` ready to host
- ✅ **Dockerfile:** Ready for deployment
- ✅ **Environment Config:** `.env.example` with all variables

---

## 🎯 Deployment Steps

### Step 1: Deploy to Railway (FREE!)

Railway gives you:
- Free PostgreSQL database
- Free hosting
- Automatic HTTPS
- Easy deployment

**Do this:**
```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login
railway login

# 3. Create new project
railway init

# 4. Add PostgreSQL database
railway add --database postgres

# 5. Deploy!
railway up
```

**Get your URL:** `https://your-app.railway.app`

---

### Step 2: Set Environment Variables

In Railway dashboard:

```bash
# Database (automatically set by Railway)
DATABASE_URL=postgresql://...

# Storage (use local for now, S3 later)
STORAGE_TYPE=local
API_BASE_URL=https://your-app.railway.app

# Optional: Add S3 later
# AWS_ACCESS_KEY_ID=...
# AWS_SECRET_ACCESS_KEY=...
# S3_BUCKET=rustaceaans-uploads
```

---

### Step 3: Host Privacy Policy

**Option A: GitHub Pages (FREE)**
```bash
# 1. Create new GitHub repo "rustaceaans-privacy"
# 2. Push privacy-policy.html
# 3. Enable GitHub Pages in repo settings
# 4. Get URL: https://yourusername.github.io/rustaceaans-privacy/privacy-policy.html
```

**Option B: Vercel (FREE)**
```bash
npm install -g vercel
vercel --prod privacy-policy.html
```

---

### Step 4: Update iOS App

Change API URL from localhost to production:

```swift
// In APIService.swift
private let baseURL = "https://your-app.railway.app"  // ✅ Your Railway URL
```

---

### Step 5: Fix Bundle ID

In Xcode:
1. Click project name
2. Select Rustaceaans target
3. Change Bundle ID to: `com.yourname.rustaceaans`
4. Enable "Automatically manage signing"
5. Select your Apple Developer team

---

## 🗄️ Database Setup (Auto on Railway)

Railway automatically:
- Creates PostgreSQL database
- Sets DATABASE_URL environment variable
- Runs migrations on first deploy

Your app will auto-create tables on startup!

---

## ☁️ Storage: Local vs S3

### For Now: Use Local Storage

Railway includes file storage, so local works:

```env
STORAGE_TYPE=local
UPLOAD_DIR=./uploads
```

### Later: Upgrade to S3

When you get more users, switch to S3:

1. Create AWS account
2. Create S3 bucket: `rustaceaans-uploads`
3. Get access key & secret
4. Update Railway env vars:
   ```env
   STORAGE_TYPE=s3
   AWS_ACCESS_KEY_ID=your_key
   AWS_SECRET_ACCESS_KEY=your_secret
   S3_BUCKET=rustaceaans-uploads
   AWS_REGION=us-east-1
   ```

---

## 📝 Checklist Before App Store

- [ ] Backend deployed to Railway
- [ ] Database working (PostgreSQL)
- [ ] Privacy policy hosted (GitHub Pages)
- [ ] iOS app updated with production URL
- [ ] Bundle ID changed
- [ ] Test on production: Sign in, upload meme, send message
- [ ] All features working

---

## 🐛 Testing Production

```bash
# Test health
curl https://your-app.railway.app/

# Test API
curl https://your-app.railway.app/memes

# Check database
railway run -- cargo run
```

---

## 💡 Pro Tips

### Monitor Your App
```bash
# View logs
railway logs

# Check database
railway connect postgres
```

### Scale Up
Railway auto-scales, but you can:
- Upgrade to pro ($5/mo) for more resources
- Add Redis for caching
- Add CDN for images

### Backup Database
```bash
# Railway auto-backs up PostgreSQL
# Download backup from dashboard
```

---

## 🆘 Troubleshooting

### "Connection refused"
**Fix:** Check DATABASE_URL is set in Railway env vars

### "Table doesn't exist"
**Fix:** Migrations run on startup. Check logs for errors.

### "Upload failed"
**Fix:** Ensure STORAGE_TYPE and UPLOAD_DIR are set

### "CORS error"
**Fix:** Add your domain to CORS allowed origins in main.rs

---

## 🔄 Update Workflow

When you make changes:

```bash
# 1. Test locally
cargo run

# 2. Commit changes
git add .
git commit -m "Add feature"

# 3. Deploy to Railway
railway up

# 4. Check logs
railway logs
```

---

## 📊 Free Tier Limits

**Railway Free Tier:**
- $5 free credit/month
- ~500 hours uptime
- 1GB RAM
- 1GB storage

**Good for:**
- Testing
- MVP launch
- First 100-1000 users

**Upgrade when:**
- >1000 daily active users
- Need 24/7 uptime
- Need more storage

---

## 🎉 You're Ready!

✅ Backend: Production-ready  
✅ Database: PostgreSQL  
✅ Storage: Configured  
✅ Privacy: Policy hosted  
✅ iOS: Update URL and submit!

**Next:** Follow `ios/APP_STORE_DEPLOYMENT.md` for App Store submission!
