# 🚀 Quick Start Guide - React Native App

Get your Rustaceaans mobile app running in 5 minutes!

## Prerequisites Check

Before starting, ensure you have:
- ✅ Node.js 18+ installed (`node --version`)
- ✅ npm or yarn
- ✅ iOS: Xcode 15+ (Mac only)
- ✅ Android: Android Studio with SDK 33+
- ✅ Expo CLI (`npm install -g expo-cli`)

## Step 1: Start the Backend (Required!)

The Rust backend MUST be running before the app works.

```bash
# In the root directory
cd /Users/igmercastillo/code/RustaceaaansMichi
cargo run
```

✅ You should see: `🚀 Server starting on 0.0.0.0:8000`

## Step 2: Install Dependencies

```bash
cd mobile
npm install
```

## Step 3: Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env with your local IP (NOT localhost!)
# Find your IP: Mac -> System Preferences -> Network
```

Example `.env`:
```env
EXPO_PUBLIC_API_URL=http://192.168.1.100:8000
```

## Step 4: Start Expo

```bash
npm start
```

## Step 5: Run on Device

### Option A: iOS Simulator (Mac only)
```bash
# Press 'i' in terminal
# OR
npm run ios
```

### Option B: Android Emulator
```bash
# Press 'a' in terminal
# OR
npm run android
```

### Option C: Physical Device (Easiest!)
1. Install **Expo Go** from App Store/Play Store
2. Scan QR code from terminal
3. App loads instantly!

## Step 6: Test the App

1. **Sign In**: Use "Demo Account" button
2. **Browse Feed**: Scroll through sample posts
3. **Upload**: Tap + button, choose photo, add caption
4. **Message**: Tap Messages tab, create conversation
5. **Profile**: View your profile and edit it

## Common Issues & Fixes

### "Cannot connect to server"
```bash
# Issue: Using localhost instead of IP
# Fix: Update .env with your computer's local IP address
# Find IP: ipconfig getifaddr en0 (Mac) or ifconfig (Linux)
```

### "No posts showing"
```bash
# Issue: Backend not running
# Fix: Start backend with cargo run
```

### Metro bundler issues
```bash
npm start -- --reset-cache
```

### Expo Go not connecting
```bash
# Make sure phone and computer on same WiFi
# Disable firewall temporarily
# Try tunnel mode: npm start --tunnel
```

## Testing Multiple Users

To test messaging between users:

```bash
# Terminal 1: Backend
cargo run

# Terminal 2: Expo
cd mobile && npm start

# Open on 2 devices/simulators:
# Device 1: Login with demo account
# Device 2: Login with different demo account
# Send messages between them!
```

## Next Steps

- 📖 Read full [README.md](./README.md)
- 🔧 Configure OAuth providers
- 💰 Set up WalletConnect
- 🚀 Deploy to production

## Quick Commands Reference

```bash
# Start backend
cargo run

# Start Expo
npm start

# iOS
npm run ios

# Android
npm run android

# Clear cache
npm start -- --reset-cache

# Type check
npm run type-check

# Lint
npm run lint
```

## Getting Help

- Check terminal for error messages
- Review [README.md](./README.md) for detailed docs
- Check backend logs for API errors
- Ensure all dependencies installed correctly

---

**Ready to build?** 🚀 Your app should now be running!

**Issues?** Make sure:
1. ✅ Backend is running
2. ✅ Using correct IP address (not localhost)
3. ✅ Phone and computer on same network
4. ✅ All dependencies installed (`npm install`)
