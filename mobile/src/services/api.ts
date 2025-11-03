import axios, { AxiosInstance } from 'axios';
import { API_URL } from '@/config/constants';
import {
  User,
  Post,
  Message,
  Conversation,
  Comment,
  RegisterUserRequest,
  SendMessageRequest,
  CreatePostRequest,
  UpdateProfileRequest,
  MessageContent,
} from '@/types';

class APIService {
  private client: AxiosInstance;
  private authToken: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add interceptor for auth token
    this.client.interceptors.request.use((config) => {
      if (this.authToken) {
        config.headers.Authorization = `Bearer ${this.authToken}`;
      }
      return config;
    });
  }

  setAuthToken(token: string | null) {
    this.authToken = token;
  }

  // ==================== New Auth APIs (Database) ====================
  async register(data: {
    username: string;
    email: string;
    password: string;
    display_name?: string;
    wallet_address?: string;
  }): Promise<{ user: User; token: string; expires_at: string }> {
    const response = await this.client.post('/auth/register', data);
    if (response.data.token) {
      this.setAuthToken(response.data.token);
    }
    return response.data;
  }

  async login(email: string, password: string): Promise<{ user: User; token: string; expires_at: string }> {
    const response = await this.client.post('/auth/login', { email, password });
    if (response.data.token) {
      this.setAuthToken(response.data.token);
    }
    return response.data;
  }

  async logout(): Promise<void> {
    await this.client.post('/auth/logout');
    this.setAuthToken(null);
  }

  async getCurrentUser(): Promise<User> {
    const response = await this.client.get('/auth/me');
    return response.data;
  }

  async updateAuthProfile(data: {
    display_name?: string;
    bio?: string;
    profile_picture_url?: string;
  }): Promise<User> {
    const response = await this.client.put('/auth/profile', data);
    return response.data;
  }

  // ==================== Legacy Auth APIs ====================
  async registerUser(data: RegisterUserRequest): Promise<User> {
    const response = await this.client.post<User>('/users/register', data);
    return response.data;
  }

  async getUserProfile(userId: string): Promise<User> {
    const response = await this.client.get<User>(`/users/${userId}`);
    return response.data;
  }

  async updateProfile(userId: string, data: UpdateProfileRequest): Promise<User> {
    const response = await this.client.put<User>(`/users/${userId}`, data);
    return response.data;
  }

  async searchUsers(query: string): Promise<User[]> {
    const response = await this.client.get<User[]>('/users/search', {
      params: { q: query },
    });
    return response.data;
  }

  // ==================== Post/Feed APIs ====================
  async getPosts(page: number = 1, limit: number = 20): Promise<Post[]> {
    const response = await this.client.get<Post[]>('/memes', {
      params: { page, limit },
    });
    return response.data;
  }

  async getPost(postId: number): Promise<Post> {
    const response = await this.client.get<Post>(`/memes/${postId}`);
    return response.data;
  }

  async getUserPosts(userId: string): Promise<Post[]> {
    const response = await this.client.get<Post[]>(`/users/${userId}/posts`);
    return response.data;
  }

  async getFollowingFeed(userId: string): Promise<Post[]> {
    const response = await this.client.get<Post[]>(`/feed/${userId}`);
    return response.data;
  }

  async likePost(postId: number): Promise<Post> {
    const response = await this.client.post<Post>(`/memes/${postId}/like`);
    return response.data;
  }

  async unlikePost(postId: number): Promise<Post> {
    const response = await this.client.delete<Post>(`/memes/${postId}/like`);
    return response.data;
  }

  async createPost(formData: FormData): Promise<Post> {
    const response = await this.client.post<Post>('/memes/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  }

  async deletePost(postId: number): Promise<void> {
    await this.client.delete(`/memes/${postId}`);
  }

  // ==================== Comment APIs ====================
  async getComments(postId: number): Promise<Comment[]> {
    const response = await this.client.get<Comment[]>(`/memes/${postId}/comments`);
    return response.data;
  }

  async addComment(postId: number, text: string, userId: string): Promise<Comment> {
    const response = await this.client.post<Comment>(`/memes/${postId}/comments`, {
      text,
      user_id: userId,
    });
    return response.data;
  }

  async deleteComment(postId: number, commentId: number): Promise<void> {
    await this.client.delete(`/memes/${postId}/comments/${commentId}`);
  }

  // ==================== Messaging APIs ====================
  async sendMessage(data: SendMessageRequest): Promise<Message> {
    const response = await this.client.post<Message>('/messages/send', data);
    return response.data;
  }

  async getConversations(userId: string): Promise<Conversation[]> {
    const response = await this.client.get<Conversation[]>(`/messages/conversations/${userId}`);
    return response.data;
  }

  async getMessages(userId: string, otherUserId: string): Promise<Message[]> {
    const response = await this.client.get<Message[]>(`/messages/${userId}/${otherUserId}`);
    return response.data;
  }

  async markMessagesAsRead(userId: string, otherUserId: string): Promise<void> {
    await this.client.put(`/messages/read/${userId}/${otherUserId}`);
  }

  // ==================== Follow APIs ====================
  async followUser(followerId: string, followingId: string): Promise<void> {
    await this.client.post('/follow', {
      follower_id: followerId,
      following_id: followingId,
    });
  }

  async unfollowUser(followerId: string, followingId: string): Promise<void> {
    await this.client.delete('/follow', {
      data: {
        follower_id: followerId,
        following_id: followingId,
      },
    });
  }

  async getFollowers(userId: string): Promise<User[]> {
    const response = await this.client.get<User[]>(`/users/${userId}/followers`);
    return response.data;
  }

  async getFollowing(userId: string): Promise<User[]> {
    const response = await this.client.get<User[]>(`/users/${userId}/following`);
    return response.data;
  }

  async isFollowing(followerId: string, followingId: string): Promise<boolean> {
    const response = await this.client.get<{ is_following: boolean }>(
      `/follow/check/${followerId}/${followingId}`
    );
    return response.data.is_following;
  }

  // ==================== Upload APIs ====================
  async uploadImage(uri: string, fileName: string): Promise<string> {
    const formData = new FormData();
    formData.append('file', {
      uri,
      name: fileName,
      type: 'image/jpeg',
    } as any);

    const response = await this.client.post<{ url: string }>('/upload/image', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data.url;
  }

  async uploadVideo(uri: string, fileName: string): Promise<string> {
    const formData = new FormData();
    formData.append('file', {
      uri,
      name: fileName,
      type: 'video/mp4',
    } as any);

    const response = await this.client.post<{ url: string }>('/upload/video', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data.url;
  }
}

export const apiService = new APIService();
