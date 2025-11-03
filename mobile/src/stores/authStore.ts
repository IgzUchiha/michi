import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@/types';
import { apiService } from '@/services/api';

interface AuthState {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  error: string | null;
  
  // Actions
  setUser: (user: User | null) => void;
  login: (user: User, token: string) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (data: Partial<User>) => Promise<void>;
  refreshUser: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  isLoading: true,
  isAuthenticated: false,
  error: null,

  setUser: (user) => {
    set({ 
      user, 
      isAuthenticated: !!user,
      error: null 
    });
  },

  login: async (user, token) => {
    try {
      await AsyncStorage.setItem('auth_token', token);
      await AsyncStorage.setItem('user', JSON.stringify(user));
      apiService.setAuthToken(token);
      set({ 
        user, 
        isAuthenticated: true, 
        isLoading: false,
        error: null 
      });
    } catch (error) {
      console.error('Login error:', error);
      set({ error: 'Failed to save authentication' });
    }
  },

  logout: async () => {
    try {
      await AsyncStorage.removeItem('auth_token');
      await AsyncStorage.removeItem('user');
      apiService.setAuthToken(null);
      set({ 
        user: null, 
        isAuthenticated: false, 
        isLoading: false,
        error: null 
      });
    } catch (error) {
      console.error('Logout error:', error);
    }
  },

  updateProfile: async (data) => {
    const { user } = get();
    if (!user) return;

    try {
      // Merge the update data with current user
      const updatedUser = { ...user, ...data };
      await AsyncStorage.setItem('user', JSON.stringify(updatedUser));
      set({ user: updatedUser });
    } catch (error) {
      console.error('Update profile error:', error);
      set({ error: 'Failed to update profile' });
      throw error;
    }
  },

  refreshUser: async () => {
    const { user } = get();
    if (!user) return;

    try {
      // Try new auth endpoint first
      const refreshedUser = await apiService.getCurrentUser();
      await AsyncStorage.setItem('user', JSON.stringify(refreshedUser));
      set({ user: refreshedUser });
    } catch (error) {
      console.error('Refresh user error:', error);
      // If new auth fails, try legacy endpoint if wallet_address exists
      if (user.wallet_address) {
        try {
          const refreshedUser = await apiService.getUserProfile(user.wallet_address);
          await AsyncStorage.setItem('user', JSON.stringify(refreshedUser));
          set({ user: refreshedUser });
        } catch (legacyError) {
          console.error('Legacy refresh also failed:', legacyError);
        }
      }
    }
  },
}));

// Initialize auth state from storage
export const initializeAuth = async () => {
  try {
    const [token, userJson] = await Promise.all([
      AsyncStorage.getItem('auth_token'),
      AsyncStorage.getItem('user'),
    ]);

    if (token && userJson) {
      const user = JSON.parse(userJson);
      apiService.setAuthToken(token);
      useAuthStore.setState({ 
        user, 
        isAuthenticated: true, 
        isLoading: false 
      });
    } else {
      useAuthStore.setState({ isLoading: false });
    }
  } catch (error) {
    console.error('Initialize auth error:', error);
    useAuthStore.setState({ isLoading: false });
  }
};
