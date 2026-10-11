/**
 * Armazenamento seguro de tokens: expo-secure-store (Keychain/Keystore) no
 * nativo; em memória no web ou quando o SecureStore não está disponível.
 */
import { Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';

const memory = new Map<string, string>();
let available: boolean | null = null;

async function isAvailable(): Promise<boolean> {
  if (Platform.OS === 'web') return false;
  if (available === null) {
    try {
      available = await SecureStore.isAvailableAsync();
    } catch {
      available = false;
    }
  }
  return available;
}

export const secureStorage = {
  async get(key: string): Promise<string | null> {
    if (await isAvailable()) {
      try {
        return await SecureStore.getItemAsync(key);
      } catch {
        return memory.get(key) ?? null;
      }
    }
    return memory.get(key) ?? null;
  },
  async set(key: string, value: string): Promise<void> {
    memory.set(key, value);
    if (await isAvailable()) {
      try {
        await SecureStore.setItemAsync(key, value);
      } catch {
        // mantém em memória
      }
    }
  },
  async remove(key: string): Promise<void> {
    memory.delete(key);
    if (await isAvailable()) {
      try {
        await SecureStore.deleteItemAsync(key);
      } catch {
        // ignore
      }
    }
  },
};

export const STORAGE_KEYS = {
  accessToken: 'cp.accessToken',
  refreshToken: 'cp.refreshToken',
  deviceId: 'cp.deviceId',
} as const;
