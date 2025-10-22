# 🍎 Apple Sign In - Quick Fix Guide

## The Error You're Seeing

```
Authorization failed: Error Domain=AKAuthenticationError Code=-7026
ASAuthorizationController credential request failed with error: 
Error Domain=com.apple.AuthenticationServices.AuthorizationError Code=1000
```

This error (`Code=1000`) means Sign in with Apple is not properly configured or is not available in the simulator.

---

## ✅ Quick Solutions (Pick One)

### Option 1: Use Demo Mode (Fastest - For Development)

**Just click "Continue as Demo User"** - This works immediately without any configuration!

The app is already set up to work in demo mode for development. You can:
- Test all UI features
- Upload memes
- Navigate through the app
- Connect wallet (mock)

### Option 2: Fix Apple Sign In (For Real Testing)

Follow these steps **in order**:

#### Step 1: Fix Bundle Identifier
1. Open Xcode
2. Select your project target (`Rustaceaans`)
3. Go to **Signing & Capabilities** tab
4. Change Bundle Identifier from `PSI.Xcode-is-Ass` to something proper:
   ```
   com.yourname.rustaceaans
   ```
   (Use lowercase, no spaces, dots only)

#### Step 2: Enable Sign in with Apple Capability
1. In the same **Signing & Capabilities** tab
2. Click the **+ Capability** button at the top
3. Search for and add **Sign in with Apple**
4. You should see it appear in the list of capabilities

#### Step 3: Select a Team
1. In **Signing & Capabilities**
2. Under **Team**, select your Apple Developer account
3. If you don't have one, you can use a personal team (free)
4. Xcode will automatically provision the app

#### Step 4: Clean and Rebuild
1. In Xcode menu: **Product > Clean Build Folder** (⇧⌘K)
2. **Product > Build** (⌘B)
3. Run the app again

---

## 🎯 Expected Behavior After Fix

### In Simulator:
- Apple Sign In may still have issues (it's a simulator limitation)
- **Use "Continue as Demo User"** instead
- Or test on a real device

### On Real Device:
- Apple Sign In should work perfectly
- You'll see the Apple authentication modal
- After signing in, you'll be logged into the app

---

## 🔍 Why This Error Happens

1. **Bundle ID Issue**: `PSI.Xcode-is-Ass` is not a valid Apple App ID format
2. **Missing Capability**: Sign in with Apple capability not enabled
3. **Simulator Limitation**: Apple Sign In has known issues in simulator

---

## 💡 Recommended Approach

**For Development:**
```swift
✅ Use "Continue as Demo User" button
✅ All features work
✅ No Apple Developer account needed
✅ No configuration needed
```

**For Production:**
```swift
1. Fix Bundle Identifier
2. Enable Sign in with Apple capability
3. Test on real device
4. Submit to App Store
```

---

## 🚨 Still Having Issues?

### Error: "No such file or directory(2)"
- **Ignore it** - This is a simulator warning, not an error
- Doesn't affect functionality

### Error: "Passcode not supported"
- **Ignore it** - Normal simulator message
- Doesn't affect functionality

### Error: "Team not found"
1. Go to Xcode > Settings > Accounts
2. Add your Apple ID
3. Select it in Signing & Capabilities

### Apple Sign In works but shows wrong email
- Apple only provides email on **first** login
- Subsequent logins won't include email (privacy feature)
- The app handles this automatically

---

## 📱 Testing Checklist

- [ ] Changed Bundle Identifier to proper format
- [ ] Added Sign in with Apple capability
- [ ] Selected a development team
- [ ] Cleaned build folder
- [ ] Rebuilt the app
- [ ] Tested on real device (not simulator)

If all else fails: **Just use Demo mode!** 🎉

The app is fully functional with demo authentication for development purposes.
