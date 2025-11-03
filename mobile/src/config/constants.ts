import Constants from 'expo-constants';

// API Configuration
export const API_URL = Constants.expoConfig?.extra?.apiUrl || process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:8000';

// OAuth Configuration
export const OAUTH_CONFIG = {
  google: {
    clientId: process.env.EXPO_PUBLIC_GOOGLE_CLIENT_ID || '',
    redirectUri: 'rustaceaans://oauth',
  },
  apple: {
    clientId: process.env.EXPO_PUBLIC_APPLE_CLIENT_ID || '',
    redirectUri: 'rustaceaans://oauth',
  },
  github: {
    clientId: process.env.EXPO_PUBLIC_GITHUB_CLIENT_ID || '',
    redirectUri: 'rustaceaans://oauth',
  },
};

// WalletConnect Configuration
export const WALLETCONNECT_PROJECT_ID = process.env.EXPO_PUBLIC_WALLETCONNECT_PROJECT_ID || '';

// Ethereum Configuration
export const CHAIN_ID = parseInt(process.env.EXPO_PUBLIC_CHAIN_ID || '11155111');
export const RPC_URL = process.env.EXPO_PUBLIC_RPC_URL || '';
export const CONTRACT_ADDRESS = process.env.EXPO_PUBLIC_CONTRACT_ADDRESS || '';

// App Configuration
export const APP_NAME = 'Rustaceaans';
export const APP_VERSION = '1.0.0';

// Colors
export const COLORS = {
  primary: '#7f33a5',
  secondary: '#cc4d80',
  background: '#FFFFFF',
  surface: '#F8F8F9',
  text: '#000000',
  textSecondary: '#666666',
  border: '#E0E0E0',
  error: '#FF3B30',
  success: '#34C759',
  warning: '#FF9500',
  gradient: {
    start: '#7f33a5',
    end: '#cc4d80',
  },
};

// Polling intervals
export const POLLING_INTERVALS = {
  messages: 3000, // 3 seconds
  feed: 30000, // 30 seconds
  notifications: 10000, // 10 seconds
};

// Media constraints
export const MEDIA_CONSTRAINTS = {
  maxImageSize: 10 * 1024 * 1024, // 10MB
  maxVideoSize: 100 * 1024 * 1024, // 100MB
  maxVideoDuration: 60, // 60 seconds
  imageQuality: 0.8,
  videoQuality: 'high',
};
