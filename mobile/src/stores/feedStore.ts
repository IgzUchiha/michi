import { create } from 'zustand';
import { Post } from '@/types';

interface FeedState {
  posts: Post[];
  isLoading: boolean;
  isRefreshing: boolean;
  hasMore: boolean;
  page: number;
  error: string | null;
  
  // Actions
  setPosts: (posts: Post[]) => void;
  addPosts: (posts: Post[]) => void;
  updatePost: (postId: number, updates: Partial<Post>) => void;
  removePost: (postId: number) => void;
  setLoading: (isLoading: boolean) => void;
  setRefreshing: (isRefreshing: boolean) => void;
  setError: (error: string | null) => void;
  reset: () => void;
  incrementPage: () => void;
}

export const useFeedStore = create<FeedState>((set) => ({
  posts: [],
  isLoading: false,
  isRefreshing: false,
  hasMore: true,
  page: 1,
  error: null,

  setPosts: (posts) => {
    set({ posts, page: 1, hasMore: posts.length > 0 });
  },

  addPosts: (newPosts) => {
    set((state) => ({
      posts: [...state.posts, ...newPosts],
      hasMore: newPosts.length > 0,
    }));
  },

  updatePost: (postId, updates) => {
    set((state) => ({
      posts: state.posts.map((post) =>
        post.id === postId ? { ...post, ...updates } : post
      ),
    }));
  },

  removePost: (postId) => {
    set((state) => ({
      posts: state.posts.filter((post) => post.id !== postId),
    }));
  },

  setLoading: (isLoading) => {
    set({ isLoading });
  },

  setRefreshing: (isRefreshing) => {
    set({ isRefreshing });
  },

  setError: (error) => {
    set({ error });
  },

  reset: () => {
    set({
      posts: [],
      isLoading: false,
      isRefreshing: false,
      hasMore: true,
      page: 1,
      error: null,
    });
  },

  incrementPage: () => {
    set((state) => ({ page: state.page + 1 }));
  },
}));
