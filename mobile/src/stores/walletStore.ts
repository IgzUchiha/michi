import { create } from 'zustand';
import { WalletState } from '@/types';

interface WalletStore extends WalletState {
  isConnecting: boolean;
  error: string | null;
  
  // Actions
  connect: (address: string) => void;
  disconnect: () => void;
  updateBalance: (balance: string) => void;
  setError: (error: string | null) => void;
}

export const useWalletStore = create<WalletStore>((set) => ({
  address: null,
  isConnected: false,
  balance: null,
  isConnecting: false,
  error: null,

  connect: (address) => {
    set({
      address,
      isConnected: true,
      isConnecting: false,
      error: null,
    });
  },

  disconnect: () => {
    set({
      address: null,
      isConnected: false,
      balance: null,
      error: null,
    });
  },

  updateBalance: (balance) => {
    set({ balance });
  },

  setError: (error) => {
    set({ error, isConnecting: false });
  },
}));
