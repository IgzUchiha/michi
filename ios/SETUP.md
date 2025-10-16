# 🚀 iOS App Setup Guide

Complete step-by-step guide to set up and run the Rust Meme iOS app.

## 📋 Prerequisites Checklist

- [ ] Mac with macOS 13.0+
- [ ] Xcode 15.0+ installed
- [ ] Apple Developer account (free or paid)
- [ ] iOS device or simulator (iOS 16+)
- [ ] Backend API running (Railway)
- [ ] Smart contract deployed (Sepolia)

## 🛠️ Step 1: Install Xcode

1. **Download Xcode** from Mac App Store
2. **Install Command Line Tools**:
   ```bash
   xcode-select --install
   ```
3. **Open Xcode** and accept license agreement

## 📁 Step 2: Create Xcode Project

Since we've created the Swift files, you need to create an Xcode project:

1. **Open Xcode**
2. **Create New Project**:
   - File → New → Project
   - Choose **iOS** → **App**
   - Click **Next**

3. **Configure Project**:
   - Product Name: `RustMemeApp`
   - Team: Select your team
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Click **Next**

4. **Save Project**:
   - Choose `/Users/igmercastillo/Rust_meme_api/ios/`
   - Click **Create**

## 📦 Step 3: Add Swift Files

1. **Delete default files**:
   - Delete `ContentView.swift` (we have our own)
   - Keep `RustMemeAppApp.swift` (rename to match our `RustMemeApp.swift`)

2. **Add our files to project**:
   - Drag all `.swift` files from Finder into Xcode
   - Check "Copy items if needed"
   - Add to target: RustMemeApp

3. **Organize in groups**:
   ```
   RustMemeApp/
   ├── RustMemeApp.swift
   ├── ContentView.swift
   ├── Models/
   ├── Services/
   ├── Managers/
   └── Views/
   ```

## 🔗 Step 4: Add Dependencies

### Using Swift Package Manager

1. **Open Package Dependencies**:
   - File → Add Package Dependencies...

2. **Add WalletConnect**:
   - URL: `https://github.com/WalletConnect/WalletConnectSwiftV2`
   - Version: 1.9.0 or later
   - Click **Add Package**

3. **Add web3.swift**:
   - URL: `https://github.com/argentlabs/web3.swift`
   - Version: 1.6.0 or later
   - Click **Add Package**

4. **Wait for resolution** (may take a few minutes)

## ⚙️ Step 5: Configure App

### Update API URL

Edit `Services/APIService.swift`:
```swift
private let baseURL = "https://rust-meme-api-production.up.railway.app"
```

### Update Contract Address

Edit `Managers/WalletManager.swift`:
```swift
private let contractAddress = "0xd1C2AceaA918b2E9eBE3e60Ad7B35618e7330486"
```

### Configure Info.plist

1. **Add permissions**:
   - Right-click `Info.plist` → Open As → Source Code
   - Copy contents from our `Info.plist` file

2. **Key permissions needed**:
   - `NSPhotoLibraryUsageDescription`
   - `NSCameraUsageDescription`
   - `CFBundleURLTypes` (for deep linking)

## 🔐 Step 6: Enable Capabilities

1. **Select project** in Xcode
2. **Select target** → RustMemeApp
3. **Signing & Capabilities** tab
4. **Add Capability**:
   - Click **+ Capability**
   - Add **Sign in with Apple**

## 🎨 Step 7: Configure Assets

1. **App Icon**:
   - Create 1024x1024 icon
   - Drag to `Assets.xcassets/AppIcon`

2. **Launch Screen**:
   - Customize in `LaunchScreen.storyboard`
   - Or use default

## 🔧 Step 8: Configure WalletConnect

1. **Get Project ID**:
   - Go to https://cloud.walletconnect.com/
   - Create account
   - Create new project
   - Copy Project ID

2. **Update WalletManager**:
   ```swift
   private func setupWalletConnect() {
       let projectId = "YOUR_PROJECT_ID_HERE"
       
       Networking.configure(
           projectId: projectId,
           socketFactory: DefaultSocketFactory()
       )
       
       let metadata = AppMetadata(
           name: "Rust Meme",
           description: "Share memes, earn crypto",
           url: "https://rustmeme.app",
           icons: ["https://rustmeme.app/icon.png"]
       )
       
       Pair.configure(metadata: metadata)
   }
   ```

## ▶️ Step 9: Build and Run

### On Simulator

1. **Select simulator**:
   - iPhone 15 Pro (or any iOS 16+)

2. **Build and run**:
   - Press `Cmd + R`
   - Or click ▶️ button

3. **Test features**:
   - Sign in with Apple works!
   - Browse memes
   - View details
   - Upload (use simulator photos)

### On Physical Device

1. **Connect iPhone** via USB

2. **Trust computer** on device

3. **Select device** in Xcode

4. **Fix signing** if needed:
   - Signing & Capabilities
   - Select your team
   - Xcode will auto-fix provisioning

5. **Run app** (`Cmd + R`)

6. **Trust developer** on device:
   - Settings → General → VPN & Device Management
   - Trust your developer certificate

## 🧪 Step 10: Test Complete Flow

### Test Authentication

1. **Launch app**
2. **Tap "Sign in with Apple"**
3. **Authenticate** with Face ID/Touch ID
4. **Verify** you're signed in

### Test Wallet Connection

1. **Install MetaMask** on device
2. **In app**, tap "Connect Wallet"
3. **Select MetaMask**
4. **Approve connection**
5. **Verify** address shows in app

### Test Upload

1. **Go to Upload tab**
2. **Select photo** from library
3. **Add caption** and tags
4. **Tap Upload**
5. **Verify** meme appears in feed

### Test Like & Tip

1. **Browse feed**
2. **Tap heart** on a meme
3. **MetaMask opens** for transaction
4. **Approve** 0.001 ETH + gas
5. **Wait** for confirmation
6. **Verify** like count increases

### Test Rewards

1. **Go to Profile tab**
2. **View pending rewards**
3. **Tap "Claim Rewards"**
4. **Approve** transaction
5. **Verify** ETH received in wallet

## 🐛 Common Issues

### Build Fails

**Error**: "No such module 'WalletConnectSwiftV2'"

**Fix**:
- File → Packages → Reset Package Caches
- File → Packages → Update to Latest Package Versions
- Clean build: `Cmd + Shift + K`

### Signing Error

**Error**: "Failed to register bundle identifier"

**Fix**:
- Change bundle ID to unique name
- Use your team's prefix
- Example: `com.yourname.rustmeme`

### Simulator Issues

**Error**: App crashes on launch

**Fix**:
- Reset simulator: Device → Erase All Content and Settings
- Restart Xcode
- Clean build folder

### WalletConnect Not Working

**Error**: "Connection failed"

**Fix**:
- Check project ID is correct
- Ensure MetaMask is installed
- Try on physical device (not simulator)

## 📱 TestFlight Distribution

### Prepare for TestFlight

1. **Archive app**:
   - Product → Archive
   - Wait for build to complete

2. **Upload to App Store Connect**:
   - Window → Organizer
   - Select archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Upload

3. **Add testers**:
   - Go to App Store Connect
   - TestFlight section
   - Add internal/external testers
   - Send invites

4. **Test beta**:
   - Testers receive email
   - Install TestFlight app
   - Download your app
   - Provide feedback

## 🎯 Next Steps

- [ ] Test all features thoroughly
- [ ] Fix any bugs found
- [ ] Optimize performance
- [ ] Add analytics (optional)
- [ ] Prepare App Store screenshots
- [ ] Write app description
- [ ] Submit for review

## 📚 Additional Resources

- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [WalletConnect iOS Guide](https://docs.walletconnect.com/2.0/swift/guides/installation)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)

## 🆘 Need Help?

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review Xcode console for errors
3. Check package dependencies are resolved
4. Verify API and contract addresses
5. Open an issue on GitHub with details

---

**Good luck with your iOS app! 🚀**
