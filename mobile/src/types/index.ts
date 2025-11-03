// User Types
export interface User {
  // New database fields
  user_id?: number;
  username?: string;
  display_name?: string;
  profile_picture_url?: string;
  
  // Legacy fields (backwards compatibility)
  wallet_address?: string;
  email?: string;
  name?: string;
  profile_picture?: string;
  bio?: string;
  oauth_provider?: 'google' | 'apple' | 'github' | 'email' | 'demo';
  oauth_id?: string;
  created_at?: string;
  followers_count?: number;
  following_count?: number;
  posts_count?: number;
}

export interface UserProfile extends User {
  is_following?: boolean;
  followers_count: number;
  following_count: number;
  posts_count: number;
}

// Post/Meme Types
export interface Post {
  id: number;
  caption: string;
  tags: string;
  image?: string;
  video?: string;
  media_type: 'image' | 'video';
  evm_address?: string;
  likes: number;
  comment_count: number;
  created_at: string;
  user?: User;
  is_liked?: boolean;
  is_saved?: boolean;
}

// Message Types
export type MessageContentType = 'text' | 'meme' | 'image' | 'video' | 'post';

export interface MessageContent {
  type: MessageContentType;
  text?: string;
  meme_id?: number;
  media_url?: string;
  post?: Post;
}

export interface Message {
  id: number;
  sender_id: string;
  receiver_id: string;
  content: MessageContent;
  timestamp: string;
  is_read: boolean;
  sender?: User;
}

export interface Conversation {
  id: string;
  other_user_id: string;
  other_user_name?: string;
  other_user_profile_picture?: string;
  other_user?: User;
  last_message?: Message;
  unread_count: number;
  updated_at: string;
}

// Comment Types
export interface Comment {
  id: number;
  post_id: number;
  user_id: string;
  user?: User;
  text: string;
  created_at: string;
  likes: number;
  is_liked?: boolean;
}

// Follow Types
export interface Follow {
  follower_id: string;
  following_id: string;
  created_at: string;
}

// Wallet Types
export interface WalletState {
  address: string | null;
  isConnected: boolean;
  balance: string | null;
}

// API Request Types
export interface RegisterUserRequest {
  wallet_address: string;
  email?: string;
  name?: string;
  profile_picture?: string;
  bio?: string;
  oauth_provider: string;
  oauth_id: string;
}

export interface SendMessageRequest {
  sender_id: string;
  receiver_id: string;
  content: MessageContent;
}

export interface CreatePostRequest {
  caption: string;
  tags: string;
  image_url?: string;
  video_url?: string;
  media_type: 'image' | 'video';
  evm_address?: string;
}

export interface UpdateProfileRequest {
  name?: string;
  bio?: string;
  profile_picture?: string;
}

// Navigation Types
export type RootStackParamList = {
  Auth: undefined;
  Main: undefined;
  Profile: { userId: string };
  PostDetail: { postId: number };
  EditProfile: undefined;
  Chat: { userId: string; userName?: string };
  NewMessage: undefined;
  Camera: undefined;
  UploadPost: { mediaUri: string; mediaType: 'image' | 'video' };
  Followers: { userId: string };
  Following: { userId: string };
  Explore: undefined;
};

export type MainTabParamList = {
  Home: undefined;
  Explore: undefined;
  Upload: undefined;
  Messages: undefined;
  Profile: undefined;
};
