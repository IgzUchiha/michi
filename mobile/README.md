# 📱 Rustaceaans Mobile - React Native App

A modern social media app built with React Native and Expo that combines Instagram/TikTok-style features with cryptocurrency integration.

## ✨ Features

### 🔐 Authentication
- **OAuth Support**: Sign in with Apple, Google, or GitHub
- **Profile Management**: Custom profiles with photos, names, and bios
- **Secure Storage**: JWT tokens stored securely with AsyncStorage

### 📸 Social Feed
- **Personalized Feed**: See posts from people you follow
- **For You Page**: Discover new content
- **Like & Comment**: Engage with posts
- **Share Posts**: Share directly to messages
- **Media Support**: Images and videos

### 💬 Messaging System
- **Real-time Messaging**: Text messages with 3-second polling
- **Media Sharing**: Share images, videos, and posts
- **Conversation List**: See all your chats with unread counts
- **Instagram-style UI**: Modern chat bubbles and design

### 👤 User Profiles
- **Profile Customization**: Upload profile pictures, add bio
- **Follow System**: Follow/unfollow users
- **Post Grid**: Instagram-style post grid
- **Stats Display**: Followers, following, posts count

### 📤 Content Upload
- **Camera Integration**: Take photos directly in-app
- **Gallery Access**: Choose from photo library
- **Video Support**: Upload video content
- **Captions & Tags**: Add descriptions and hashtags

### 💰 Crypto Integration
- **Wallet Connect**: Connect MetaMask or other wallets
- **Tip System**: Send ETH tips on posts
- **Rewards**: Earn crypto from engagement
- **Balance Display**: View your wallet balance

## 🏗️ Architecture

```
mobile/
├── App.tsx                    # Main app entry & navigation
├── src/
│   ├── components/            # Reusable UI components
│   │   ├── PostCard.tsx      # Instagram-style post card
│   │   ├── MessageBubble.tsx # Chat message bubble
│   │   ├── ConversationCard.tsx
│   │   └── WalletConnect.tsx # Wallet connection modal
│   ├── screens/              # App screens
│   │   ├── AuthScreen.tsx    # Login/signup
│   │   ├── HomeScreen.tsx    # Main feed
│   │   ├── MessagesScreen.tsx
│   │   ├── ChatScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   ├── UploadScreen.tsx
│   │   └── EditProfileScreen.tsx
│   ├── stores/               # Zustand state management
│   │   ├── authStore.ts      # Authentication state
│   │   ├── feedStore.ts      # Feed state
│   │   ├── messageStore.ts   # Messaging state
│   │   └── walletStore.ts    # Wallet state
│   ├── services/             # API services
│   │   └── api.ts            # Backend API client
│   ├── types/                # TypeScript types
│   │   └── index.ts
│   └── config/               # Configuration
│       └── constants.ts      # App constants & colors
└── package.json
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** 18+ (recommended: use `nvm`)
- **Expo CLI**: `npm install -g expo-cli`
- **iOS**: macOS with Xcode 15+ (for iOS development)
- **Android**: Android Studio with SDK 33+ (for Android development)
- **Backend**: Running Rust API server

### Installation

1. **Clone the repository**
   ```bash
   cd /Users/igmercastillo/code/RustaceaaansMichi/mobile
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your configuration:
   ```env
   EXPO_PUBLIC_API_URL=http://YOUR_IP:8000
   EXPO_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
   EXPO_PUBLIC_APPLE_CLIENT_ID=your_apple_client_id
   EXPO_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
   ```

4. **Start the Rust backend**
   ```bash
   cd ..
   cargo run
   ```

5. **Start Expo**
   ```bash
   npm start
   ```

### Running on Devices

#### iOS Simulator
```bash
npm run ios
```

#### Android Emulator
```bash
npm run android
```

#### Physical Device
1. Install **Expo Go** from App Store/Play Store
2. Scan the QR code shown in terminal
3. App will load on your device

## 📱 Testing Multi-User Messaging

To test the messaging system with multiple users:

### Option 1: Two Simulators (Recommended)
```bash
# Terminal 1 - Start backend
cargo run

# Terminal 2 - Start Expo
cd mobile && npm start

# In Expo Dev Tools:
# Press 'i' to open iOS Simulator 1
# Press 'Shift+i' to open iOS Simulator 2

# Login with different demo accounts on each simulator
```

### Option 2: Simulator + Physical Device
```bash
# Start backend and Expo
cargo run
cd mobile && npm start

# Open on simulator: Press 'i'
# Open on device: Scan QR with Expo Go
```

## 🎨 Design System

### Colors
```typescript
Primary: #7f33a5 (Purple)
Secondary: #cc4d80 (Pink)
Gradient: #7f33a5 → #cc4d80
Background: #FFFFFF
Surface: #F8F8F9
Text: #000000
Text Secondary: #666666
```

### UI Components
- **Linear Gradients**: Purple to pink gradients throughout
- **Rounded Corners**: 12px for cards, 20px for buttons
- **Shadows**: Subtle elevation for depth
- **Icons**: Ionicons from Expo vector-icons

## 🔧 Configuration

### OAuth Setup

#### Apple Sign In
1. Already configured in `AuthScreen.tsx`
2. Works automatically on iOS devices
3. Requires Apple Developer account for production

#### Google OAuth
1. Get OAuth credentials from [Google Cloud Console](https://console.cloud.google.com)
2. Add to `.env`: `EXPO_PUBLIC_GOOGLE_CLIENT_ID`
3. Configure redirect URI: `rustaceaans://oauth`

#### GitHub OAuth
1. Create OAuth app in [GitHub Settings](https://github.com/settings/developers)
2. Add to `.env`: `EXPO_PUBLIC_GITHUB_CLIENT_ID`
3. Set callback URL: `rustaceaans://oauth`

### WalletConnect Setup
1. Create project at [WalletConnect Cloud](https://cloud.walletconnect.com)
2. Get Project ID
3. Add to `.env`: `EXPO_PUBLIC_WALLETCONNECT_PROJECT_ID`

## 📦 Dependencies

### Core
- **expo**: ~51.0.0 - Framework for React Native
- **react-native**: 0.74.0 - Mobile framework
- **expo-router**: Navigation

### State Management
- **zustand**: State management
- **@tanstack/react-query**: Data fetching

### UI/UX
- **expo-linear-gradient**: Gradient components
- **expo-blur**: Blur effects
- **@expo/vector-icons**: Icon library
- **react-native-gesture-handler**: Touch interactions
- **react-native-reanimated**: Animations

### Media
- **expo-image-picker**: Camera and gallery access
- **expo-camera**: Camera access
- **expo-av**: Video playback
- **react-native-fast-image**: Optimized images

### Storage & Auth
- **@react-native-async-storage/async-storage**: Persistent storage
- **expo-secure-store**: Secure credential storage
- **expo-auth-session**: OAuth flows

### Web3
- **@walletconnect/react-native-compat**: Wallet integration
- **viem**: Ethereum interactions

## 🔒 Security

### Best Practices Implemented
- ✅ Secure token storage with AsyncStorage
- ✅ OAuth 2.0 authentication flows
- ✅ HTTPS API communication
- ✅ Input validation on all forms
- ✅ No hardcoded credentials
- ✅ Wallet signatures for transactions

### Production Checklist
- [ ] Add rate limiting on backend
- [ ] Implement refresh tokens
- [ ] Add message encryption
- [ ] Set up push notifications
- [ ] Configure app signing certificates
- [ ] Add analytics and crash reporting
- [ ] Implement biometric authentication

## 🚢 Deployment

### iOS App Store

1. **Configure app signing**
   ```bash
   expo build:ios
   ```

2. **Submit to App Store Connect**
   - Follow Apple's guidelines
   - Include privacy policy
   - Add age rating: 12+ (social media)

### Android Play Store

1. **Build APK/AAB**
   ```bash
   expo build:android
   ```

2. **Upload to Play Console**
   - Complete store listing
   - Add screenshots
   - Set content rating

### Over-The-Air (OTA) Updates
```bash
expo publish
```
Users will receive updates automatically without app store submission!

## 🐛 Troubleshooting

### "Cannot connect to backend"
- Check backend is running: `cargo run`
- Verify API URL in `.env` uses your local IP (not localhost)
- Check firewall settings

### "OAuth login not working"
- Verify OAuth credentials in `.env`
- Check redirect URIs match app scheme
- Test on physical device (some OAuth requires real device)

### "Images not uploading"
- Check camera/library permissions
- Verify storage type in backend `.env`
- Check file size limits

### Metro bundler issues
```bash
npm start -- --reset-cache
```

### iOS build fails
```bash
cd ios && pod install
```

## 📈 Performance

### Optimization Techniques
- **Image optimization**: FastImage for caching
- **Lazy loading**: Feed pagination
- **Memo components**: Prevent unnecessary re-renders
- **Polling optimization**: Only poll active screens
- **Virtualized lists**: FlatList for long feeds

### Monitoring
- Use React Native Debugger
- Enable Performance Monitor: Shake device → "Show Perf Monitor"
- Profile with Chrome DevTools

## 🛣️ Roadmap

### Phase 1 (Current)
- ✅ OAuth authentication
- ✅ Feed system
- ✅ Messaging
- ✅ Profile management
- ✅ Media upload
- ✅ Basic wallet integration

### Phase 2 (Next)
- [ ] WebSocket for real-time messages
- [ ] Push notifications
- [ ] Video player with controls
- [ ] Story/Reels feature
- [ ] Advanced search & discovery
- [ ] Direct message groups

### Phase 3 (Future)
- [ ] Live streaming
- [ ] NFT integration
- [ ] Token rewards system
- [ ] In-app wallet
- [ ] AR filters
- [ ] Advanced analytics

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test on both iOS and Android
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## 🆘 Support

For issues or questions:
- Check documentation in `ios/` and `contracts/` folders
- Review backend API docs
- Open GitHub issue

---

**Built with ❤️ using React Native & Expo**

**Instagram + TikTok + Crypto = Rustaceaans** 🚀
