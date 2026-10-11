import { create } from 'zustand';
import type { AuthTokens, UserProfile } from '@/api/contracts';
import { secureStorage, STORAGE_KEYS } from '@/lib/secureStorage';

export type SessionStatus = 'booting' | 'signedOut' | 'signedIn';

interface AuthState {
  status: SessionStatus;
  accessToken: string | null;
  refreshToken: string | null;
  user: UserProfile | null;
  /** Hidrata tokens do armazenamento seguro. Não valida a sessão. */
  hydrate: () => Promise<{ accessToken: string | null; refreshToken: string | null }>;
  setTokens: (tokens: AuthTokens) => Promise<void>;
  signIn: (tokens: AuthTokens, user: UserProfile) => Promise<void>;
  setUser: (user: UserProfile) => void;
  markSignedOut: () => void;
  clear: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  status: 'booting',
  accessToken: null,
  refreshToken: null,
  user: null,

  hydrate: async () => {
    const [accessToken, refreshToken] = await Promise.all([
      secureStorage.get(STORAGE_KEYS.accessToken),
      secureStorage.get(STORAGE_KEYS.refreshToken),
    ]);
    set({ accessToken, refreshToken });
    return { accessToken, refreshToken };
  },

  setTokens: async (tokens) => {
    set({ accessToken: tokens.accessToken, refreshToken: tokens.refreshToken });
    await Promise.all([
      secureStorage.set(STORAGE_KEYS.accessToken, tokens.accessToken),
      secureStorage.set(STORAGE_KEYS.refreshToken, tokens.refreshToken),
    ]);
  },

  signIn: async (tokens, user) => {
    set({ accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user, status: 'signedIn' });
    await Promise.all([
      secureStorage.set(STORAGE_KEYS.accessToken, tokens.accessToken),
      secureStorage.set(STORAGE_KEYS.refreshToken, tokens.refreshToken),
    ]);
  },

  setUser: (user) => set({ user, status: 'signedIn' }),

  markSignedOut: () => set({ status: 'signedOut' }),

  clear: async () => {
    set({ accessToken: null, refreshToken: null, user: null, status: 'signedOut' });
    await Promise.all([
      secureStorage.remove(STORAGE_KEYS.accessToken),
      secureStorage.remove(STORAGE_KEYS.refreshToken),
    ]);
  },
}));
