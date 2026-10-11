/**
 * Registro do token de push (Expo Push) no BFF. Nunca lança: em Expo Go,
 * web, simulador ou sem permissão simplesmente não registra.
 */
import { Platform } from 'react-native';
import Constants, { ExecutionEnvironment } from 'expo-constants';
import * as Device from 'expo-device';
import { deviceApi } from '@/api/endpoints';
import { EAS_PROJECT_ID } from './env';
import { getDeviceName } from './deviceName';
import { secureStorage, STORAGE_KEYS } from './secureStorage';

let registering: Promise<void> | null = null;

function canUsePush(): boolean {
  if (Platform.OS !== 'ios' && Platform.OS !== 'android') return false;
  if (!Device.isDevice) return false;
  // Expo Go não suporta push remoto desde o SDK 53.
  if (Constants.executionEnvironment === ExecutionEnvironment.StoreClient) return false;
  return true;
}

export function configureNotificationHandler(): void {
  if (!canUsePush()) return;
  // import dinâmico: evita avisos no web/Expo Go, onde push remoto não existe.
  import('expo-notifications')
    .then((Notifications) => {
      Notifications.setNotificationHandler({
        handleNotification: async () => ({
          shouldShowBanner: true,
          shouldShowList: true,
          shouldPlaySound: false,
          shouldSetBadge: false,
        }),
      });
    })
    .catch(() => undefined);
}

export function registerPushToken(): Promise<void> {
  if (registering) return registering;
  registering = (async () => {
    if (!canUsePush()) return;
    try {
      const Notifications = await import('expo-notifications');
      if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync('default', {
          name: 'Padrão',
          importance: Notifications.AndroidImportance.MAX,
          lightColor: '#E0A24A',
        });
      }
      let { status } = await Notifications.getPermissionsAsync();
      if (status !== 'granted') {
        ({ status } = await Notifications.requestPermissionsAsync());
      }
      if (status !== 'granted') return;

      const projectId =
        EAS_PROJECT_ID ?? Constants.expoConfig?.extra?.eas?.projectId ?? Constants.easConfig?.projectId;
      if (!projectId) return;

      const { data: expoPushToken } = await Notifications.getExpoPushTokenAsync({ projectId });
      const { id } = await deviceApi.register({
        expoPushToken,
        platform: Platform.OS === 'ios' ? 'ios' : 'android',
        appVersion: Constants.expoConfig?.version ?? '0.0.0',
        deviceName: getDeviceName(),
      });
      await secureStorage.set(STORAGE_KEYS.deviceId, id);
    } catch (e) {
      if (__DEV__) console.warn('[push] registro ignorado:', e);
    } finally {
      registering = null;
    }
  })();
  return registering;
}

export async function unregisterPushToken(): Promise<void> {
  const id = await secureStorage.get(STORAGE_KEYS.deviceId);
  if (!id) return;
  try {
    await deviceApi.remove(id);
  } finally {
    await secureStorage.remove(STORAGE_KEYS.deviceId);
  }
}
