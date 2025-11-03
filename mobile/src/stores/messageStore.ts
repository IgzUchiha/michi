import { create } from 'zustand';
import { Message, Conversation } from '@/types';

interface MessageState {
  conversations: Conversation[];
  currentMessages: Message[];
  isLoading: boolean;
  error: string | null;
  
  // Actions
  setConversations: (conversations: Conversation[]) => void;
  addConversation: (conversation: Conversation) => void;
  updateConversation: (conversationId: string, updates: Partial<Conversation>) => void;
  setCurrentMessages: (messages: Message[]) => void;
  addMessage: (message: Message) => void;
  markAsRead: (conversationId: string) => void;
  setLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  reset: () => void;
}

export const useMessageStore = create<MessageState>((set) => ({
  conversations: [],
  currentMessages: [],
  isLoading: false,
  error: null,

  setConversations: (conversations) => {
    set({ conversations });
  },

  addConversation: (conversation) => {
    set((state) => ({
      conversations: [conversation, ...state.conversations],
    }));
  },

  updateConversation: (conversationId, updates) => {
    set((state) => ({
      conversations: state.conversations.map((conv) =>
        conv.id === conversationId ? { ...conv, ...updates } : conv
      ),
    }));
  },

  setCurrentMessages: (messages) => {
    set({ currentMessages: messages });
  },

  addMessage: (message) => {
    set((state) => ({
      currentMessages: [...state.currentMessages, message],
    }));
  },

  markAsRead: (conversationId) => {
    set((state) => ({
      conversations: state.conversations.map((conv) =>
        conv.id === conversationId ? { ...conv, unread_count: 0 } : conv
      ),
    }));
  },

  setLoading: (isLoading) => {
    set({ isLoading });
  },

  setError: (error) => {
    set({ error });
  },

  reset: () => {
    set({
      conversations: [],
      currentMessages: [],
      isLoading: false,
      error: null,
    });
  },
}));
