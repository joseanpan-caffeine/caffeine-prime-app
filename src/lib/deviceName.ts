import { Platform } from 'react-native';
import * as Device from 'expo-device';

export function getDeviceName(): string {
  if (Platform.OS === 'web') return 'Web';
  const model = Device.modelName ?? Device.deviceName ?? null;
  const os = Platform.OS === 'ios' ? 'iOS' : 'Android';
  return model ? `${model} (${os})` : os;
}
