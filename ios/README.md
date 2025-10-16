# 📱 Rust Meme API - iOS App

A native iOS app built with SwiftUI that connects to the Rust Meme API backend. Share memes, earn crypto rewards, and engage with the community.

## ✨ Features

- 🔐 **OAuth Authentication** - Sign in with Apple, Google, or GitHub
- 💰 **Web3 Wallet Integration** - Connect MetaMask via WalletConnect
- 📸 **Upload Memes** - Share images with captions and tags
- ❤️ **Like & Tip** - Send 0.001 ETH when you like a meme
- 💬 **Comments** - Engage with the community
- 🎁 **Claim Rewards** - Earn ETH from likes on your memes
- 👤 **Profile** - View your memes and pending rewards

## 🏗️ Architecture

```
ios/
├── RustMemeApp/
│   ├── RustMemeApp.swift          # App entry point
│   ├── ContentView.swift          # Root view with auth routing
│   ├── Models/
│   │   └── Meme.swift             # Data models
│   ├── Services/
│   │   └── APIService.swift       # Backend API integration
│   ├── Managers/
│   │   ├── AuthManager.swift      # OAuth authentication
│   │   └── WalletManager.swift    # Web3 wallet integration
│   └── Views/
│       ├── AuthView.swift         # Sign in screen
│       ├── FeedView.swift         # Meme feed
│       ├── MemeDetailView.swift   # Meme details & comments
│       ├── UploadView.swift       # Upload memes
│       └── ProfileView.swift      # User profile & rewards
├── Package.swift                  # Swift Package Manager dependencies
├── Info.plist                     # App configuration
└── README.md                      # This file
```

## 🚀 Getting Started

### Prerequisites

- **macOS** 13.0 or later
- **Xcode** 15.0 or later
- **iOS** 16.0+ device or simulator
- Active **Rust Meme API** backend (Railway deployment)

### Installation

1. **Open Xcode**
   ```bash
   cd ios
   open RustMemeApp.xcodeproj
   ```

2. **Update API URL**
   
   Edit `RustMemeApp/Services/APIService.swift`:
   ```swift
   private let baseURL = "https://your-rust-api.railway.app"
   ```

3. **Update Contract Address**
   
   Edit `RustMemeApp/Managers/WalletManager.swift`:
   ```swift
   private let contractAddress = "0xYourContractAddress"
   ```

4. **Install Dependencies**
   
   Xcode will automatically resolve Swift Package Manager dependencies:
   - WalletConnectSwiftV2
   - web3.swift

5. **Configure Signing**
   
   - Select your development team in Xcode
   - Update bundle identifier: `com.yourcompany.rustmeme`

6. **Run the App**
   
   - Select a simulator or device
   - Press `Cmd + R` to build and run

## 🔧 Configuration

### Sign in with Apple

1. Enable **Sign in with Apple** capability in Xcode
2. Add to your Apple Developer account
3. No additional configuration needed!

### Google Sign-In (Optional)

1. Install GoogleSignIn SDK:
   ```swift
   .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
   ```

2. Add Google OAuth credentials to `Info.plist`

3. Implement in `AuthManager.swift`

### WalletConnect Setup

1. Get a project ID from https://cloud.walletconnect.com/

2. Update `WalletManager.swift`:
   ```swift
   let projectId = "YOUR_WALLETCONNECT_PROJECT_ID"
   ```

3. Configure WalletConnect in `setupWalletConnect()`:
   ```swift
   Networking.configure(projectId: projectId, socketFactory: DefaultSocketFactory())
   ```

## 📱 Testing

### Using iOS Simulator

1. **Select iPhone 15 Pro** (or any iOS 16+ simulator)
2. **Build and Run** (`Cmd + R`)
3. **Test Features**:
   - Sign in with Apple (works in simulator)
   - Browse memes
   - View meme details
   - Upload memes (use simulator photos)

### Using Physical Device

1. **Connect iPhone** via USB
2. **Trust computer** on device
3. **Select device** in Xcode
4. **Run app** (`Cmd + R`)
5. **Test WalletConnect**:
   - Install MetaMask on device
   - Connect wallet in app
   - Like memes and send tips
   - Claim rewards

## 🎨 UI/UX Features

- **Native SwiftUI** - Modern, declarative UI
- **Dark Mode** - Automatic theme switching
- **Pull to Refresh** - Update feeds easily
- **Async Images** - Smooth image loading
- **Loading States** - Clear feedback for users
- **Error Handling** - User-friendly error messages
- **Tab Navigation** - Easy access to all features

## 🔐 Security

- ✅ **Keychain Storage** - Secure credential storage
- ✅ **HTTPS Only** - Encrypted API communication
- ✅ **WalletConnect** - Industry-standard Web3 connection
- ✅ **No Private Keys** - Wallet manages keys securely
- ✅ **OAuth 2.0** - Secure authentication flow

## 📦 Dependencies

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/WalletConnect/WalletConnectSwiftV2", from: "1.9.0"),
    .package(url: "https://github.com/argentlabs/web3.swift", from: "1.6.0"),
]
```

### System Frameworks

- SwiftUI
- Combine
- AuthenticationServices
- PhotosUI

## 🚢 Deployment

### TestFlight (Beta Testing)

1. **Archive the app** in Xcode
2. **Upload to App Store Connect**
3. **Add testers** via email
4. **Distribute** TestFlight build

### App Store Release

1. **Prepare app metadata**:
   - Screenshots (required sizes)
   - App description
   - Keywords
   - Privacy policy URL

2. **Submit for review**:
   - Explain crypto features
   - Provide test account
   - Include demo video

3. **App Store Guidelines**:
   - Comply with crypto regulations
   - Clear disclosure of fees
   - Age rating: 12+ (social media)

## 🐛 Troubleshooting

### "Failed to load memes"

- Check API URL in `APIService.swift`
- Verify backend is running
- Check network connection

### "Wallet connection failed"

- Install MetaMask on device
- Check WalletConnect project ID
- Ensure on correct network (Sepolia)

### "Upload failed"

- Check photo library permissions
- Verify wallet is connected
- Check backend upload endpoint

### Build Errors

- Clean build folder: `Cmd + Shift + K`
- Reset package cache: `File > Packages > Reset Package Caches`
- Update dependencies: `File > Packages > Update to Latest Package Versions`

## 🎯 Roadmap

- [ ] Push notifications for likes/comments
- [ ] Share memes to social media
- [ ] In-app camera for meme creation
- [ ] Trending memes algorithm
- [ ] User following system
- [ ] Direct messaging
- [ ] NFT minting for top memes
- [ ] Widget support

## 📚 Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [WalletConnect Docs](https://docs.walletconnect.com/)
- [web3.swift Guide](https://github.com/argentlabs/web3.swift)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## 🆘 Support

For issues or questions:
- Open an issue on GitHub
- Check existing documentation
- Review troubleshooting section

---

**Built with ❤️ using Swift & SwiftUI**
