# Web3Auth SDK Integration & Apple Sign In Fix

This guide will help you integrate Web3Auth Embedded Wallets SDK and fix the Apple Sign In issue.

## 🔴 Critical: Fix Apple Sign In First

The error you're seeing (`AuthorizationError Code=1000`) happens because Sign in with Apple isn't properly configured. Here's how to fix it:

### Step 1: Enable Sign in with Apple Capability

1. Open your Xcode project (`Rustaceaans.xcodeproj`)
2. Select your app target in the left sidebar
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Add **Sign in with Apple**
6. Make sure you're signed in with your Apple Developer account

### Step 2: Fix Bundle Identifier Issues

The error shows `AKClientBundleID=PSI.Xcode-is-Ass` which is problematic:

1. In **Signing & Capabilities**, set a proper Bundle Identifier:
   - Example: `com.yourname.rustaceaans` or `com.rustaceaans.app`
2. **IMPORTANT**: This must match your Apple Developer Portal app identifier
3. Update the `redirectUrl` in `WalletManager.swift` to match your bundle ID

### Step 3: Configure Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers**
4. Find your app's identifier (or create one)
5. Enable **Sign in with Apple** capability
6. Save changes

### Step 4: Testing Sign in with Apple

**IMPORTANT**: Sign in with Apple has limitations in the simulator:
- First time setup may fail in simulator
- You may need to test on a real device
- Or use the "Continue as Demo User" button for development

---

## 🚀 Web3Auth SDK Integration

### Step 1: Add Web3Auth via Swift Package Manager

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter the repository URL:
   ```
   https://github.com/Web3Auth/web3auth-swift-sdk
   ```
3. Select **Exact Version**: `11.1.0`
4. Click **Add Package**
5. Wait for Xcode to download and integrate the package

### Step 2: Get Your Web3Auth Client ID

1. Go to [Web3Auth Dashboard](https://dashboard.web3auth.io)
2. Create a new project or select existing one
3. Copy your **Client ID**
4. In the dashboard, configure:
   - **Whitelist URLs**: Add your bundle ID redirect URL
     - Format: `com.yourname.rustaceaans://auth`
   - **Network**: Select Sapphire Mainnet or Devnet
   - **Social Logins**: Enable providers you want (Google, Apple, etc.)

### Step 3: Update WalletManager.swift

1. Open `WalletManager.swift`
2. Uncomment line 4:
   ```swift
   import Web3Auth
   ```
3. Replace `YOUR_WEB3AUTH_CLIENT_ID` on line 19 with your actual Client ID
4. Update `redirectUrl` on line 20 to match your bundle ID:
   ```swift
   private let redirectUrl = "com.yourname.rustaceaans://auth"
   ```
5. Uncomment the Web3Auth initialization (lines 24-30):
   ```swift
   web3Auth = Web3Auth(W3AInitParams(
       clientId: web3AuthClientId,
       network: .sapphire_mainnet, // Use .sapphire_devnet for testing
       redirectUrl: redirectUrl
   ))
   ```
6. Uncomment the Web3Auth login logic (lines 46-68)
7. Uncomment the logout logic (lines 85-100)

### Step 4: Configure URL Scheme in Xcode

1. Select your app target
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add a new URL Type
5. Set:
   - **Identifier**: `com.web3auth`
   - **URL Schemes**: Your bundle ID (e.g., `com.yourname.rustaceaans`)
   - **Role**: Editor

### Step 5: Update Info.plist

Add these entries to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.web3auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourname.rustaceaans</string>
        </array>
    </dict>
</array>

<!-- For iOS 14+ privacy -->
<key>NSUserTrackingUsageDescription</key>
<string>This app uses Web3Auth for secure wallet authentication</string>
```

### Step 6: Test Web3Auth Integration

1. Build and run the app
2. Click "Connect Wallet" in the Profile tab
3. You should see Web3Auth's login modal
4. Choose a login provider (Google, Apple, etc.)
5. After successful login, you'll get a wallet address

---

## 📱 Choose Your Login Providers

Web3Auth supports multiple login methods. Update line 50 in `WalletManager.swift`:

```swift
// Google Login
loginProvider: .GOOGLE

// Apple Login
loginProvider: .APPLE

// Facebook
loginProvider: .FACEBOOK

// Twitter
loginProvider: .TWITTER

// Email Passwordless
loginProvider: .EMAIL_PASSWORDLESS

// For custom provider
loginProvider: .JWT
```

---

## 🔧 Advanced Configuration

### Use Different Networks

```swift
// For development/testing
network: .sapphire_devnet

// For production
network: .sapphire_mainnet

// For custom network
network: .cyan
```

### Customize Login UI

```swift
let result = try await web3Auth?.login(
    W3ALoginParams(
        loginProvider: .GOOGLE,
        extraLoginOptions: [
            "display": "popup", // or "page"
            "prompt": "select_account",
            "theme": "dark" // or "light"
        ]
    )
)
```

### Session Management

Web3Auth handles session persistence automatically. Users will stay logged in across app restarts until they explicitly logout.

---

## 🐛 Troubleshooting

### "Module 'Web3Auth' not found"
- Make sure you've added the package via SPM
- Clean build folder: **Product > Clean Build Folder**
- Restart Xcode

### "Redirect URL not whitelisted"
- Check Web3Auth Dashboard settings
- Ensure the redirect URL exactly matches your bundle ID + `://auth`
- No typos in the URL scheme configuration

### Apple Sign In Still Failing
- Test on a real device instead of simulator
- Verify Sign in with Apple capability is enabled in both:
  - Xcode project
  - Apple Developer Portal
- Check that your Apple ID is signed in on the device
- Use the "Continue as Demo User" button for development

### Web3Auth Login Timeout
- Check your internet connection
- Verify Client ID is correct
- Try `.sapphire_devnet` instead of mainnet for testing

---

## 📚 Additional Resources

- [Web3Auth iOS Documentation](https://web3auth.io/docs/sdk/pnp/ios)
- [Web3Auth Dashboard](https://dashboard.web3auth.io)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Web3.swift for Blockchain Interactions](https://github.com/argentlabs/web3.swift)

---

## 🎯 Next Steps

After Web3Auth is integrated:

1. **Add Web3.swift** for actual blockchain transactions
2. **Implement smart contract interactions** in `sendTip()` and `claimRewards()`
3. **Add proper error handling** for network issues
4. **Implement transaction signing** using the private key from Web3Auth
5. **Add transaction history** tracking

---

## 💡 Development vs Production

**Current State**: Mock wallet for development
**With Web3Auth**: Real wallet with social login
**Production Ready**: Web3Auth + Smart contract integration + Transaction handling

The mock implementation will work fine for UI development. Integrate Web3Auth when you're ready to test with real wallets!
